# Suivi de l'évolution et Préparation à la Production (AttendanceOS)

Ce document trace les modifications majeures apportées au projet `RH_Manager`, les risques potentiels identifiés, et les étapes critiques restant à accomplir avant le déploiement en production.

## 1. État Actuel du Projet (Backend & Frontend)

Le projet utilise **Flutter** pour l'application cliente (Kiosk + Mobile Employé/Admin) et **Supabase** en local pour le backend (Base de données PostgreSQL, Authentification, Edge Functions).

### Modifications Majeures Effectuées (À Risque)

*   **Correction de la configuration réseau Flutter :**
    *   **Modification :** Remplacement de l'IP `10.0.2.2` par `127.0.0.1` dans `lib/core/constants/app_constants.dart` pour permettre à l'application de tourner sur Linux/Web localement.
    *   **Risque :** Si l'application doit être testée sur un émulateur Android, la connexion au backend local échouera (Timeout). Il faudra repasser à `10.0.2.2` ou utiliser le flag `--dart-define=SUPABASE_URL=http://10.0.2.2:54331`. En production, cette valeur sera l'URL publique de Supabase.

*   **Correction du crash de l'API d'Authentification Supabase (GoTrue) :**
    *   **Problème initial :** Erreur `500 Internal Server Error` lors de la connexion. Le serveur GoTrue paniquait face aux valeurs `NULL` insérées par le script `seed.sql` dans la table système `auth.users`.
    *   **Modification :** Mise à jour manuelle de la base de données locale (`auth.users`) pour remplacer les `NULL` des colonnes `confirmation_token`, `email_change`, `phone_change`, etc., par des chaînes vides `''`. Forçage des mots de passe des comptes de test à `password123` via `crypt('password123', gen_salt('bf', 10))`.
    *   **Risque / Info :** Lors d'un `supabase db reset`, ces données factices avec des `NULL` pourraient réapparaître si le script `seed.sql` n'est pas lui-même purgé de ses insertions manuelles dans `auth.users`. En production, ce bug n'arrivera pas car les utilisateurs seront créés via l'API (qui gère bien les valeurs par défaut).

*   **Création de l'Edge Function `create_user` (Logique Métier Admin) :**
    *   **Modification :** Ajout d'une fonction Deno TypeScript (`supabase/functions/create_user/index.ts`) permettant à un Administrateur de créer un compte RH/Employé sans être déconnecté de sa session. La fonction utilise le *Service Role Key* (API Admin).
    *   **Risque :** Assurez-vous que les variables d'environnement (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`) sont correctement définies sur le serveur de production Supabase pour cette fonction.

*   **Logique de Pointage Sécurisée (RPC PostgreSQL) :**
    *   **Modification :** Création du fichier de migration `20260502000000_attendance_logic.sql` contenant les fonctions `clock_in` et `clock_out`.
    *   **Sécurité intégrée :** La fonction `clock_in` intègre désormais le **Geofencing** (formule de Haversine pour calculer la distance GPS) et le **blocage du double-pointage** directement côté serveur.

---

## 2. Améliorations Futures et Étapes avant Production

### A. Sécurisation du Système QR Code (Terminé ✅)
Actuellement, la borne (Kiosk) génère un QR code avec une donnée "Mock" (`COMPANY_ID_MOCK_1714...`). 
*   **Fait :** Le Kiosk génère désormais un jeton signé avec HMAC-SHA256 en utilisant un `qr_secret` propre à l'entreprise.
*   **Fait :** La fonction RPC `clock_in` a été mise à jour pour décomposer le jeton, vérifier la validité de l'entreprise, s'assurer que l'heure de génération (timestamp) date de moins de 45 secondes, et re-calculer la signature cryptographique pour authentifier le scan.

### B. Intégration Frontend / Backend (Attendance) (Terminé ✅)
*   **Fait :** Le bloc d'authentification Flutter a été connecté au backend de la manière suivante :
    1. Utilisation du `LocationService` pour extraire la Latitude et la Longitude exactes de l'employé au moment du scan.
    2. Envoi de ces données via la fonction sécurisée `supabase.rpc('clock_in')`. L'application capture les exceptions renvoyées par PostgreSQL (comme "Trop loin" ou "Jeton expiré") pour les afficher à l'utilisateur.

### C. Gestion des Rôles et Dashboard
*   **Action requise :** Lier les interfaces Flutter existantes avec les requêtes de base de données. Par exemple, l'écran "Employee Directory" doit requêter la table `public.profiles` plutôt que d'utiliser des données en dur (mockées).
*   **Action requise :** S'assurer que le profil "RH" dispose d'un écran dédié pour approuver/voir les présences.

### D. Migration vers la Production Supabase
1.  Créer un projet sur Supabase.com.
2.  Lier le projet local : `supabase link --project-ref <ID>`.
3.  Pousser la structure de la BDD et le RLS : `supabase db push`.
4.  Déployer l'Edge Function : `supabase functions deploy create_user`.
5.  Mettre à jour l'URL et la clé `anon` de production dans le code Flutter.

## 3. Débogage Rapide (Troubleshooting)

*   **Si l'app reste bloquée sur "Sign In" (Chargement infini) :** Vérifiez l'URL Supabase dans `app_constants.dart` (`127.0.0.1` vs `10.0.2.2`). Vérifiez si les conteneurs Docker locaux tournent (`npx supabase status`).
*   **Si l'app affiche "500 Internal Server Error" à la connexion :** Il y a probablement des valeurs `NULL` dans la table `auth.users` pour les champs tokens. (Voir section 1).
*   **Si un employé ne peut pas pointer ("Trop loin") :** Vérifiez que la table `qr_configs` contient bien les bonnes coordonnées GPS (`office_lat`, `office_lng`) pour l'entreprise (`company_id`) de l'employé.
