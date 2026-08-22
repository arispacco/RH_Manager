-- ============================================================
-- Complete Backend Schema for RH_Manager
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 1. ENUMS
-- ============================================================

CREATE TYPE public.app_role AS ENUM ('super_admin', 'owner', 'admin', 'hr', 'employee', 'kiosk');
CREATE TYPE public.attendance_status AS ENUM ('on_time', 'late', 'absent', 'excused', 'half_day');
CREATE TYPE public.employee_status AS ENUM ('active', 'inactive', 'on_leave', 'terminated');

-- ============================================================
-- 2. COMPANIES TABLE
-- ============================================================

CREATE TABLE public.companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    domain TEXT UNIQUE,
    owner_id UUID REFERENCES auth.users(id) ON DELETE RESTRICT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX idx_companies_owner ON public.companies(owner_id);

-- ============================================================
-- 3. PROFILES TABLE (extends auth.users)
-- ============================================================

CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
    role public.app_role NOT NULL DEFAULT 'employee'::app_role,
    full_name TEXT NOT NULL,
    department TEXT,
    phone TEXT,
    employee_status public.employee_status DEFAULT 'active'::employee_status NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    avatar_url TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX idx_profiles_company ON public.profiles(company_id);
CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_profiles_is_active ON public.profiles(is_active);
CREATE INDEX idx_profiles_email ON auth.users(email);

-- ============================================================
-- 4. QR CONFIGS TABLE (Geofencing & TOTP)
-- ============================================================

CREATE TABLE public.qr_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL UNIQUE,
    rotation_seconds INTEGER DEFAULT 15 NOT NULL CHECK (rotation_seconds > 0),
    office_lat DOUBLE PRECISION,
    office_lng DOUBLE PRECISION,
    radius_meters INTEGER DEFAULT 200 NOT NULL CHECK (radius_meters > 0),
    is_geofencing_enabled BOOLEAN DEFAULT true NOT NULL,
    is_totp_enabled BOOLEAN DEFAULT true NOT NULL,
    totp_secret TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX idx_qr_configs_company ON public.qr_configs(company_id);

-- ============================================================
-- 5. ATTENDANCE LOGS TABLE
-- ============================================================

CREATE TABLE public.attendance_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    clock_in TIMESTAMP WITH TIME ZONE NOT NULL,
    clock_out TIMESTAMP WITH TIME ZONE,
    clock_in_lat DOUBLE PRECISION,
    clock_in_lng DOUBLE PRECISION,
    clock_out_lat DOUBLE PRECISION,
    clock_out_lng DOUBLE PRECISION,
    status public.attendance_status DEFAULT 'on_time'::attendance_status NOT NULL,
    qr_token TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX idx_attendance_user ON public.attendance_logs(user_id);
CREATE INDEX idx_attendance_company ON public.attendance_logs(company_id);
CREATE INDEX idx_attendance_date ON public.attendance_logs(date);
CREATE INDEX idx_attendance_company_date ON public.attendance_logs(company_id, date);

-- ============================================================
-- 6. UTILITY FUNCTIONS
-- ============================================================

-- Haversine distance calculation (meters)
CREATE OR REPLACE FUNCTION public.calculate_distance_meters(
    lat1 DOUBLE PRECISION, 
    lon1 DOUBLE PRECISION, 
    lat2 DOUBLE PRECISION, 
    lon2 DOUBLE PRECISION
) RETURNS DOUBLE PRECISION
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    R DOUBLE PRECISION := 6371000; -- Earth's radius in meters
    dlat DOUBLE PRECISION;
    dlon DOUBLE PRECISION;
    a DOUBLE PRECISION;
    c DOUBLE PRECISION;
BEGIN
    IF lat1 IS NULL OR lon1 IS NULL OR lat2 IS NULL OR lon2 IS NULL THEN
        RETURN NULL;
    END IF;
    
    dlat := radians(lat2 - lat1);
    dlon := radians(lon2 - lon1);
    a := sin(dlat/2) * sin(dlat/2) + 
         cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon/2) * sin(dlon/2);
    c := 2 * asin(sqrt(a));
    
    RETURN R * c;
END;
$$;

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$;

CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_companies_updated_at
    BEFORE UPDATE ON public.companies
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_qr_configs_updated_at
    BEFORE UPDATE ON public.qr_configs
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_attendance_logs_updated_at
    BEFORE UPDATE ON public.attendance_logs
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

-- ============================================================
-- 7. ATTENDANCE BUSINESS LOGIC
-- ============================================================

-- Clock In Function
CREATE OR REPLACE FUNCTION public.clock_in(
    p_user_id UUID,
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_company_id UUID;
    v_config RECORD;
    v_distance DOUBLE PRECISION;
    v_existing_log UUID;
    v_log_id UUID;
    v_result JSONB;
BEGIN
    -- Verify user exists and is active
    SELECT company_id INTO v_company_id
    FROM profiles
    WHERE id = p_user_id AND is_active = true;
    
    IF v_company_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User not found or inactive'
        );
    END IF;
    
    -- Get QR config
    SELECT * INTO v_config
    FROM qr_configs
    WHERE company_id = v_company_id;
    
    -- Check geofencing if enabled
    IF v_config.is_geofencing_enabled AND v_config.office_lat IS NOT NULL THEN
        v_distance := calculate_distance_meters(
            p_latitude, p_longitude,
            v_config.office_lat, v_config.office_lng
        );
        
        IF v_distance > v_config.radius_meters THEN
            RETURN jsonb_build_object(
                'success', false,
                'error', 'Outside office radius',
                'distance', ROUND(v_distance::numeric, 2),
                'allowed_radius', v_config.radius_meters
            );
        END IF;
    END IF;
    
    -- Check if user already clocked in today
    SELECT id INTO v_existing_log
    FROM attendance_logs
    WHERE user_id = p_user_id 
        AND date = CURRENT_DATE 
        AND clock_out IS NULL;
    
    IF v_existing_log IS NOT NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Already clocked in today'
        );
    END IF;
    
    -- Create attendance log
    INSERT INTO attendance_logs (
        user_id, company_id, date, clock_in,
        clock_in_lat, clock_in_lng, status
    ) VALUES (
        p_user_id, v_company_id, CURRENT_DATE, NOW(),
        p_latitude, p_longitude, 'on_time'::attendance_status
    )
    RETURNING id INTO v_log_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'log_id', v_log_id,
        'message', 'Clocked in successfully'
    );
END;
$$;

-- Clock Out Function
CREATE OR REPLACE FUNCTION public.clock_out(
    p_user_id UUID,
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_log_id UUID;
    v_result JSONB;
BEGIN
    -- Find active attendance log
    SELECT id INTO v_log_id
    FROM attendance_logs
    WHERE user_id = p_user_id 
        AND date = CURRENT_DATE 
        AND clock_out IS NULL;
    
    IF v_log_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'No active clock in found'
        );
    END IF;
    
    -- Update attendance log
    UPDATE attendance_logs
    SET 
        clock_out = NOW(),
        clock_out_lat = p_latitude,
        clock_out_lng = p_longitude
    WHERE id = v_log_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'log_id', v_log_id,
        'message', 'Clocked out successfully'
    );
END;
$$;

-- ============================================================
-- 8. ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qr_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_logs ENABLE ROW LEVEL SECURITY;

-- Companies: Owners can manage their companies
CREATE POLICY "Owners can view their companies" ON public.companies
    FOR SELECT USING (
        auth.uid() = owner_id OR 
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid() 
            AND profiles.role IN ('super_admin', 'owner')
        )
    );

CREATE POLICY "Owners can update their companies" ON public.companies
    FOR UPDATE USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

-- Profiles: Users see their own profile and admins see their company
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (
        id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid()
            AND p.role IN ('admin', 'hr', 'super_admin')
            AND p.company_id = profiles.company_id
        )
    );

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

CREATE POLICY "Admins can view all profiles in company" ON public.profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles caller
            WHERE caller.id = auth.uid()
            AND caller.role IN ('admin', 'hr', 'super_admin')
            AND caller.company_id = profiles.company_id
        )
    );

-- QR Configs: Authenticated users can view their company config
CREATE POLICY "Users can view company QR config" ON public.qr_configs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.company_id = qr_configs.company_id
        )
    );

CREATE POLICY "Admins can update QR config" ON public.qr_configs
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'super_admin')
            AND profiles.company_id = qr_configs.company_id
        )
    );

-- Attendance Logs: Users see their own, admins see company's
CREATE POLICY "Users can view own attendance" ON public.attendance_logs
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Admins can view company attendance" ON public.attendance_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'hr', 'super_admin')
            AND profiles.company_id = attendance_logs.company_id
        )
    );

CREATE POLICY "Users can insert their own attendance" ON public.attendance_logs
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their attendance" ON public.attendance_logs
    FOR UPDATE USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- ============================================================
-- 9. AUTH TRIGGERS
-- ============================================================

CREATE SCHEMA IF NOT EXISTS private;

-- Handle new user signup (creates profile)
CREATE OR REPLACE FUNCTION private.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (
        id, 
        company_id, 
        role, 
        full_name, 
        is_active
    ) VALUES (
        new.id,
        (new.raw_user_meta_data->>'company_id')::uuid,
        COALESCE(
            (new.raw_user_meta_data->>'role')::public.app_role,
            'employee'::public.app_role
        ),
        COALESCE(new.raw_user_meta_data->>'full_name', new.email),
        true
    );
    RETURN new;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION private.handle_new_user();

-- Handle user deletion
CREATE OR REPLACE FUNCTION private.handle_user_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    DELETE FROM public.profiles WHERE id = old.id;
    RETURN old;
END;
$$;

CREATE TRIGGER on_auth_user_deleted
    BEFORE DELETE ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION private.handle_user_delete();
