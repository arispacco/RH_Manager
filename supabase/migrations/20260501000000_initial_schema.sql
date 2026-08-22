-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Companies Table
CREATE TABLE public.companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    domain TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Profiles Table (extends Supabase auth.users)
CREATE TYPE public.app_role AS ENUM ('admin', 'hr', 'employee', 'kiosk');

CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
    role public.app_role NOT NULL DEFAULT 'employee'::app_role,
    name TEXT NOT NULL,
    department TEXT,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. QR Configs Table (Geofencing and TOTP config)
CREATE TABLE public.qr_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL UNIQUE,
    rotation_seconds INTEGER DEFAULT 15 NOT NULL,
    office_lat DOUBLE PRECISION,
    office_lng DOUBLE PRECISION,
    radius_meters INTEGER DEFAULT 200 NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. Attendance Logs Table
CREATE TYPE public.attendance_status AS ENUM ('on_time', 'late', 'absent', 'excused');

CREATE TABLE public.attendance_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
    clock_in TIMESTAMP WITH TIME ZONE NOT NULL,
    clock_out TIMESTAMP WITH TIME ZONE,
    clock_in_lat DOUBLE PRECISION,
    clock_in_lng DOUBLE PRECISION,
    status public.attendance_status DEFAULT 'on_time'::attendance_status NOT NULL,
    qr_token TEXT NOT NULL
);

-- Indexes for performance
CREATE INDEX idx_profiles_company ON public.profiles(company_id);
CREATE INDEX idx_attendance_user ON public.attendance_logs(user_id);
CREATE INDEX idx_attendance_company ON public.attendance_logs(company_id);

-- RLS (Row Level Security)

-- Enable RLS
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qr_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_logs ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can only read their own profile
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (id = auth.uid());

-- Profiles: Users can update their own profile
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (id = auth.uid());

-- Companies: Anyone authenticated can read companies
CREATE POLICY "Authenticated users can view companies" ON public.companies
    FOR SELECT USING (auth.role() = 'authenticated');

-- QR Configs: Anyone authenticated can read QR configs
CREATE POLICY "Authenticated users can view QR configs" ON public.qr_configs
    FOR SELECT USING (auth.role() = 'authenticated');

-- Attendance: Users can read their own attendance
CREATE POLICY "Users can view own attendance" ON public.attendance_logs
    FOR SELECT USING (user_id = auth.uid());

-- Attendance: Users can insert their own attendance
CREATE POLICY "Users can clock in" ON public.attendance_logs
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Attendance: Users can update their own attendance (clock out)
CREATE POLICY "Users can clock out" ON public.attendance_logs
    FOR UPDATE USING (user_id = auth.uid());

-- Secure trigger to automatically create a profile when a user signs up
CREATE SCHEMA IF NOT EXISTS private;

CREATE OR REPLACE FUNCTION private.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, name, company_id, role)
  VALUES (
    new.id,
    new.raw_user_meta_data->>'name',
    (new.raw_user_meta_data->>'company_id')::uuid,
    COALESCE((new.raw_user_meta_data->>'role')::public.app_role, 'employee'::public.app_role)
  );
  RETURN new;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE private.handle_new_user();
