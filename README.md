# RH_Manager - Système de Gestion de Présence

RH_Manager est une solution mobile moderne pour la gestion du temps et de la présence des employés, utilisant la géolocalisation et des QR codes dynamiques.

## 🚀 Caractéristiques principales
- **Mode Dual-Backend** : Basculez entre un environnement **Local (PostgreSQL)** et la **Production (Supabase)**.
- **Authentification Sécurisée** : Sessions persistantes et hachage BCrypt.
- **Gestion de Présence** : Pointage (Clock-in/out) avec vérification de géorepérage (geofencing).
- **Design Premium** : Interface utilisateur moderne et réactive développée avec Flutter.

## 📁 Structure du Projet
- `flutter_app/` : Application mobile Flutter.
- `supabase/` : Migrations et données de test pour la base de données.
- `DOCS/` : Documentation détaillée.

## 🛠️ Démarrage Rapide
1.  **Choisir l'environnement** :
    ```bash
    ./manage_env.sh
    ```
2.  **Lancer l'application** :
    ```bash
    cd flutter_app
    flutter run
    ```

## 📚 Documentation
- [Guide d'installation](DOCS/SETUP.md)
- [Architecture et Développement](DOCS/DEVELOPMENT.md)
- [Détails du Backend](DOCS/BACKEND.md)

---
*Développé pour une fiabilité maximale, avec ou sans connexion internet.*
