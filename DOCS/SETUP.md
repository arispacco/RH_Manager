# Guide d'Installation

Ce guide vous aide à configurer l'environnement de développement pour RH_Manager.

## 1. Prérequis
- **Flutter SDK** : [Installation](https://docs.flutter.dev/get-started/install)
- **PostgreSQL** : (Pour le mode local) Installé et tournant sur le port 5432.
- **Supabase CLI** : (Pour les migrations et le mode en ligne) `npm install -g supabase`

## 2. Configuration du Backend Local (PostgreSQL)

### Création de la base de données
1. Créez une base de données nommée `rh_manager`.
2. Appliquez les migrations situées dans `supabase/migrations/` (ou utilisez la commande `supabase db push` si vous utilisez le stack Supabase local).

### Chargement des données de test
Exécutez le script de seed pour avoir des utilisateurs fonctionnels :
```bash
psql -d rh_manager -f supabase/seed.sql
```

### Identifiants de test
| Email | Mot de passe |
| :--- | :--- |
| `admin@acme.com` | `password` |
| `hr@acme.com` | `password` |
| `john.doe@acme.com` | `password` |

## 3. Configuration de Supabase (Online)
1. Créez un projet sur [Supabase.com](https://supabase.com).
2. Copiez l'URL de votre projet et la clé API `anon` dans `lib/app/config.dart`.
3. Appliquez le schéma SQL via l'éditeur SQL de Supabase.

## 4. Basculement d'environnement
Utilisez le script interactif à la racine :
```bash
./manage_env.sh
```
Choisissez l'option **1** pour le mode local ou **2** pour le mode Supabase.
