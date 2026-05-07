# RH Manager - Local PostgreSQL Setup

Configuration pour développer avec PostgreSQL local sans Docker.

## Prerequisites

- PostgreSQL 15+ installé et en cours d'exécution
- Flutter SDK v3.5+
- Dart v3.5+

## Setup PostgreSQL Local

### 1. Vérifier PostgreSQL

```bash
psql --version
psql -U postgres -d postgres -c "SELECT version();"
```

### 2. Créer la base de données

```bash
psql -U postgres -c "CREATE DATABASE rh_manager;"
```

### 3. Appliquer les migrations

```bash
# Dans le répertoire du projet
psql -U postgres -d rh_manager < supabase/migrations/local_postgres.sql
```

Résultat attendu:
```
CREATE EXTENSION
CREATE EXTENSION
CREATE TYPE
CREATE TYPE
CREATE TYPE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE INDEX
...
CREATE FUNCTION
CREATE TRIGGER
```

### 4. Charger les données de test

```bash
psql -U postgres -d rh_manager < supabase/seed_local.sql
```

Utilisateurs de test:
- `admin@acme.com` / `admin123`
- `hr@acme.com` / `hr123`
- `john.doe@acme.com` / `john123`
- `jane.smith@acme.com` / `jane123`

### 5. Vérifier les données

```bash
psql -U postgres -d rh_manager -c "SELECT COUNT(*) FROM companies; SELECT COUNT(*) FROM profiles; SELECT COUNT(*) FROM attendance_logs;"
```

## Configuration Flutter

### 1. Installation des dépendances

```bash
cd flutter_app
flutter pub get
```

### 2. Paramètres de connexion

Dans `lib/services/postgresql_service.dart`:
```dart
static const String _host = 'localhost';
static const int _port = 5432;
static const String _database = 'rh_manager';
static const String _username = 'postgres';
static const String _password = 'postgres';
```

Modifier si nécessaire.

## Lancer l'app Flutter

### Émulateur Android

```bash
flutter emulators launch Pixel_4_API_33
flutter run
```

### Appareil physique

```bash
flutter run
```

## Architecture

### PostgreSQL Local Service

Le fichier `lib/services/postgresql_service.dart` gère:
- Connexion DirectSQL à PostgreSQL via le package `postgres`
- CRUD operations sur les entités
- Geofencing calculations
- Hashing des mots de passe

### Cubits pour State Management

- `AuthCubit`: Authentification avec PostgreSQL
- `AttendanceCubit`: Gestion des présences

### Données de test

- 2 compagnies (ACME Corp, Tech Innovators)
- 4 utilisateurs avec différents rôles
- 2 configurations QR
- Logs d'attendance d'exemple

## Flux d'utilisation

### 1. Authentification

```
Login Page → SignIn() → Query users table → Load profile → Navigate to Dashboard
```

### 2. Clock In

```
Employee Dashboard → Request location → Validate geofence → Insert attendance_log → Show success
```

### 3. Clock Out

```
Update attendance_log → Set status to clocked_out → Show duration worked
```

### 4. Voir l'historique

```
Load history (30 derniers jours) → Display list of AttendanceLogs
```

## Troubleshooting

### Erreur: "connection refused"

```bash
# Vérifier que PostgreSQL est en cours d'exécution
psql -U postgres -c "SELECT 1"

# Sur Linux
sudo systemctl status postgresql

# Sur macOS
brew services list
```

### Erreur: "FATAL: role 'postgres' does not exist"

Créer le rôle:
```bash
createuser postgres --superuser
psql -U postgres -c "ALTER USER postgres WITH PASSWORD 'postgres';"
```

### Erreur: "database 'rh_manager' does not exist"

Recréer:
```bash
psql -U postgres -c "DROP DATABASE IF EXISTS rh_manager;"
psql -U postgres -c "CREATE DATABASE rh_manager;"
psql -U postgres -d rh_manager < supabase/migrations/local_postgres.sql
psql -U postgres -d rh_manager < supabase/seed_local.sql
```

### Erreur: "permission denied"

Vérifier les permissions:
```bash
# Réinitialiser les permissions
psql -U postgres -d rh_manager -c "GRANT ALL PRIVILEGES ON SCHEMA public TO postgres; GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;"
```

## Migration vers Supabase Cloud

Quand vous êtes prêt pour la production:

1. Créer un projet Supabase cloud
2. Les migrations SQL `local_postgres.sql` sont compatibles avec Supabase PostgreSQL
3. Copier les migrations vers Supabase
4. Mettre à jour `lib/services/postgresql_service.dart` ou créer un nouveau `SupabaseService` pour se connecter au cloud
5. Utiliser l'authentification Supabase (GoTrue) au lieu du hash local

## Commandes utiles

```bash
# Connexion à la DB
psql -U postgres -d rh_manager

# Lister les tables
psql -U postgres -d rh_manager -c "\\dt"

# Voir la structure d'une table
psql -U postgres -d rh_manager -c "\\d profiles"

# Exporter les données
pg_dump -U postgres rh_manager > backup.sql

# Importer les données
psql -U postgres rh_manager < backup.sql

# Supprimer la DB
psql -U postgres -c "DROP DATABASE rh_manager;"
```

## Notes

- Les migrations sont écrites en PostgreSQL pur, compatible avec Supabase
- Les enums sont en snake_case en DB, camelCase en Dart
- Les mots de passe sont hashés en SHA256 (utiliser bcrypt en production)
- Pas de RLS en local (ajouter en production via Supabase)
