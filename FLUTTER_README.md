# RH Manager - Mobile App (Flutter)

App mobile de gestion des présences avec Flutter + Dart + Supabase.

## Architecture

### Services (`lib/services/`)
- **SupabaseService**: Singleton gérant toute la communication avec Supabase
  - Auth (sign up, sign in, sign out)
  - Profile CRUD
  - Attendance (clock in/out)
  - Company management
  - QR Config lookup
  - Geofencing helpers
  - Real-time subscriptions

### Models (`lib/models/`)
- `Company`: Société avec géofence
- `Profile`: Utilisateur étendu (roles: superAdmin, owner, admin, hr, employee, kiosk)
- `QRConfig`: Configuration QR active
- `AttendanceLog`: Logs entrée/sortie avec coordonnées GPS

### State Management (`lib/cubits/`)
- **AuthCubit**: Authentification et profil utilisateur
  - SignUp, SignIn, SignOut, CheckAuthStatus
  - États: Initial, Loading, Authenticated, Unauthenticated, Error
  
- **AttendanceCubit**: Gestion des présences
  - ClockIn (avec validation géofence)
  - ClockOut
  - Load attendance history
  - Load company attendance (pour admins)
  - États: Loading, ClockedIn, ClockedOut, HistoryLoaded, Error

### Dépendances Clés
- `supabase_flutter: ^2.5.4` - Client Supabase
- `flutter_bloc: ^9.1.0` - State management
- `geolocator: ^13.0.2` - Localisation GPS
- `permission_handler: ^11.3.0` - Permissions
- `mobile_scanner: ^5.2.3` - Scan QR codes
- `logger: ^2.5.0` - Logging

## Configuration Locale

### Démarrer la base de données

```bash
# Dans le répertoire du projet
docker-compose up -d

# Vérifier les services
docker ps

# Vérifier les logs
docker-compose logs -f postgres studio
```

Services actifs:
- PostgreSQL: localhost:54332
- Supabase Studio: http://localhost:3001

### Appliquer les migrations

```bash
# Via Supabase Studio: http://localhost:3001
# Ou via psql:
psql postgresql://postgres:postgres@localhost:54332/postgres < supabase/migrations/20260504000000_complete_backend.sql

# Charger les données de test
psql postgresql://postgres:postgres@localhost:54332/postgres < supabase/seed.sql
```

### Configuration Flutter

Pour l'émulateur Android, modifier `lib/core/constants/app_constants.dart`:
```dart
// Remplacer localhost par 10.0.2.2 (l'adresse de la machine hôte)
static const String supabaseUrl = 'http://10.0.2.2:8000';
```

## Flux d'utilisation

### 1. Authentification
```
User → SignIn/SignUp → Supabase Auth → Profile Loaded
```

### 2. Clock In
```
Employee → Demande Location → Validation Géofence → Scan QR (optionnel) → Clock In → AttendanceLog créé
```

### 3. Clock Out
```
Employee → Demande Location → Clock Out → AttendanceLog mis à jour
```

### 4. Voir l'Historique
```
Employee → Load History (30 jours défaut) → List d'AttendanceLogs

Admin/HR → Load Company Attendance → Tous les logs de la compagnie
```

## Utilisation des Cubits

### Dans les Widgets

```dart
// Accès via BlocProvider
BlocProvider(
  create: (context) => sl<AuthCubit>()..checkAuthStatus(),
  child: MaterialApp(...)
)

// Écouter les changements
BlocListener<AuthCubit, AuthState>(
  listener: (context, state) {
    if (state is AuthAuthenticated) {
      context.go('/dashboard');
    } else if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message))
      );
    }
  },
  child: const SizedBox.shrink(),
)

// Afficher l'état
BlocBuilder<AuthCubit, AuthState>(
  builder: (context, state) {
    if (state is AuthLoading) return const CircularProgressIndicator();
    if (state is AuthAuthenticated) {
      return Text('Welcome ${state.profile.fullName}');
    }
    return const SizedBox.shrink();
  },
)
```

### Clock In Example

```dart
Future<void> _handleClockIn() async {
  final authState = context.read<AuthCubit>().state;
  if (authState is! AuthAuthenticated) return;

  final position = await Geolocator.getCurrentPosition();
  
  context.read<AttendanceCubit>().clockIn(
    profileId: authState.profile.id,
    qrConfigId: _scannedQRCode,
    latitude: position.latitude,
    longitude: position.longitude,
    companyLat: company.latitude!,
    companyLng: company.longitude!,
    geofenceRadius: company.geofenceRadius ?? 0.1,
  );
}
```

## Structure de la base de données

```
companies
├── id (uuid)
├── name
├── description
├── address
├── latitude, longitude
├── geofence_radius (km)

profiles (extends auth.users)
├── id (uuid) - foreign key auth.users.id
├── email
├── first_name, last_name
├── phone, avatar_url
├── company_id
├── role (enum: superAdmin, owner, admin, hr, employee, kiosk)
├── status (enum: active, inactive, onLeave)

qr_configs
├── id (uuid)
├── company_id
├── config_code (unique)
├── name
├── active (boolean)

attendance_logs
├── id (uuid)
├── profile_id
├── qr_config_id (nullable)
├── clock_in_time
├── clock_out_time (nullable)
├── clock_in_lat, clock_in_lng
├── clock_out_lat, clock_out_lng (nullable)
├── status (enum: clockedIn, clockedOut, onBreak)
├── notes
```

## RLS (Row-Level Security)

Toutes les tables ont des politiques RLS:
- Les employés ne voient que leurs propres données
- Les admins/HR voient les données de leur compagnie
- Les superadmins voient tout
- Les kiosks ne peuvent que créer des logs

## Prochaines étapes

1. **UI Screens** - Implémenter les écrans Flutter pour:
   - Login / Register
   - Employee Dashboard (clock in/out, history)
   - Admin Dashboard (company attendance report)
   - QR Scanner
   
2. **Real-time** - Ajouter les subscriptions temps réel pour les mises à jour d'attendance

3. **Offline Support** - Implémenter la mise en cache locale avec Hive ou sqflite

4. **Push Notifications** - Configurer Firebase Cloud Messaging pour les alertes

5. **Tests** - Ajouter des tests unitaires et d'intégration
