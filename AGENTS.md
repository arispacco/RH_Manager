# AttendanceOS

Workforce management platform for tracking attendance, analyzing trends, and operational oversight. This repo contains two products:

1. **Web app** (root) — React 19 + Vite 6 + TypeScript, styled with Tailwind CSS v4. This is the primary product.
2. **Flutter mobile prototype** (`flutter_app/`) — a Flutter skeleton mirroring the web front-end flow.

## Cursor Cloud specific instructions

### Web app (root)

- Dependencies are installed with `npm install` (this is the update script, run automatically on startup).
- Scripts (see `package.json`): `npm run dev` (Vite dev server on port 3000, host 0.0.0.0), `npm run build` (production build, no type-checking), `npm run lint` (`tsc --noEmit`), `npm run preview`.
- Auth is fully mocked (no backend). On the login screen, the role is inferred from the email: an address containing `admin` logs in as super admin, one containing `hr` logs in as HR, anything else is an employee. Password is not validated. Use e.g. `admin@test.com` to reach the admin dashboard.
- `npm run lint` (`tsc --noEmit`) currently FAILS on `main` with pre-existing errors: `src/views/HRDashboard.tsx` uses `cn(...)` without importing it (`Cannot find name 'cn'`). This is a repository code bug, not an environment issue. Because of it, logging in as an `hr@...` user will crash the HR dashboard at runtime (`cn` is undefined). Prefer the admin or employee role for smoke-testing until this is fixed.
- `@google/genai` and `GEMINI_API_KEY` appear in dependencies/`.env.example` but are not referenced anywhere in `src/`, so no Gemini key is required to run the web app.

### Flutter mobile prototype (`flutter_app/`)

- The Flutter SDK is NOT part of the base image and is intentionally kept out of the startup update script (large system dependency). Install it on demand when working on the mobile app:
  - `git clone --depth 1 -b stable https://github.com/flutter/flutter.git $HOME/flutter`
  - `export PATH="$HOME/flutter/bin:$PATH"` then run `flutter --version` once (downloads the bundled Dart SDK).
- Standard commands (from `flutter_app/`, mirroring `.github/workflows/dart.yml`): `flutter pub get`, `flutter analyze`, `flutter test`.
- `flutter pub get` on a newer stable SDK may rewrite `analysis_options.yaml` and `pubspec.lock`; do not commit those incidental changes unless intended.
- Building the Android APK (`.github/workflows/build-apk.yml`) additionally requires the Android SDK, which is not installed here.
