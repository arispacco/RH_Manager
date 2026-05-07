# RH_Manager Backend - Supabase Architecture

## Overview

Complete backend architecture using Supabase, featuring:
- **Multi-tenant companies** with role-based access control
- **Real-time attendance tracking** with geofencing and TOTP
- **Row-Level Security (RLS)** for data isolation
- **Edge Functions** for business logic
- **PostgreSQL** database with triggers and stored procedures

## Project Structure

```
supabase/
├── config.toml                    # Supabase local configuration
├── migrations/
│   ├── 20260501000000_initial_schema.sql
│   ├── 20260502000000_attendance_logic.sql
│   ├── 20260502000001_qr_totp_security.sql
│   ├── 20260503000000_super_admin_owner_roles.sql
│   └── 20260504000000_complete_backend.sql      # NEW: Complete schema
├── functions/
│   └── auth/
│       ├── create-user.ts         # Create new user (admin only)
│       ├── clock-in.ts            # Clock in with geofencing
│       ├── clock-out.ts           # Clock out
│       └── get-attendance.ts       # Get attendance history
└── seed.sql                       # Database seeding for testing

src/
└── lib/
    └── supabase.ts               # Frontend TypeScript client
```

## Database Schema

### Tables

#### 1. **companies**
- Store company information
- Multi-tenant support
- Fields: id, name, domain, owner_id, created_at, updated_at

#### 2. **profiles** (extends auth.users)
- User profiles with roles
- Extends Supabase Auth users
- Fields: id, company_id, role, full_name, department, phone, employee_status, is_active, avatar_url, metadata

#### 3. **qr_configs**
- QR code rotation and geofencing configuration per company
- Fields: id, company_id, rotation_seconds, office_lat, office_lng, radius_meters, is_geofencing_enabled, is_totp_enabled

#### 4. **attendance_logs**
- Tracks all clock-in/clock-out events
- Geolocation data for compliance
- Fields: id, user_id, company_id, date, clock_in, clock_out, clock_in_lat, clock_in_lng, clock_out_lat, clock_out_lng, status, qr_token, notes

### Enums

```typescript
app_role: 'super_admin' | 'owner' | 'admin' | 'hr' | 'employee' | 'kiosk'
attendance_status: 'on_time' | 'late' | 'absent' | 'excused' | 'half_day'
employee_status: 'active' | 'inactive' | 'on_leave' | 'terminated'
```

## Security

### Row-Level Security (RLS)

All tables have RLS enabled with policies:

- **companies**: Owners can view/update their companies
- **profiles**: Users see own profile, admins see company profiles
- **qr_configs**: Users can view company config, admins can update
- **attendance_logs**: Users see own logs, admins see company logs

### Key Features

- **SECURITY DEFINER functions** for sensitive operations
- **Service Role Key** used only in Edge Functions (server-side)
- **Triggers** automatically create profiles on user signup
- **Constraints** validate data integrity (CHECK, UNIQUE, FOREIGN KEY)

## Edge Functions

### 1. **auth/create-user** (POST /functions/v1/auth/create-user)

Create a new user (admin only).

**Request:**
```json
{
  "email": "john@example.com",
  "password": "secure_password",
  "full_name": "John Doe",
  "role": "employee"
}
```

**Response:**
```json
{
  "success": true,
  "user": {
    "id": "uuid",
    "email": "john@example.com"
  }
}
```

### 2. **auth/clock-in** (POST /functions/v1/auth/clock-in)

Clock in with geofencing validation.

**Request:**
```json
{
  "latitude": 48.8566,
  "longitude": 2.3522
}
```

**Response (Success):**
```json
{
  "success": true,
  "log_id": "uuid",
  "message": "Clocked in successfully"
}
```

**Response (Outside Geofence):**
```json
{
  "success": false,
  "error": "Outside office radius",
  "distance": 1250.5,
  "allowed_radius": 200
}
```

### 3. **auth/clock-out** (POST /functions/v1/auth/clock-out)

Clock out with location tracking.

**Request:**
```json
{
  "latitude": 48.8566,
  "longitude": 2.3522
}
```

**Response:**
```json
{
  "success": true,
  "log_id": "uuid",
  "message": "Clocked out successfully"
}
```

### 4. **auth/get-attendance** (GET /functions/v1/auth/get-attendance?days=30)

Get user's attendance history.

**Query Params:**
- `days` (optional, default: 30): Number of days to retrieve

**Response:**
```json
{
  "success": true,
  "attendance": [
    {
      "id": "uuid",
      "date": "2026-05-07",
      "clock_in": "2026-05-07T08:30:00Z",
      "clock_out": "2026-05-07T17:00:00Z",
      "status": "on_time",
      "duration_hours": 8.5
    }
  ]
}
```

### 5. **auth/get-profile** (GET /functions/v1/auth/get-profile)

Get current user's profile.

**Response:**
```json
{
  "success": true,
  "profile": {
    "id": "uuid",
    "email": "user@example.com",
    "full_name": "User Name",
    "role": "employee",
    "company_id": "uuid",
    "department": "Engineering",
    "employee_status": "active"
  }
}
```

## Frontend Integration

### Setup

1. Install Supabase client:
```bash
npm install @supabase/supabase-js
```

2. Set environment variables (.env.local):
```
VITE_SUPABASE_URL=http://localhost:54331
VITE_SUPABASE_ANON_KEY=your-anon-key
```

3. Use the backend client:
```typescript
import { supabaseBackend } from "@/lib/supabase";

// Login
const { success, user, session } = await supabaseBackend.login(
  "user@example.com",
  "password"
);

// Clock in
const result = await supabaseBackend.clockIn(latitude, longitude);

// Get attendance
const { attendance } = await supabaseBackend.getAttendanceHistory(30);
```

## Database Functions (PL/pgSQL)

### calculate_distance_meters()

Calculates distance between two GPS coordinates using Haversine formula.

```sql
SELECT public.calculate_distance_meters(48.8566, 2.3522, 48.8526, 2.3476);
-- Returns: ~5200 (meters)
```

### clock_in()

Server-side clock in logic with geofencing validation.

```sql
SELECT public.clock_in(user_id, latitude, longitude);
```

### clock_out()

Server-side clock out logic.

```sql
SELECT public.clock_out(user_id, latitude, longitude);
```

### Triggers

- `on_auth_user_created`: Auto-creates profile on user signup
- `on_auth_user_deleted`: Auto-deletes profile on user deletion
- `update_*_updated_at`: Auto-updates timestamps

## Development

### Local Setup

```bash
# Start Supabase local environment
supabase start

# Apply migrations
supabase db push

# Seed test data (optional)
psql postgresql://postgres:postgres@localhost:54332/postgres < seed.sql

# Deploy Edge Functions locally
supabase functions serve
```

### Testing

Use the Supabase dashboard at `http://localhost:54323` to:
- Test Edge Functions
- View database data
- Manage authentication
- Check logs

### Common Tasks

#### Create a new company and admin user

```sql
-- Create company
INSERT INTO companies (name, domain, owner_id) 
VALUES ('Acme Corp', 'acme.com', 'owner-uuid');

-- User signup with metadata
-- Use /auth/v1/signup with raw_user_meta_data:
{
  "full_name": "Admin User",
  "role": "admin",
  "company_id": "company-uuid"
}
```

#### View attendance for a company

```sql
SELECT 
    p.full_name,
    al.date,
    al.clock_in,
    al.clock_out,
    al.status,
    ROUND(EXTRACT(EPOCH FROM (al.clock_out - al.clock_in)) / 3600, 2) as hours
FROM attendance_logs al
JOIN profiles p ON al.user_id = p.id
WHERE al.company_id = 'company-uuid'
ORDER BY al.date DESC;
```

#### Update QR geofencing config

```sql
UPDATE qr_configs 
SET 
    office_lat = 48.8566,
    office_lng = 2.3522,
    radius_meters = 500,
    is_geofencing_enabled = true
WHERE company_id = 'company-uuid';
```

## Deployment

### Production Deployment

1. Create Supabase project on [supabase.com](https://supabase.com)
2. Push migrations:
```bash
supabase db push --db-url "postgresql://user:pass@host:5432/db"
```
3. Deploy Edge Functions:
```bash
supabase functions deploy auth/create-user
supabase functions deploy auth/clock-in
supabase functions deploy auth/clock-out
supabase functions deploy auth/get-attendance
supabase functions deploy auth/get-profile
```

### Environment Variables

**Production:**
```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-production-anon-key
```

## Best Practices

1. **Always use RLS** - All tables have row-level security enabled
2. **Use SECURITY DEFINER sparingly** - Only for system operations
3. **Validate input** - Edge Functions validate all inputs
4. **Timestamps** - All tables have created_at/updated_at with triggers
5. **Indexes** - Key columns indexed for performance
6. **Constraints** - CHECK constraints for valid data
7. **Error handling** - Proper error responses with context

## Troubleshooting

### Geofencing not working

1. Check QR config: `SELECT * FROM qr_configs WHERE company_id = 'uuid'`
2. Verify `is_geofencing_enabled = true`
3. Ensure office_lat/lng are set

### RLS blocking queries

1. Check user has authenticated session
2. Verify user profile exists in company
3. Check RLS policies in Supabase dashboard

### Edge Functions timing out

1. Check function logs: `supabase functions logs`
2. Verify database connectivity
3. Increase function timeout if needed

## Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [PostgreSQL RLS](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
- [Edge Functions Guide](https://supabase.com/docs/guides/functions)
- [Deno Documentation](https://deno.land)
