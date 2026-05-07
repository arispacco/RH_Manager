# RH_Manager Backend - Setup & Development Guide

## Quick Start (Local Development)

### Prerequisites

- **Supabase CLI**: [Install](https://supabase.com/docs/guides/local-development/cli/overview)
- **Docker**: Required for `supabase start`
- **Node.js/npm**: For frontend development
- **Git**: For version control

### 1. Start Supabase Locally

```bash
cd ~/Documents/RH_Manager

# Start Supabase stack (database, API, auth, functions)
supabase start

# Output will show:
# API URL:        http://localhost:54331
# Database URL:   postgresql://postgres:postgres@localhost:54332/postgres
# Studio URL:     http://localhost:54323
# Anon Key:       eyJhbGc...
```

### 2. Apply Database Migrations

```bash
# Apply all migrations in order
supabase db push

# Verify migrations applied
psql postgresql://postgres:postgres@localhost:54332/postgres \
  -c "SELECT name, executed_at FROM schema_migrations ORDER BY executed_at DESC LIMIT 5;"
```

### 3. Seed Test Data (Optional)

```bash
# Load seed data for testing
psql postgresql://postgres:postgres@localhost:54332/postgres \
  < supabase/seed.sql

# Verify
psql postgresql://postgres:postgres@localhost:54332/postgres \
  -c "SELECT full_name, role, company_id FROM public.profiles;"
```

### 4. Deploy Edge Functions

```bash
# Deploy all Edge Functions
supabase functions deploy auth/create-user
supabase functions deploy auth/clock-in
supabase functions deploy auth/clock-out
supabase functions deploy auth/get-attendance
supabase functions deploy auth/get-profile

# View function logs
supabase functions list
```

### 5. Configure Frontend

```bash
# Copy environment template
cp .env.supabase .env.local

# Or set environment variables directly in your editor:
# VITE_SUPABASE_URL=http://localhost:54331
# VITE_SUPABASE_ANON_KEY=<anon-key-from-supabase-start-output>
```

### 6. Start Frontend Dev Server

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Open http://localhost:5173
```

## Testing

### Test User Accounts

After seeding, these accounts are available:

| Email | Password | Role | Company |
|-------|----------|------|---------|
| admin@acme.com | (any) | admin | Acme Corporation |
| hr@acme.com | (any) | hr | Acme Corporation |
| john.doe@acme.com | (any) | employee | Acme Corporation |
| jane.smith@acme.com | (any) | employee | Acme Corporation |

**Note**: Passwords are hashed in the database. For testing via Edge Functions, use your real Supabase credentials.

### Test Clock In/Out (Postman/curl)

```bash
# Get session token
SESSION_TOKEN=$(curl -X POST http://localhost:54331/auth/v1/token?grant_type=password \
  -H "apikey: <your-anon-key>" \
  -H "Content-Type: application/json" \
  -d '{"email":"john.doe@acme.com","password":"password"}' \
  | jq -r '.access_token')

# Clock in
curl -X POST http://localhost:54331/functions/v1/auth/clock-in \
  -H "Authorization: Bearer $SESSION_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"latitude":48.8566,"longitude":2.3522}'

# Should return: { "success": true, "log_id": "..." }

# Clock out
curl -X POST http://localhost:54331/functions/v1/auth/clock-out \
  -H "Authorization: Bearer $SESSION_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"latitude":48.8566,"longitude":2.3522}'

# Get attendance history
curl -X GET "http://localhost:54331/functions/v1/auth/get-attendance?days=30" \
  -H "Authorization: Bearer $SESSION_TOKEN"
```

### Test RLS Policies

```bash
# Verify RLS is enabled
psql postgresql://postgres:postgres@localhost:54332/postgres \
  -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename IN ('companies', 'profiles', 'qr_configs', 'attendance_logs');"

# Check policies
psql postgresql://postgres:postgres@localhost:54332/postgres \
  -c "SELECT * FROM pg_policies WHERE tablename = 'attendance_logs';"
```

## Common Commands

### Database Commands

```bash
# Connect to local database
psql postgresql://postgres:postgres@localhost:54332/postgres

# View current migrations
supabase db list-migrations

# Reset database (WARNING: deletes all data)
supabase db reset

# Push latest schema changes
supabase db push

# Pull remote schema (production)
supabase db pull
```

### Function Commands

```bash
# Test local function
supabase functions test auth/clock-in

# View function logs in real-time
supabase functions serve

# Deploy specific function to production
supabase functions deploy auth/clock-in --project-ref <project-ref>
```

### Authentication Commands

```bash
# Generate auth URL
supabase auth get-url --project-ref <project-ref> --kind signup

# Get magic link
supabase auth send-magic-link --email user@example.com
```

## Supabase Studio (Web UI)

Access the local Supabase dashboard:

```
http://localhost:54323
```

**Features:**
- Browse tables and edit data
- Run SQL queries
- View function logs
- Manage authentication
- Check real-time subscriptions

## Production Deployment

### 1. Create Supabase Project

```bash
# Create new project on supabase.com
# Get project URL and API keys from project settings
```

### 2. Push Database Schema

```bash
supabase db push --db-url "postgresql://user:pass@host:5432/db"
```

### 3. Deploy Edge Functions

```bash
# Deploy each function
supabase functions deploy auth/create-user --project-ref <project-ref>
supabase functions deploy auth/clock-in --project-ref <project-ref>
supabase functions deploy auth/clock-out --project-ref <project-ref>
supabase functions deploy auth/get-attendance --project-ref <project-ref>
supabase functions deploy auth/get-profile --project-ref <project-ref>
```

### 4. Configure Production Environment

```bash
# Set production environment variables in your deployment platform
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=<production-anon-key>
```

### 5. Enable Row-Level Security

Ensure RLS is enforced on all tables:

```sql
ALTER TABLE public.companies FORCE ROW LEVEL SECURITY;
ALTER TABLE public.profiles FORCE ROW LEVEL SECURITY;
ALTER TABLE public.qr_configs FORCE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_logs FORCE ROW LEVEL SECURITY;
```

## Troubleshooting

### Supabase won't start

```bash
# Clean up Docker containers
docker ps -a
docker rm -f $(docker ps -a -q)

# Remove Supabase cache
rm -rf ~/.supabase

# Start fresh
supabase start
```

### Migrations failing

```bash
# Check migration status
supabase db migrations list

# Reset and re-apply
supabase db reset
supabase db push
```

### Functions not executing

```bash
# Check function logs
supabase functions serve

# Verify authorization header
curl -X GET http://localhost:54331/functions/v1/auth/get-profile \
  -H "Authorization: Bearer <valid-token>"
```

### RLS blocking legitimate queries

1. Verify user is authenticated
2. Check profile exists in company
3. Review RLS policies in Supabase Studio
4. Enable "check" mode in policies for debugging

## Performance Tips

1. **Use Indexes**: Key columns are indexed
2. **Batch Requests**: Group multiple queries
3. **Cache Results**: Implement frontend caching
4. **Connection Pooling**: Enabled by default
5. **Monitor**: Use Supabase dashboard metrics

## Security Checklist

- [ ] RLS enabled on all tables
- [ ] Service Role Key never exposed to client
- [ ] Auth tokens validated in Edge Functions
- [ ] Input validation on all endpoints
- [ ] Rate limiting configured
- [ ] Geofencing enabled for attendance
- [ ] Audit logs enabled
- [ ] Secrets stored in environment variables

## Next Steps

1. **Customize migrations**: Add company-specific fields
2. **Add more functions**: Reports, exports, integrations
3. **Setup CI/CD**: Automatic deployments
4. **Monitor**: Setup alerts and monitoring
5. **Scale**: Configure connection pooling, caching

## Getting Help

- [Supabase Docs](https://supabase.com/docs)
- [GitHub Issues](https://github.com/supabase/supabase/issues)
- [Discord Community](https://discord.supabase.com)
- [Local Development Guide](https://supabase.com/docs/guides/local-development)
