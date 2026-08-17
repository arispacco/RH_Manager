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

### Supabase mode (schema + backend)
- The Supabase schema is `supabase/migrations/20260505000000_app_aligned_schema.sql`, kept in sync with the Dart models (`profiles` extend `auth.users`; enums `clocked_in/clocked_out/on_break`, etc.). The earlier migrations were removed because they no longer matched the app. `supabase/seed.sql` seeds companies + QR configs; `supabase/seed_users.sh` creates the auth test users (a trigger auto-creates their `profiles`).
- `config.dart` reads `SUPABASE_URL` / `SUPABASE_ANON_KEY` at build time via `--dart-define` (defaults target the local stack). For the Android emulator use `--dart-define=SUPABASE_URL=http://10.0.2.2:54331`. For a real project, pass its URL + anon key (e.g. from Cursor **Secrets**).

#### Running the local Supabase stack (`supabase start`)
- Requires Docker, which is NOT in the base image. Enable it once per session (see the Docker-in-Docker recipe: install `docker-ce` + `fuse-overlayfs` + `iptables`, set `/etc/docker/daemon.json` to `storage-driver: fuse-overlayfs` and `features.containerd-snapshotter: false` for Docker 29, switch to `iptables-legacy`, then run `sudo dockerd &` and `sudo chmod 666 /var/run/docker.sock`).
- Then from the repo root: `supabase start` → apply schema+seed; `./supabase/seed_users.sh` → create test users. Get URL/keys with `supabase status -o json`. Local API is `http://127.0.0.1:54331` (ports come from `supabase/config.toml`). Test logins: `admin@acme.com`/`admin123`, `hr@acme.com`/`hr123`, `john.doe@acme.com`/`john123`.
- The default `BackendMode.local` (plain PostgreSQL via `.cursor/start.sh`) needs no Docker and is the zero-config path; use the Supabase stack only when working on Supabase mode.
