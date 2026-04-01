# TrustPay - Gestion Financière & Paiement QR

Application mobile et desktop moderne pour la gestion financière en Afrique de l'Ouest.

## 🚀 Fonctionnalités
- **Dashboard Holistique** : Vue d'ensemble des soldes, revenus et dépenses.
- **Gestion Multi-comptes** : Cash, Mobile Money (MTN, Moov), Banques.
- **Paiements QR** : Scanner et générer des codes QR pour les transactions.
- **Score Financier** : Analyse de la santé financière basée sur les habitudes de dépense.
- **Offline-First** : Fonctionne sans connexion avec synchronisation Hive.
- **Clean Architecture** : Code modulaire, testable et évolutif.

## 🛠 Stack Technique
- **Flutter** (Latest Stable)
- **State Management** : BLoC / Cubit
- **Navigation** : GoRouter (ShellRoute pour le responsive)
- **Base de données** : Hive
- **Client API** : Dio + Interceptors
- **DI** : GetIt

## 📂 Architecture
Le projet suit les principes de la **Clean Architecture** :
- `core/` : Code partagé (thème, navigation, network, utils).
- `domain/` : Logique métier (entities, repositories abstracts, usecases).
- `data/` : Implémentation de la donnée (models, repositories impl, datasources).
- `presentation/` : UI (pages, widgets, blocs).

## 🏁 Installation
1. S'assurer que Flutter est installé.
2. Cloner le projet.
3. Exécuter `flutter pub get`.
4. Exécuter `flutter run`.

## 🔌 API Integration
L'application est configurée pour consommer une API Django REST. 
Les endpoints sont définis dans `lib/config/api_config.dart`.
Le `DioClient` gère automatiquement les headers JWT.
