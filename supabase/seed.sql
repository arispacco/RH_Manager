-- ============================================================
-- Seed data for testing RH_Manager
-- Run this after applying all migrations
-- ============================================================

-- TRUNCATE DATA (be careful in production!)
-- TRUNCATE attendance_logs, profiles, qr_configs, companies, auth.users CASCADE;

-- ============================================================
-- 1. CREATE TEST COMPANIES
-- ============================================================

INSERT INTO public.companies (id, name, domain, created_at, updated_at) VALUES
('10000000-0000-0000-0000-000000000001'::uuid, 'Acme Corporation', 'acme.com', NOW(), NOW()),
('10000000-0000-0000-0000-000000000002'::uuid, 'Tech Innovations Ltd', 'techinno.com', NOW(), NOW())
ON CONFLICT DO NOTHING;

-- ============================================================
-- 2. CREATE QR CONFIGS (Geofencing & TOTP)
-- ============================================================

INSERT INTO public.qr_configs (
    id, 
    company_id, 
    rotation_seconds, 
    office_lat, 
    office_lng, 
    radius_meters,
    is_geofencing_enabled,
    is_totp_enabled,
    updated_at
) VALUES
(
    '20000000-0000-0000-0000-000000000001'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    15,
    48.8566,
    2.3522,
    500,
    true,
    true,
    NOW()
),
(
    '20000000-0000-0000-0000-000000000002'::uuid,
    '10000000-0000-0000-0000-000000000002'::uuid,
    15,
    51.5074,
    -0.1278,
    300,
    true,
    true,
    NOW()
)
ON CONFLICT DO NOTHING;

-- ============================================================
-- 3. CREATE TEST USERS (profiles created by auth trigger)
-- ============================================================

-- Admin User
INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_user_meta_data,
    created_at,
    updated_at
) VALUES (
    '30000000-0000-0000-0000-000000000001'::uuid,
    'admin@acme.com',
    '$2a$10$PwCRYzAAhKpz4rKWVh3eeOvBXA3vT3x3p0yxF5K0W0qR5Q5Q5Q5Q5',
    NOW(),
    '{"full_name":"Alex Rivers","company_id":"10000000-0000-0000-0000-000000000001","role":"admin"}',
    NOW(),
    NOW()
) ON CONFLICT (email) DO NOTHING;

-- HR User
INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_user_meta_data,
    created_at,
    updated_at
) VALUES (
    '30000000-0000-0000-0000-000000000002'::uuid,
    'hr@acme.com',
    '$2a$10$PwCRYzAAhKpz4rKWVh3eeOvBXA3vT3x3p0yxF5K0W0qR5Q5Q5Q5Q5',
    NOW(),
    '{"full_name":"Sarah Jenkins","company_id":"10000000-0000-0000-0000-000000000001","role":"hr"}',
    NOW(),
    NOW()
) ON CONFLICT (email) DO NOTHING;

-- Employee User 1
INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_user_meta_data,
    created_at,
    updated_at
) VALUES (
    '30000000-0000-0000-0000-000000000003'::uuid,
    'john.doe@acme.com',
    '$2a$10$PwCRYzAAhKpz4rKWVh3eeOvBXA3vT3x3p0yxF5K0W0qR5Q5Q5Q5Q5',
    NOW(),
    '{"full_name":"John Doe","company_id":"10000000-0000-0000-0000-000000000001","role":"employee"}',
    NOW(),
    NOW()
) ON CONFLICT (email) DO NOTHING;

-- Employee User 2
INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_user_meta_data,
    created_at,
    updated_at
) VALUES (
    '30000000-0000-0000-0000-000000000004'::uuid,
    'jane.smith@acme.com',
    '$2a$10$PwCRYzAAhKpz4rKWVh3eeOvBXA3vT3x3p0yxF5K0W0qR5Q5Q5Q5Q5',
    NOW(),
    '{"full_name":"Jane Smith","company_id":"10000000-0000-0000-0000-000000000001","role":"employee"}',
    NOW(),
    NOW()
) ON CONFLICT (email) DO NOTHING;

-- ============================================================
-- 4. CREATE SAMPLE ATTENDANCE LOGS
-- ============================================================

INSERT INTO public.attendance_logs (
    id,
    user_id,
    company_id,
    date,
    clock_in,
    clock_out,
    clock_in_lat,
    clock_in_lng,
    clock_out_lat,
    clock_out_lng,
    status,
    created_at,
    updated_at
) VALUES
-- John Doe - Previous Monday
(
    '40000000-0000-0000-0000-000000000001'::uuid,
    '30000000-0000-0000-0000-000000000003'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    CURRENT_DATE - INTERVAL '4 days',
    CURRENT_DATE - INTERVAL '4 days' || ' 08:30:00+00:00'::timestamptz,
    CURRENT_DATE - INTERVAL '4 days' || ' 17:00:00+00:00'::timestamptz,
    48.8566,
    2.3522,
    48.8566,
    2.3522,
    'on_time'::public.attendance_status,
    NOW(),
    NOW()
),
-- John Doe - Tuesday
(
    '40000000-0000-0000-0000-000000000002'::uuid,
    '30000000-0000-0000-0000-000000000003'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    CURRENT_DATE - INTERVAL '3 days',
    CURRENT_DATE - INTERVAL '3 days' || ' 08:45:00+00:00'::timestamptz,
    CURRENT_DATE - INTERVAL '3 days' || ' 17:15:00+00:00'::timestamptz,
    48.8566,
    2.3522,
    48.8566,
    2.3522,
    'on_time'::public.attendance_status,
    NOW(),
    NOW()
),
-- Jane Smith - Previous Monday
(
    '40000000-0000-0000-0000-000000000003'::uuid,
    '30000000-0000-0000-0000-000000000004'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    CURRENT_DATE - INTERVAL '4 days',
    CURRENT_DATE - INTERVAL '4 days' || ' 09:05:00+00:00'::timestamptz,
    CURRENT_DATE - INTERVAL '4 days' || ' 17:30:00+00:00'::timestamptz,
    48.8566,
    2.3522,
    48.8566,
    2.3522,
    'late'::public.attendance_status,
    NOW(),
    NOW()
),
-- Jane Smith - Tuesday (Still clocked in)
(
    '40000000-0000-0000-0000-000000000004'::uuid,
    '30000000-0000-0000-0000-000000000004'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    CURRENT_DATE - INTERVAL '3 days',
    CURRENT_DATE - INTERVAL '3 days' || ' 08:30:00+00:00'::timestamptz,
    NULL,
    48.8566,
    2.3522,
    NULL,
    NULL,
    'on_time'::public.attendance_status,
    NOW(),
    NOW()
)
ON CONFLICT DO NOTHING;

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================

-- Uncomment to test after running seed:
-- SELECT COUNT(*) as total_companies FROM public.companies;
-- SELECT COUNT(*) as total_users FROM public.profiles;
-- SELECT COUNT(*) as total_attendance FROM public.attendance_logs;
-- SELECT full_name, role, employee_status FROM public.profiles ORDER BY created_at DESC;
-- SELECT full_name, date, clock_in, clock_out, status FROM public.attendance_logs ORDER BY date DESC;
