-- ============================================================
-- ARCHIVÉ — ne jamais appliquer au projet piavdhrlayfsnrfhqbww ;
-- le schéma live contient des migrations plus récentes sous le même
-- numéro. Conservé pour référence historique du mode local.
-- ============================================================
--
-- ============================================================
-- Migration 4 — Schema completion & alignment (INCREMENTAL)
-- ============================================================
-- Aligns the cloud schema with what the Flutter app consumes
-- (see flutter_app/lib/models/models.dart and lib/services/*):
--   * attendance_logs: user_id -> profile_id, clock_in -> clock_in_time,
--     clock_out -> clock_out_time, plus qr_config_id / notes / timestamps
--   * profiles: email, first_name/last_name (replaces legacy `name`),
--     phone, avatar_url, employee status, updated_at
--   * companies: owner_id, geolocation & branding fields
--   * qr_configs: config_code / name / active + integrity checks
-- Every statement is idempotent: this file can be re-applied safely.
-- NOTE: no index is created on auth.users (not permitted when hosted).
-- ============================================================

-- ------------------------------------------------------------
-- 1. Extensions
-- ------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ------------------------------------------------------------
-- 2. Enums (values written/read by the app)
-- ------------------------------------------------------------
DO $$
BEGIN
    CREATE TYPE public.employee_status AS ENUM ('active', 'inactive', 'on_leave');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END
$$;

-- Values used by the local PostgreSQL mode and the attendance BLoC
ALTER TYPE public.attendance_status ADD VALUE IF NOT EXISTS 'clocked_in';
ALTER TYPE public.attendance_status ADD VALUE IF NOT EXISTS 'clocked_out';
ALTER TYPE public.attendance_status ADD VALUE IF NOT EXISTS 'on_break';
ALTER TYPE public.attendance_status ADD VALUE IF NOT EXISTS 'present';

-- ------------------------------------------------------------
-- 3. Companies: ownership + fields read by Company.fromJson
-- ------------------------------------------------------------
ALTER TABLE public.companies
    ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id) ON DELETE RESTRICT,
    ADD COLUMN IF NOT EXISTS description TEXT,
    ADD COLUMN IF NOT EXISTS address TEXT,
    ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS geofence_radius DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now());

CREATE INDEX IF NOT EXISTS idx_companies_owner ON public.companies(owner_id);

-- ------------------------------------------------------------
-- 4. Attendance logs: align column names with the Dart models
-- ------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'attendance_logs' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.attendance_logs RENAME COLUMN user_id TO profile_id;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'attendance_logs' AND column_name = 'clock_in'
    ) THEN
        ALTER TABLE public.attendance_logs RENAME COLUMN clock_in TO clock_in_time;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'attendance_logs' AND column_name = 'clock_out'
    ) THEN
        ALTER TABLE public.attendance_logs RENAME COLUMN clock_out TO clock_out_time;
    END IF;
END
$$;

ALTER TABLE public.attendance_logs
    ADD COLUMN IF NOT EXISTS qr_config_id UUID REFERENCES public.qr_configs(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS clock_out_lat DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS clock_out_lng DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS date DATE NOT NULL DEFAULT CURRENT_DATE,
    ADD COLUMN IF NOT EXISTS notes TEXT,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now());

-- QR tokens are optional (manual clock-in without scan)
ALTER TABLE public.attendance_logs ALTER COLUMN qr_token DROP NOT NULL;

CREATE INDEX IF NOT EXISTS idx_attendance_date ON public.attendance_logs(date);
CREATE INDEX IF NOT EXISTS idx_attendance_company_date ON public.attendance_logs(company_id, date);

-- ------------------------------------------------------------
-- 5. Profiles: align with Profile.fromJson (first/last name, email...)
-- ------------------------------------------------------------
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS email TEXT,
    ADD COLUMN IF NOT EXISTS first_name TEXT,
    ADD COLUMN IF NOT EXISTS last_name TEXT,
    ADD COLUMN IF NOT EXISTS phone TEXT,
    ADD COLUMN IF NOT EXISTS avatar_url TEXT,
    ADD COLUMN IF NOT EXISTS status public.employee_status NOT NULL DEFAULT 'active',
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now());

-- Migrate legacy `name` into first_name, then drop it
UPDATE public.profiles SET first_name = name WHERE first_name IS NULL AND name IS NOT NULL;
UPDATE public.profiles p SET email = u.email FROM auth.users u WHERE p.id = u.id AND p.email IS NULL;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS name;

CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- ------------------------------------------------------------
-- 6. QR configs: app-facing fields + integrity checks
-- ------------------------------------------------------------
ALTER TABLE public.qr_configs
    ADD COLUMN IF NOT EXISTS config_code TEXT,
    ADD COLUMN IF NOT EXISTS name TEXT,
    ADD COLUMN IF NOT EXISTS active BOOLEAN NOT NULL DEFAULT true,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now());

CREATE UNIQUE INDEX IF NOT EXISTS ux_qr_configs_config_code ON public.qr_configs(config_code);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'qr_configs_rotation_seconds_check'
    ) THEN
        ALTER TABLE public.qr_configs ADD CONSTRAINT qr_configs_rotation_seconds_check CHECK (rotation_seconds > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'qr_configs_radius_meters_check'
    ) THEN
        ALTER TABLE public.qr_configs ADD CONSTRAINT qr_configs_radius_meters_check CHECK (radius_meters > 0);
    END IF;
END
$$;

-- ------------------------------------------------------------
-- 7. updated_at maintenance triggers
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS update_companies_updated_at ON public.companies;
CREATE TRIGGER update_companies_updated_at
    BEFORE UPDATE ON public.companies
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS update_qr_configs_updated_at ON public.qr_configs;
CREATE TRIGGER update_qr_configs_updated_at
    BEFORE UPDATE ON public.qr_configs
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS update_attendance_logs_updated_at ON public.attendance_logs;
CREATE TRIGGER update_attendance_logs_updated_at
    BEFORE UPDATE ON public.attendance_logs
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ------------------------------------------------------------
-- 8. Business logic refresh (post-rename column names)
--    Signatures unchanged from migrations 2/3 -> simple REPLACE.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.clock_in(
    scanned_token text,
    user_lat double precision,
    user_lng double precision
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id uuid;
    v_company_id uuid;
    v_config record;
    v_distance double precision;
    v_open_log_id uuid;
    v_result jsonb;
    v_token_parts text[];
    v_token_company_id text;
    v_token_timestamp text;
    v_token_signature text;
    v_expected_signature text;
    v_time_diff double precision;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT company_id INTO v_company_id FROM public.profiles WHERE id = v_user_id;
    IF v_company_id IS NULL THEN
        RAISE EXCEPTION 'User profile or company not found';
    END IF;

    -- No double clock-in
    SELECT id INTO v_open_log_id
    FROM public.attendance_logs
    WHERE profile_id = v_user_id AND clock_out_time IS NULL
    ORDER BY clock_in_time DESC LIMIT 1;

    IF v_open_log_id IS NOT NULL THEN
        RAISE EXCEPTION 'Already clocked in. Please clock out first.';
    END IF;

    -- Geofencing validation
    SELECT * INTO v_config FROM public.qr_configs WHERE company_id = v_company_id;

    IF v_config IS NOT NULL AND v_config.office_lat IS NOT NULL AND v_config.office_lng IS NOT NULL THEN
        IF user_lat IS NULL OR user_lng IS NULL THEN
            RAISE EXCEPTION 'Location is required for clocking in at this company.';
        END IF;

        v_distance := public.calculate_distance(user_lat, user_lng, v_config.office_lat, v_config.office_lng);

        IF v_distance > v_config.radius_meters THEN
            RAISE EXCEPTION 'Geofence restriction: You are % meters away. Maximum allowed is % meters.', round(v_distance::numeric, 1), v_config.radius_meters;
        END IF;
    END IF;

    -- Signed QR token validation (HMAC-SHA256 TOTP)
    IF scanned_token IS NULL OR scanned_token = '' THEN
        RAISE EXCEPTION 'Invalid or missing QR token';
    END IF;

    -- Expected format: company_id:timestamp_ms:signature
    v_token_parts := string_to_array(scanned_token, ':');
    IF array_length(v_token_parts, 1) != 3 THEN
        RAISE EXCEPTION 'Invalid QR code format';
    END IF;

    v_token_company_id := v_token_parts[1];
    v_token_timestamp := v_token_parts[2];
    v_token_signature := v_token_parts[3];

    IF v_token_company_id != v_company_id::text THEN
        RAISE EXCEPTION 'This QR code does not belong to your company';
    END IF;

    -- Rotation window: kiosk refresh 15s + scan time + latency
    v_time_diff := extract(epoch from now()) * 1000 - v_token_timestamp::numeric;
    IF v_time_diff < -5000 OR v_time_diff > 45000 THEN
        RAISE EXCEPTION 'QR code has expired. Please scan the latest one on the kiosk screen.';
    END IF;

    v_expected_signature := encode(hmac(v_token_company_id || ':' || v_token_timestamp, v_config.qr_secret, 'sha256'), 'hex');
    IF v_token_signature != v_expected_signature THEN
        RAISE EXCEPTION 'Invalid or forged QR code signature';
    END IF;

    INSERT INTO public.attendance_logs (
        profile_id, company_id, clock_in_time, clock_in_lat, clock_in_lng, status, qr_token
    ) VALUES (
        v_user_id, v_company_id, now(), user_lat, user_lng, 'on_time', scanned_token
    ) RETURNING id INTO v_open_log_id;

    v_result := jsonb_build_object(
        'success', true,
        'message', 'Clocked in successfully',
        'attendance_id', v_open_log_id
    );

    RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION public.clock_out()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id uuid;
    v_open_log_id uuid;
    v_result jsonb;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT id INTO v_open_log_id
    FROM public.attendance_logs
    WHERE profile_id = v_user_id AND clock_out_time IS NULL
    ORDER BY clock_in_time DESC LIMIT 1;

    IF v_open_log_id IS NULL THEN
        RAISE EXCEPTION 'No active clock-in found. Cannot clock out.';
    END IF;

    UPDATE public.attendance_logs
    SET clock_out_time = now()
    WHERE id = v_open_log_id;

    v_result := jsonb_build_object(
        'success', true,
        'message', 'Clocked out successfully',
        'attendance_id', v_open_log_id
    );

    RETURN v_result;
END;
$$;

-- ------------------------------------------------------------
-- 9. RLS hardening
--    Replaces the blanket "any authenticated user" policies with
--    company-scoped access (fixes qr_secret exposure across tenants).
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Authenticated users can view companies" ON public.companies;
CREATE POLICY "Members can view their company" ON public.companies
    FOR SELECT USING (
        owner_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
              AND (
                p.company_id = companies.id
                OR p.role = 'super_admin'
              )
        )
    );

DROP POLICY IF EXISTS "Owners can update their companies" ON public.companies;
CREATE POLICY "Owners can update their companies" ON public.companies
    FOR UPDATE USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (
        id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.profiles caller
            WHERE caller.id = auth.uid()
              AND caller.company_id = profiles.company_id
              AND caller.role IN ('admin', 'hr', 'super_admin', 'owner')
        )
    );

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "Admins can view all profiles in company" ON public.profiles;
CREATE POLICY "Admins can view all profiles in company" ON public.profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles caller
            WHERE caller.id = auth.uid()
              AND caller.company_id = profiles.company_id
              AND caller.role IN ('admin', 'hr', 'super_admin')
        )
    );

DROP POLICY IF EXISTS "Authenticated users can view QR configs" ON public.qr_configs;
CREATE POLICY "Users can view company QR config" ON public.qr_configs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
              AND profiles.company_id = qr_configs.company_id
        )
    );

DROP POLICY IF EXISTS "Admins can update QR config" ON public.qr_configs;
CREATE POLICY "Admins can update QR config" ON public.qr_configs
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
              AND profiles.company_id = qr_configs.company_id
              AND profiles.role IN ('admin', 'super_admin', 'owner')
        )
    );

DROP POLICY IF EXISTS "Users can view own attendance" ON public.attendance_logs;
CREATE POLICY "Users can view own attendance" ON public.attendance_logs
    FOR SELECT USING (profile_id = auth.uid());

DROP POLICY IF EXISTS "Admins can view company attendance" ON public.attendance_logs;
CREATE POLICY "Admins can view company attendance" ON public.attendance_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
              AND profiles.company_id = attendance_logs.company_id
              AND profiles.role IN ('admin', 'hr', 'super_admin')
        )
    );

DROP POLICY IF EXISTS "Users can clock in" ON public.attendance_logs;
DROP POLICY IF EXISTS "Users can insert their own attendance" ON public.attendance_logs;
CREATE POLICY "Users can insert their own attendance" ON public.attendance_logs
    FOR INSERT WITH CHECK (profile_id = auth.uid());

DROP POLICY IF EXISTS "Users can clock out" ON public.attendance_logs;
DROP POLICY IF EXISTS "Users can update their attendance" ON public.attendance_logs;
CREATE POLICY "Users can update their attendance" ON public.attendance_logs
    FOR UPDATE USING (profile_id = auth.uid())
    WITH CHECK (profile_id = auth.uid());

-- ------------------------------------------------------------
-- 10. Auth lifecycle triggers
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (
        id, email, company_id, role, first_name, status
    ) VALUES (
        new.id,
        new.email,
        (new.raw_user_meta_data->>'company_id')::uuid,
        COALESCE(
            (new.raw_user_meta_data->>'role')::public.app_role,
            'employee'::public.app_role
        ),
        COALESCE(
            new.raw_user_meta_data->>'name',
            new.raw_user_meta_data->>'full_name',
            new.email
        ),
        'active'
    );
    RETURN new;
END;
$$;

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

DROP TRIGGER IF EXISTS on_auth_user_deleted ON auth.users;
CREATE TRIGGER on_auth_user_deleted
    BEFORE DELETE ON auth.users
    FOR EACH ROW EXECUTE FUNCTION private.handle_user_delete();
