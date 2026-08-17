-- ============================================================
-- Seed data for RH_Manager (Supabase local stack)
-- Applied automatically by `supabase start` / `supabase db reset`.
-- Auth users are created separately (see supabase/seed_users.sh),
-- because they must go through Supabase Auth (auth.users).
-- ============================================================

insert into public.companies (id, name, description, address, latitude, longitude, geofence_radius)
values
  ('10000000-0000-0000-0000-000000000001'::uuid, 'ACME Corp', 'Main headquarters', '123 Business St', 48.8566, 2.3522, 0.5),
  ('10000000-0000-0000-0000-000000000002'::uuid, 'Tech Innovators', 'Tech division', '456 Tech Ave', 48.8700, 2.3500, 0.3)
on conflict (id) do nothing;

insert into public.qr_configs (company_id, config_code, name, active)
values
  ('10000000-0000-0000-0000-000000000001'::uuid, 'QR_ACME_MAIN', 'Main Entrance', true),
  ('10000000-0000-0000-0000-000000000002'::uuid, 'QR_TECH_LAB', 'Lab Access', true)
on conflict (config_code) do nothing;
