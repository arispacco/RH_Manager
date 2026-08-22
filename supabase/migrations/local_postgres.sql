-- RH Manager - PostgreSQL Local Setup (without Supabase auth schema)
-- Run this INSTEAD of the Supabase migration for local development

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Enums
CREATE TYPE app_role AS ENUM ('super_admin', 'owner', 'admin', 'hr', 'employee', 'kiosk');
CREATE TYPE attendance_status AS ENUM ('clocked_in', 'clocked_out', 'on_break');
CREATE TYPE employee_status AS ENUM ('active', 'inactive', 'on_leave');

-- Companies table
CREATE TABLE IF NOT EXISTS companies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR NOT NULL,
  description TEXT,
  address VARCHAR,
  latitude FLOAT,
  longitude FLOAT,
  geofence_radius FLOAT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Users table (local auth substitute)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR UNIQUE NOT NULL,
  password_hash VARCHAR NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Profiles table (extends users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  email VARCHAR NOT NULL,
  first_name VARCHAR,
  last_name VARCHAR,
  phone VARCHAR,
  avatar_url VARCHAR,
  company_id UUID NOT NULL REFERENCES companies(id),
  role app_role DEFAULT 'employee',
  status employee_status DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- QR Configs table
CREATE TABLE IF NOT EXISTS qr_configs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID NOT NULL REFERENCES companies(id),
  config_code VARCHAR UNIQUE NOT NULL,
  name VARCHAR,
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Attendance logs table
CREATE TABLE IF NOT EXISTS attendance_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  qr_config_id UUID REFERENCES qr_configs(id),
  clock_in_time TIMESTAMP NOT NULL,
  clock_out_time TIMESTAMP,
  clock_in_lat FLOAT NOT NULL,
  clock_in_lng FLOAT NOT NULL,
  clock_out_lat FLOAT,
  clock_out_lng FLOAT,
  status attendance_status DEFAULT 'clocked_in',
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_profiles_company_id ON profiles(company_id);
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_qr_configs_company_id ON qr_configs(company_id);
CREATE INDEX idx_attendance_logs_profile_id ON attendance_logs(profile_id);
CREATE INDEX idx_attendance_logs_clock_in_time ON attendance_logs(clock_in_time);

-- Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_qr_configs_updated_at BEFORE UPDATE ON qr_configs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_attendance_logs_updated_at BEFORE UPDATE ON attendance_logs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Haversine distance function
CREATE OR REPLACE FUNCTION calculate_distance_meters(
    lat1 FLOAT, lon1 FLOAT,
    lat2 FLOAT, lon2 FLOAT
) RETURNS FLOAT AS $$
DECLARE
    p FLOAT := 0.017453292519943295;
    a FLOAT;
    result FLOAT;
BEGIN
    a := 0.5 - COS((lat2 - lat1) * p) / 2 + COS(lat1 * p) * COS(lat2 * p) * (1 - COS((lon2 - lon1) * p)) / 2;
    result := 12742 * ASIN(SQRT(a)) * 1000;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to check if within geofence
CREATE OR REPLACE FUNCTION is_within_geofence(
    user_lat FLOAT, user_lng FLOAT,
    company_lat FLOAT, company_lng FLOAT,
    radius_km FLOAT
) RETURNS BOOLEAN AS $$
DECLARE
    distance_m FLOAT;
BEGIN
    distance_m := calculate_distance_meters(user_lat, user_lng, company_lat, company_lng);
    RETURN distance_m <= (radius_km * 1000);
END;
$$ LANGUAGE plpgsql;

-- Clock in function
CREATE OR REPLACE FUNCTION clock_in(
    p_profile_id UUID,
    p_qr_config_id UUID,
    p_lat FLOAT,
    p_lng FLOAT
) RETURNS TABLE(
    id UUID,
    profile_id UUID,
    clock_in_time TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    INSERT INTO attendance_logs(profile_id, qr_config_id, clock_in_time, clock_in_lat, clock_in_lng, status)
    VALUES(p_profile_id, p_qr_config_id, CURRENT_TIMESTAMP, p_lat, p_lng, 'clocked_in')
    RETURNING attendance_logs.id, attendance_logs.profile_id, attendance_logs.clock_in_time;
END;
$$ LANGUAGE plpgsql;

-- Clock out function
CREATE OR REPLACE FUNCTION clock_out(
    p_log_id UUID,
    p_lat FLOAT,
    p_lng FLOAT
) RETURNS TABLE(
    id UUID,
    profile_id UUID,
    clock_out_time TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    UPDATE attendance_logs
    SET clock_out_time = CURRENT_TIMESTAMP,
        clock_out_lat = p_lat,
        clock_out_lng = p_lng,
        status = 'clocked_out'
    WHERE id = p_log_id
    RETURNING attendance_logs.id, attendance_logs.profile_id, attendance_logs.clock_out_time;
END;
$$ LANGUAGE plpgsql;
