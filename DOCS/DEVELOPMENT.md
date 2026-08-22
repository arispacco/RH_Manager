# Architecture et Développement

## 🏗️ Architecture Technique

L'application suit une architecture propre (Clean Architecture) simplifiée avec l'utilisation de **Bloc** pour la gestion d'état.

### Dual-Backend Engine
Le cœur de la flexibilité du projet repose sur la classe `AppConfig` et l'injection de dépendances dans `di.dart`.
- **Mode Local** : L'application communique directement avec PostgreSQL via `PostgreSQLService`.
- **Mode Supabase** : L'application utilise le SDK officiel `supabase_flutter`.

### Services Clés
- `PostgreSQLService` : Gère la connexion directe, le hachage BCrypt et les requêtes SQL complexes pour simuler les fonctionnalités Supabase en local.
- `AuthBloc` : Gère l'état d'authentification et bascule entre les fournisseurs de données.
- `AttendanceBloc` : Gère la logique de pointage et la géolocalisation.

## 🛠️ Workflow de Développement

### Ajout d'une fonctionnalité
1.  **Schéma** : Ajoutez les modifications SQL dans un nouveau fichier de migration dans `supabase/migrations/`.
2.  **Service** : Si la fonctionnalité nécessite un accès DB, mettez à jour `PostgreSQLService` pour le mode local et assurez-vous que l'équivalent Supabase existe.
3.  **Bloc** : Mettez à jour le Bloc correspondant pour supporter les deux modes de données.
4.  **UI** : Créez ou modifiez les widgets Flutter.

### Gestion des dépendances
Toutes les dépendances sont centralisées dans `lib/app/di.dart`. Utilisez `sl<Type>()` pour récupérer une instance.

## 🧪 Tests locaux
- Utilisez l'émulateur Android (l'hôte est configuré sur `10.0.2.2`).
- Pour tester le geofencing, simulez une position GPS proche de `48.8566, 2.3522` (Coordonnées d'Acme Corp).
