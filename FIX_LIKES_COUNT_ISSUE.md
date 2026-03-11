# Fix - Problème de Compteur de Likes (0 → 25 → 24)

## 📋 Problème Rapporté

L'utilisateur constate que :
1. Au chargement initial d'une confession, `likesCount` affiche **0**
2. Après avoir cliqué sur "like", le compteur passe à **25**
3. Après avoir cliqué sur "dislike", le compteur passe à **24**

**Comportement attendu** : Le compteur devrait afficher **24** dès le chargement initial.

---

## 🔍 Analyse

### Vérifications effectuées

1. **Backend Laravel** ✅
   - Le modèle `Confession` a bien un champ `likes_count` dans la DB
   - Le `ConfessionResource` renvoie correctement `likes_count`
   - Les méthodes `like()` et `unlike()` retournent le compteur correct via `$confession->fresh()->likes_count`
   - Test effectué : Une confession en DB a `likes_count = 100` et le JSON API renvoie bien cette valeur

2. **Frontend Flutter** ⚠️
   - Le modèle `ConfessionModel.fromJson()` parse correctement `likes_count`
   - Le cache sérialise/désérialise correctement les confessions
   - **PROBLÈME IDENTIFIÉ** : Après un like/unlike, le cache persistant n'est PAS mis à jour

### Cause Racine

Le problème vient de l'**incohérence du cache** :

1. L'utilisateur charge les confessions depuis le cache (données potentiellement obsolètes)
2. Le cache peut contenir des valeurs incorrectes de `likesCount`
3. Quand l'utilisateur like/unlike, l'API renvoie le compteur correct
4. **MAIS** ce nouveau compteur n'est pas sauvegardé dans le cache persistant
5. Au prochain chargement de l'app, le cache obsolète est à nouveau utilisé

---

## ✅ Solution Implémentée

### 1. Mise à jour du cache après like/unlike

**Fichier** : `lib/app/modules/feeds/controllers/feeds_controller.dart`

**Modification dans la méthode `toggleLike()`** :

```dart
// Mettre à jour le cache mémoire
_confessionCache[confessionId] = confessions[index];

// ✨ NOUVEAU: Sauvegarder dans le cache persistant pour éviter les incohérences
await _cache.saveConfessionsCache(confessions.toList(), page: currentPage);
print('💾 [LIKE] Cache updated after like/unlike');
```

**Effet** :
- Après chaque like/unlike, le cache persistant est mis à jour avec les nouvelles valeurs
- Les données restent cohérentes entre les sessions

### 2. Logs de débogage ajoutés

Pour faciliter le débogage futur, des logs détaillés ont été ajoutés :

#### Au chargement depuis le cache
```dart
// Debug: Vérifier les likes_count dans le cache
if (cachedConfessions.isNotEmpty) {
  final firstConfession = cachedConfessions.first;
  print('🔍 [DEBUG] First cached confession - ID: ${firstConfession.id}, likes: ${firstConfession.likesCount}, isLiked: ${firstConfession.isLiked}');
}
```

#### Au chargement depuis l'API
```dart
// Debug: Vérifier les likes_count dans la réponse API
if (response.confessions.isNotEmpty) {
  final firstConfession = response.confessions.first;
  print('🔍 [DEBUG] First API confession - ID: ${firstConfession.id}, likes: ${firstConfession.likesCount}, isLiked: ${firstConfession.isLiked}');
}
```

#### Pendant le toggle like/unlike
```dart
print('🎯 [LIKE] Toggling like for confession $confessionId, current likes: ${confession.likesCount}, isLiked: ${confession.isLiked}');
print('👍 [LIKE] Liking confession $confessionId');
print('✅ [LIKE] Like response: $result');
print('📊 [LIKE] Updated confession likes_count: ${confessions[index].likesCount}');
print('💾 [LIKE] Cache updated after like/unlike');
```

---

## 🧪 Comment Tester

### Test 1: Vérifier les logs initiaux

1. **Lancer l'app Flutter en debug**
2. **Observer les logs** au chargement des confessions :
   ```
   🔍 [DEBUG] First cached confession - ID: 123, likes: 24, isLiked: false
   ```
   ou
   ```
   🔍 [DEBUG] First API confession - ID: 123, likes: 24, isLiked: false
   ```

3. **Vérifier** que `likes` affiche la bonne valeur (pas 0)

### Test 2: Tester le like/unlike

1. **Liker une confession**
2. **Observer les logs** :
   ```
   🎯 [LIKE] Toggling like for confession 123, current likes: 24, isLiked: false
   👍 [LIKE] Liking confession 123
   ✅ [LIKE] Like response: {likes_count: 25, is_liked: true}
   📊 [LIKE] Updated confession likes_count: 25
   💾 [LIKE] Cache updated after like/unlike
   ```

3. **Vérifier** que le compteur passe de 24 à 25
4. **Disliker** et vérifier que ça retombe à 24

### Test 3: Vérifier la persistance du cache

1. **Liker une confession** (le compteur passe à 25)
2. **Fermer complètement l'app** (kill process)
3. **Rouvrir l'app**
4. **Vérifier** que le compteur affiche toujours **25** (et non 24 ou 0)
5. **Observer les logs** :
   ```
   🔍 [DEBUG] First cached confession - ID: 123, likes: 25, isLiked: true
   ```

### Test 4: Vider le cache et recharger

1. **Utiliser la fonctionnalité** de nettoyage du cache (si disponible)
2. **Recharger les confessions**
3. **Vérifier** que les compteurs sont corrects dès le début

---

## 📊 Résumé des Modifications

| Fichier | Lignes | Modification |
|---------|---------|-------------|
| `feeds_controller.dart` | 530-535 | Ajout de la mise à jour du cache après like/unlike |
| `feeds_controller.dart` | 280-284 | Ajout de logs de debug au chargement du cache |
| `feeds_controller.dart` | 314-318 | Ajout de logs de debug au chargement de l'API |
| `feeds_controller.dart` | 470-544 | Ajout de logs détaillés pendant le toggle like |

---

## 🔧 Améliorations Futures (Optionnelles)

### 1. Optimistic Update

Pour une meilleure UX, on pourrait implémenter un **optimistic update** :

```dart
// Mettre à jour immédiatement l'UI (avant la réponse API)
confessions[index] = confessions[index].copyWith(
  isLiked: !confession.isLiked,
  likesCount: confession.isLiked ? confession.likesCount - 1 : confession.likesCount + 1,
);
confessions.refresh();

try {
  // Ensuite faire l'appel API
  final result = await _confessionService.likeConfession(confessionId);

  // Mettre à jour avec la vraie valeur de l'API
  confessions[index] = confessions[index].copyWith(
    likesCount: result['likes_count'] as int,
    isLiked: result['is_liked'] as bool,
  );
} catch (e) {
  // En cas d'erreur, restaurer l'ancienne valeur
  confessions[index] = confession;
}
```

### 2. Invalidation du cache après X temps

Ajouter une logique pour invalider automatiquement le cache des confessions après un certain temps :

```dart
const CACHE_DURATION = Duration(minutes: 15);

bool isCacheExpired() {
  final timestamp = _storage.read<int>(_confessionsTimestampKey);
  if (timestamp == null) return true;

  final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return DateTime.now().difference(cacheTime) > CACHE_DURATION;
}
```

### 3. Synchronisation en arrière-plan

Implémenter une synchronisation périodique en arrière-plan pour mettre à jour les compteurs :

```dart
Timer.periodic(Duration(minutes: 5), (_) {
  _silentRefreshConfessions();
});
```

---

## 🐛 Debugging

### Si le problème persiste

1. **Vérifier les logs** pour identifier à quelle étape `likesCount` est incorrect
2. **Tester avec le cache désactivé** :
   ```dart
   // Commenter temporairement le chargement du cache
   // final cachedConfessions = _cache.getConfessionsCache();
   ```
3. **Vérifier la réponse API directement** :
   ```dart
   print('🔍 [DEBUG] Raw API response: ${response.confessions.first.toJson()}');
   ```
4. **Vérifier le cache persistant** :
   ```dart
   final cachedConfessions = _cache.getConfessionsCache();
   print('🔍 [DEBUG] Cached confessions: ${cachedConfessions?.map((c) => 'ID: ${c.id}, likes: ${c.likesCount}').toList()}');
   ```

### Logs à surveiller

- `🔍 [DEBUG]` : Logs de débogage pour les compteurs
- `💾 [LIKE]` : Confirmation de la mise à jour du cache
- `📊 [LIKE]` : Valeur mise à jour du compteur
- `⚠️ [LIKE]` : Warnings si la confession n'est pas trouvée

---

## 📝 Notes

- Le fix est **rétrocompatible** et ne casse rien
- Les logs de debug peuvent être **supprimés en production** pour optimiser les performances
- La mise à jour du cache après chaque like/unlike a un **léger impact sur les performances** (I/O disk), mais c'est négligeable pour une meilleure cohérence des données

---

**Date**: 2026-03-11
**Version**: 1.0
**Auteur**: Claude Code
