-- Migration to add 'super_admin' and 'owner' to the app_role enum

-- We use IF NOT EXISTS to ensure idempotency
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'super_admin';
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'owner';

-- Make company_id nullable to support super_admin
ALTER TABLE public.profiles ALTER COLUMN company_id DROP NOT NULL;

-- Ensure company_id is present for everyone except super_admin
ALTER TABLE public.profiles ADD CONSTRAINT profiles_company_id_check
CHECK (
    (role = 'super_admin') OR (company_id IS NOT NULL)
);
