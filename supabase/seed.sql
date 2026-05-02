-- Insert mock company
INSERT INTO public.companies (id, name, domain)
VALUES ('00000000-0000-0000-0000-000000000001', 'Acme Corp', 'acme.com')
ON CONFLICT DO NOTHING;

-- Insert QR Config for Acme Corp (Yaoundé test coords)
INSERT INTO public.qr_configs (company_id, rotation_seconds, office_lat, office_lng, radius_meters)
VALUES ('00000000-0000-0000-0000-000000000001', 15, 3.8480, 11.5021, 200)
ON CONFLICT DO NOTHING;

-- Create mock users via Supabase auth (in a real scenario this happens via the API)
-- For seeding, we'll directly insert into auth.users and let the trigger create the profiles.
-- (Note: passwords in auth.users are encrypted. We use a known hash for 'password123')

INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) VALUES
-- Admin
(
  '00000000-0000-0000-0000-000000000000',
  'a0000000-0000-0000-0000-000000000001',
  'authenticated',
  'authenticated',
  'admin@acme.com',
  crypt('Admin@2024', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"name":"Alex Admin", "company_id":"00000000-0000-0000-0000-000000000001", "role":"admin"}',
  now(),
  now()
),
-- HR
(
  '00000000-0000-0000-0000-000000000000',
  'a0000000-0000-0000-0000-000000000002',
  'authenticated',
  'authenticated',
  'hr@acme.com',
  crypt('Admin@2024', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"name":"Sarah HR", "company_id":"00000000-0000-0000-0000-000000000001", "role":"hr"}',
  now(),
  now()
),
-- Employee
(
  '00000000-0000-0000-0000-000000000000',
  'a0000000-0000-0000-0000-000000000003',
  'authenticated',
  'authenticated',
  'employee@acme.com',
  crypt('Admin@2024', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"name":"John Employee", "company_id":"00000000-0000-0000-0000-000000000001", "role":"employee"}',
  now(),
  now()
),
-- Kiosk
(
  '00000000-0000-0000-0000-000000000000',
  'a0000000-0000-0000-0000-000000000004',
  'authenticated',
  'authenticated',
  'kiosk@acme.com',
  crypt('Admin@2024', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"name":"Main Entrance Kiosk", "company_id":"00000000-0000-0000-0000-000000000001", "role":"kiosk"}',
  now(),
  now()
);
