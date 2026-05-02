# attendance_os_mobile

## Supabase setup (Flutter mobile)

Default local config is now Android-emulator friendly:
- `SUPABASE_URL` defaults to `http://10.0.2.2:54331`
- `SUPABASE_ANON_KEY` defaults to the local publishable key

If you use a physical device or cloud Supabase, override at run time:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<your-project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_xxx
```
