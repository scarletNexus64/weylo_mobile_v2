# Guide Shorebird - Mises à Jour Automatiques 🚀

Ce guide explique comment utiliser Shorebird pour les mises à jour automatiques (OTA - Over The Air) dans l'application Weylo.

## 📋 Table des Matières

1. [Configuration Initiale](#configuration-initiale)
2. [Comment ça Marche](#comment-ça-marche)
3. [Utilisation](#utilisation)
4. [Afficher la Notification de MAJ](#afficher-la-notification-de-maj)
5. [Commandes Utiles](#commandes-utiles)
6. [Limitations](#limitations)

---

## 🔧 Configuration Initiale

### 1. Installer Shorebird CLI

```bash
# macOS/Linux
curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash

# Windows
powershell -c "irm https://raw.githubusercontent.com/shorebirdtech/install/main/install.ps1 | iex"
```

### 2. Créer un Compte Shorebird

```bash
shorebird login
```

### 3. Initialiser le Projet

```bash
# Dans le dossier du projet
shorebird init
```

### 4. Permissions Android

Vérifiez que le fichier `android/app/src/main/AndroidManifest.xml` contient :

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## 🎯 Comment ça Marche

### Stratégie Intelligente

L'implémentation actuelle est **non intrusive** et fonctionne ainsi :

1. **Au lancement de l'app** : Vérification automatique en arrière-plan
2. **Téléchargement silencieux** : Si une MAJ est disponible, elle est téléchargée sans bloquer l'utilisateur
3. **Application au prochain lancement** : La mise à jour est appliquée quand l'utilisateur redémarre l'app naturellement
4. **Notification optionnelle** : Un banner discret peut proposer de redémarrer immédiatement

### Pas de Redémarrage Automatique !

**IMPORTANT** : Il est techniquement **impossible** d'appliquer une mise à jour Shorebird sans redémarrer l'application. C'est une limitation de Flutter et du système.

**Cependant**, notre stratégie est intelligente :
- ✅ Téléchargement en arrière-plan pendant que l'utilisateur utilise l'app
- ✅ Pas d'interruption forcée
- ✅ MAJ appliquée au prochain lancement naturel
- ✅ Option pour redémarrer immédiatement (non forcée)

### Rate Limiting

Le service vérifie les mises à jour automatiquement avec un intervalle de **6 heures** pour éviter de surcharger le réseau et la batterie.

---

## 🚀 Utilisation

### Build Initial (Release)

Pour la première release :

```bash
# Android
shorebird release android

# iOS
shorebird release ios
```

### Envoyer une Mise à Jour (Patch)

Pour envoyer une mise à jour OTA après la release :

```bash
# Android
shorebird patch android

# iOS
shorebird patch ios
```

### Workflow Typique

1. **Première Release** :
   ```bash
   shorebird release android --flutter-version=3.10.4
   ```

2. **Correction de Bug / Mise à Jour** :
   - Modifiez votre code
   - Testez en local
   - Envoyez un patch :
   ```bash
   shorebird patch android
   ```

3. **Les Utilisateurs** :
   - Reçoivent automatiquement la mise à jour au prochain lancement
   - Aucune action requise de leur part
   - Pas besoin de passer par le Play Store/App Store

---

## 📱 Afficher la Notification de MAJ

### Option 1 : Banner Permanent (Recommandé)

Ajoutez le widget dans votre scaffold principal :

```dart
import 'package:weylo/app/widgets/update_notification_widget.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // Votre contenu principal
        YourMainContent(),

        // Banner de mise à jour (en haut)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: UpdateNotificationWidget(),
        ),
      ],
    ),
  );
}
```

### Option 2 : Snackbar Ponctuelle

Affichez une notification ponctuelle :

```dart
import 'package:weylo/app/widgets/update_notification_widget.dart';

// Dans votre logique
final updateService = Get.find<ShorebirdUpdateService>();
if (updateService.isUpdateAvailable.value &&
    updateService.updateStatus.value == 'Prêt à redémarrer') {
  UpdateSnackbar.show();
}
```

### Option 3 : Vérification Manuelle

Pour vérifier manuellement depuis les paramètres :

```dart
import 'package:get/get.dart';
import 'package:weylo/app/data/services/shorebird_update_service.dart';

// Dans un bouton "Vérifier les mises à jour"
final updateService = Get.find<ShorebirdUpdateService>();
await updateService.forceCheckForUpdates();

// Afficher les infos
final info = await updateService.getAppInfo();
print('Patch actuel: ${info['currentPatch']}');
print('MAJ disponible: ${info['updateAvailable']}');
```

---

## 🛠 Commandes Utiles

### Vérifier l'État

```bash
# Lister les releases
shorebird releases list

# Lister les patches d'une release
shorebird patches list

# Voir les infos du projet
shorebird doctor
```

### Debug

```bash
# Tester en local (pas de patch créé)
flutter run

# Voir les logs Shorebird dans l'app
# Regardez les logs avec le préfixe [SHOREBIRD]
```

### Gestion

```bash
# Supprimer une release
shorebird releases delete <release-version>

# Promouvoir un patch en production
shorebird releases promote <release-version>
```

---

## ⚠️ Limitations

### Ce qui PEUT être mis à jour (Dart uniquement)

✅ Logique métier (code Dart)
✅ UI/Widgets Flutter
✅ Corrections de bugs
✅ Nouvelles features (code Dart)
✅ Changements de styles/couleurs

### Ce qui NE PEUT PAS être mis à jour

❌ Code natif (Java/Kotlin/Swift/Objective-C)
❌ Dépendances natives
❌ Permissions Android/iOS
❌ Configuration AndroidManifest.xml / Info.plist
❌ Assets natifs (splash screen, icônes)

**Pour ces changements, il faut publier une nouvelle version sur les stores.**

### Autres Limitations

- **Pas de MAJ sans redémarrage** : L'app doit être relancée
- **Taille des patches** : Limitée (généralement < 10 MB)
- **Réseau requis** : L'utilisateur doit avoir une connexion internet

---

## 📊 Monitoring

Le service expose plusieurs observables pour suivre l'état :

```dart
final updateService = Get.find<ShorebirdUpdateService>();

// État
updateService.isUpdateAvailable.value;  // bool
updateService.isDownloading.value;      // bool
updateService.downloadProgress.value;   // 0.0 - 1.0
updateService.updateStatus.value;       // String
updateService.currentPatchNumber.value; // int?
```

---

## 🎨 Personnalisation

### Changer l'Intervalle de Vérification

Dans `shorebird_update_service.dart` :

```dart
// Configuration
static const Duration _checkInterval = Duration(hours: 6); // Modifiez ici
```

### Personnaliser le Banner

Modifiez `update_notification_widget.dart` pour adapter les couleurs, le texte, etc.

---

## 🐛 Dépannage

### "Shorebird non disponible (normal en dev)"

C'est normal en mode développement. Shorebird fonctionne uniquement avec les builds de release créés via `shorebird release`.

### Les Mises à Jour ne s'Appliquent pas

1. Vérifiez que l'app a été buildée avec `shorebird release`
2. Vérifiez que le patch a été envoyé avec `shorebird patch`
3. Vérifiez les logs `[SHOREBIRD]` dans la console
4. Forcez une vérification : `updateService.forceCheckForUpdates()`

### Tester en Local

```bash
# Build de release en local
shorebird release android --local

# Run en mode release
flutter run --release
```

---

## 📚 Ressources

- [Documentation Officielle](https://docs.shorebird.dev/)
- [GitHub Shorebird](https://github.com/shorebirdtech/shorebird)
- [Package shorebird_code_push](https://pub.dev/packages/shorebird_code_push)

---

**Bon déploiement ! 🎉**
