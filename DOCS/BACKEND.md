# Détails du Backend

## 🗄️ Schéma de la Base de Données

Le système s'appuie sur les tables suivantes :

- **`companies`** : Gère les organisations et leurs paramètres de géolocalisation.
- **`profiles`** : Informations étendues sur les utilisateurs (nom, rôle, entreprise).
- **`qr_configs`** : Configuration des QR codes pour chaque entreprise.
- **`attendance_logs`** : Historique des pointages (entrées, sorties, coordonnées GPS).
- **`users`** (Public en local, Auth dans Supabase) : Gère les identifiants et les mots de passe hachés.

## 🔐 Sécurité

### Hachage des mots de passe
- **Algorithme** : BCrypt.
- **Vérification** : Effectuée via `BCrypt.checkpw` dans `PostgreSQLService` ou gérée nativement par Supabase Auth.

### Géorepérage (Geofencing)
La sécurité du pointage est renforcée par une vérification de la distance entre l'employé et le centre de l'entreprise (`office_lat`, `office_lng`). Le rayon est configurable par entreprise.

## 📡 API et Edge Functions
En mode Supabase, l'application peut appeler des fonctions Edge pour des opérations complexes. En mode local, ces opérations sont exécutées via des requêtes directes optimisées dans le `PostgreSQLService`.
