#!/usr/bin/env bash
# Per-boot startup for the local PostgreSQL backend (BackendMode.local).
# Idempotent: safe to run on every environment start.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Run a psql/command as the postgres OS user, whether we are root or a sudo user.
as_postgres() {
  if [ "$(id -u)" -eq 0 ]; then
    su postgres -c "$1"
  else
    sudo -u postgres bash -c "$1"
  fi
}

PG_VER="$(ls /usr/lib/postgresql | sort -n | tail -1)"

# Start the default cluster if it is not already running.
if [ "$(id -u)" -eq 0 ]; then
  pg_ctlcluster "$PG_VER" main start || true
else
  sudo pg_ctlcluster "$PG_VER" main start || true
fi

# Wait for readiness.
for _ in $(seq 1 30); do
  if pg_isready -h localhost -p 5432 >/dev/null 2>&1; then break; fi
  sleep 1
done

# Match the credentials hard-coded in flutter_app/lib/services/postgresql_service.dart
# (postgres/postgres) and the expected database name.
as_postgres "psql -tAc \"ALTER USER postgres PASSWORD 'postgres';\"" || true
if ! as_postgres "psql -tAc \"SELECT 1 FROM pg_database WHERE datname='rh_manager'\"" | grep -q 1; then
  as_postgres "createdb rh_manager"
fi

# Apply schema + seed once (guarded on the presence of the users table).
HAS_USERS="$(as_postgres "psql -d rh_manager -tAc \"SELECT to_regclass('public.users')\"" || true)"
if [ "$HAS_USERS" != "users" ]; then
  as_postgres "psql -d rh_manager -v ON_ERROR_STOP=1" < "$ROOT/supabase/migrations/local_postgres.sql"
  as_postgres "psql -d rh_manager -v ON_ERROR_STOP=1" < "$ROOT/supabase/seed_local.sql"
  echo "Applied local schema + seed to rh_manager."
fi

echo "PostgreSQL ready: rh_manager on localhost:5432 (user: postgres)"
