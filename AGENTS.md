# RH_Manager

Mobile workforce attendance platform. A **Flutter** app (`flutter_app/`) with a **dual backend**: it can talk either to a **local PostgreSQL** database or to an **online Supabase** project. SQL schema, migrations and seeds live in `supabase/`.

See `README.md` and `DOCS/` (`SETUP.md`, `DEVELOPMENT.md`, `BACKEND.md`) for product/architecture details.

## Cursor Cloud specific instructions

### Environment layout
- The environment is defined by `.cursor/environment.json` + `.cursor/Dockerfile` (repository-managed build), so it is the source of truth — changing the toolchain means editing those files, not saving a snapshot.
- Base image `ghcr.io/cirruslabs/flutter:3.41.8` provides **Flutter 3.41.8** (matching `.github/workflows/build-apk.yml`), the **Android SDK** (build-tools/platforms/licenses) and a compatible **JDK**. The Dockerfile adds **PostgreSQL** and the **Supabase CLI**.
- `install` runs `flutter pub get` in `flutter_app/`. `start` runs `.cursor/start.sh`, which boots PostgreSQL and (idempotently) creates + seeds the `rh_manager` database.
- Do NOT pin a newer Flutter (e.g. latest stable). This project's Gradle wrapper is `8.11.1`; Flutter ≥ 3.47 requires Gradle ≥ 8.14 and the APK build fails. Stay on 3.41.8.

### Flutter app (`flutter_app/`)
- Standard commands mirror `.github/workflows/dart.yml`: `flutter analyze`, `flutter test`; APK via `flutter build apk --debug` (or `--release`), see also `.github/workflows/build-apk.yml` and `build-apk.sh`.
- Backend mode is selected in `flutter_app/lib/app/config.dart` (`BackendMode.local` default) and can be toggled with `./manage_env.sh`.

### Local PostgreSQL backend
- `.cursor/start.sh` provisions `rh_manager` on `localhost:5432` with user/password `postgres`/`postgres` (the values hard-coded in `lib/services/postgresql_service.dart`; note the app uses host `10.0.2.2` when running on the Android emulator).
- Schema/seed come from `supabase/migrations/local_postgres.sql` and `supabase/seed_local.sql`. Local seed logins use short passwords, e.g. `admin@acme.com` / `admin123` (BCrypt-hashed via pgcrypto). The `DOCS/SETUP.md` table refers to the Supabase `seed.sql` instead.

### Online Supabase mode
- Set `BackendMode.supabase` and provide the project URL + anon key (in `config.dart`, or supply them as Cursor **Secrets** and wire them in). The Supabase CLI is available for migrations/type generation.
- `supabase start` (full local stack) needs Docker, which is NOT installed in this image; use the local PostgreSQL path above for offline development.

### Known pre-existing issues (unmerged WIP branch — not environment problems)
- `flutter analyze` reports 2 compile errors in `lib/services/supabase_service.dart` (Supabase mode only): `asin` is called as a method on `double` (should be `dart:math`'s `math.asin(...)`), and `RealtimeChannel.onPostgresChange` should be `onPostgresChanges(..., callback: ...)`. These block a clean `flutter build apk` until fixed.
- `flutter test` (`test/widget_test.dart`) fails in `setUpAll`: `initDependencies()` calls `SharedPreferences.getInstance()` without `TestWidgetsFlutterBinding.ensureInitialized()` + `SharedPreferences.setMockInitialValues({})`, causing `MissingPluginException`.
