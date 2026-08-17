#!/usr/bin/env bash
# Create test auth users in the local Supabase stack via the GoTrue admin API.
# The `on_auth_user_created` trigger creates the matching public.profiles rows.
# Requires the local stack to be running (`supabase start`).
set -euo pipefail

STATUS_JSON="$(supabase status -o json 2>/dev/null)"
API_URL="$(printf '%s' "$STATUS_JSON" | python3 -c 'import sys,json;print(json.load(sys.stdin)["API_URL"])')"
SERVICE_ROLE_KEY="$(printf '%s' "$STATUS_JSON" | python3 -c 'import sys,json;print(json.load(sys.stdin)["SERVICE_ROLE_KEY"])')"

create_user() {
  local email="$1" password="$2" first="$3" last="$4" role="$5"
  curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$API_URL/auth/v1/admin/users" \
    -H "apikey: $SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$email\",\"password\":\"$password\",\"email_confirm\":true,\"user_metadata\":{\"first_name\":\"$first\",\"last_name\":\"$last\",\"role\":\"$role\"}}"
  echo " <- $email ($role)"
}

echo "Seeding auth users into $API_URL ..."
create_user "admin@acme.com"     "admin123" "Admin" "User"    "admin"
create_user "hr@acme.com"        "hr123"    "HR"    "Manager" "hr"
create_user "john.doe@acme.com"  "john123"  "John"  "Doe"     "employee"
echo "Done."
