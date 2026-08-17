-- ============================================================
-- RH_Manager - Supabase schema aligned with the Flutter app
-- ============================================================
-- This schema mirrors the data model the app actually uses
-- (lib/models/models.dart + lib/services/supabase_service.dart),
-- which is the same shape as supabase/migrations/local_postgres.sql
-- but backed by Supabase Auth (auth.users) instead of a local
-- `users` table. It replaces the previous, mutually inconsistent
-- migrations that no longer matched the app.

create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ---------- Enums (match Dart enums in models.dart) ----------
create type public.app_role as enum ('super_admin', 'owner', 'admin', 'hr', 'employee', 'kiosk');
create type public.attendance_status as enum ('clocked_in', 'clocked_out', 'on_break');
create type public.employee_status as enum ('active', 'inactive', 'on_leave');

-- ---------- Companies ----------
create table public.companies (
  id uuid primary key default uuid_generate_v4(),
  name varchar not null,
  description text,
  address varchar,
  latitude float,
  longitude float,
  geofence_radius float,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------- Profiles (extend auth.users) ----------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email varchar not null,
  first_name varchar,
  last_name varchar,
  phone varchar,
  avatar_url varchar,
  company_id uuid not null references public.companies(id),
  role public.app_role not null default 'employee',
  status public.employee_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------- QR configs ----------
create table public.qr_configs (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references public.companies(id),
  config_code varchar unique not null,
  name varchar,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------- Attendance logs ----------
create table public.attendance_logs (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  qr_config_id uuid references public.qr_configs(id),
  clock_in_time timestamptz not null,
  clock_out_time timestamptz,
  clock_in_lat float not null,
  clock_in_lng float not null,
  clock_out_lat float,
  clock_out_lng float,
  status public.attendance_status not null default 'clocked_in',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_profiles_company_id on public.profiles(company_id);
create index idx_profiles_email on public.profiles(email);
create index idx_qr_configs_company_id on public.qr_configs(company_id);
create index idx_attendance_logs_profile_id on public.attendance_logs(profile_id);
create index idx_attendance_logs_clock_in_time on public.attendance_logs(clock_in_time);

-- ---------- updated_at trigger ----------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_companies_updated_at before update on public.companies
  for each row execute function public.set_updated_at();
create trigger trg_profiles_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger trg_qr_configs_updated_at before update on public.qr_configs
  for each row execute function public.set_updated_at();
create trigger trg_attendance_logs_updated_at before update on public.attendance_logs
  for each row execute function public.set_updated_at();

-- ---------- Auto-create a profile when a new auth user signs up ----------
-- The app's signUp() only calls Supabase Auth; this trigger fills profiles so
-- getProfile() works afterwards. company_id / name / role can be passed through
-- the sign-up user metadata; otherwise sensible defaults are used.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  default_company uuid;
begin
  select id into default_company from public.companies order by created_at limit 1;

  insert into public.profiles (id, email, first_name, last_name, company_id, role, status)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'first_name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'last_name', ''),
    coalesce((new.raw_user_meta_data->>'company_id')::uuid, default_company),
    coalesce((new.raw_user_meta_data->>'role')::public.app_role, 'employee'),
    'active'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- Row Level Security ----------
alter table public.companies enable row level security;
alter table public.profiles enable row level security;
alter table public.qr_configs enable row level security;
alter table public.attendance_logs enable row level security;

-- Dev-friendly policies: any authenticated user can read/write.
-- Tighten these before production.
create policy "authenticated full access - companies"
  on public.companies for all to authenticated using (true) with check (true);
create policy "authenticated full access - profiles"
  on public.profiles for all to authenticated using (true) with check (true);
create policy "authenticated full access - qr_configs"
  on public.qr_configs for all to authenticated using (true) with check (true);
create policy "authenticated full access - attendance_logs"
  on public.attendance_logs for all to authenticated using (true) with check (true);

grant usage on schema public to anon, authenticated, service_role;
grant all on all tables in schema public to authenticated, service_role;
grant all on all sequences in schema public to authenticated, service_role;
