-- Test data for local development

-- Insert test companies
INSERT INTO companies (name, description, address, latitude, longitude, geofence_radius)
VALUES 
  ('ACME Corp', 'Main headquarters', '123 Business St', 48.8566, 2.3522, 0.5),
  ('Tech Innovators', 'Tech division', '456 Tech Ave', 48.8700, 2.3500, 0.3);

-- Insert test users (passwords are hashed with bcrypt)
INSERT INTO users (email, password_hash)
VALUES 
  ('admin@acme.com', crypt('admin123', gen_salt('bf'))),
  ('hr@acme.com', crypt('hr123', gen_salt('bf'))),
  ('john.doe@acme.com', crypt('john123', gen_salt('bf'))),
  ('jane.smith@acme.com', crypt('jane123', gen_salt('bf')));

-- Insert profiles
INSERT INTO profiles (id, email, first_name, last_name, phone, company_id, role, status)
SELECT id, email, SPLIT_PART(email, '@', 1), 'Admin', '0123456789', 
       (SELECT id FROM companies WHERE name = 'ACME Corp'), 'admin'::app_role, 'active'::employee_status
FROM users WHERE email = 'admin@acme.com'
UNION ALL
SELECT id, email, 'HR', 'Manager', '0123456790',
       (SELECT id FROM companies WHERE name = 'ACME Corp'), 'hr'::app_role, 'active'::employee_status
FROM users WHERE email = 'hr@acme.com'
UNION ALL
SELECT id, email, 'John', 'Doe', '0123456791',
       (SELECT id FROM companies WHERE name = 'ACME Corp'), 'employee'::app_role, 'active'::employee_status
FROM users WHERE email = 'john.doe@acme.com'
UNION ALL
SELECT id, email, 'Jane', 'Smith', '0123456792',
       (SELECT id FROM companies WHERE name = 'ACME Corp'), 'employee'::app_role, 'active'::employee_status
FROM users WHERE email = 'jane.smith@acme.com';

-- Insert QR configs
INSERT INTO qr_configs (company_id, config_code, name, active)
VALUES 
  ((SELECT id FROM companies WHERE name = 'ACME Corp'), 'QR_ACME_MAIN', 'Main Entrance', true),
  ((SELECT id FROM companies WHERE name = 'Tech Innovators'), 'QR_TECH_LAB', 'Lab Access', true);

-- Insert sample attendance logs
INSERT INTO attendance_logs (profile_id, qr_config_id, clock_in_time, clock_in_lat, clock_in_lng, status)
VALUES 
  ((SELECT id FROM profiles WHERE email = 'john.doe@acme.com'), 
   (SELECT id FROM qr_configs WHERE config_code = 'QR_ACME_MAIN'),
   NOW() - INTERVAL '1 day', 48.8566, 2.3522, 'clocked_out'::attendance_status),
  ((SELECT id FROM profiles WHERE email = 'jane.smith@acme.com'),
   (SELECT id FROM qr_configs WHERE config_code = 'QR_ACME_MAIN'),
   NOW() - INTERVAL '2 days', 48.8566, 2.3522, 'clocked_out'::attendance_status);

-- Update attendance logs to have clock_out times
UPDATE attendance_logs
SET clock_out_time = clock_in_time + INTERVAL '8 hours',
    clock_out_lat = 48.8566,
    clock_out_lng = 2.3522
WHERE clock_out_time IS NULL;
