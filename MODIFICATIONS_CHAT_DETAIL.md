# 📝 GUIDE DE MODIFICATION - ChatDetailController & ChatDetailView

## 🎯 ÉTAT ACTUEL

✅ **Backend Laravel** - 100% terminé (7 fichiers)
✅ **Mobile Flutter** - 60% terminé (3/5 fichiers)

### Fichiers Flutter terminés :
1. ✅ `message_cache_service.dart` - Créé
2. ✅ `chat_message_model.dart` - Modifié (editedAt, isEdited, canBeEdited)
3. ✅ `chat_service.dart` - Modifié (updateMessage, deleteMessage, sendTypingIndicator)
4. ✅ `chat_controller.dart` - Modifié (cache intégré)

### Fichiers restants (2) :
5. ⚠️ `chat_detail_controller.dart` - **À MODIFIER MANUELLEMENT**
6. ⚠️ `chat_detail_view.dart` - **À MODIFIER MANUELLEMENT**

---

## 📌 PARTIE 1 : ChatDetailController.dart

**Fichier :** `/Users/macbookpro/Desktop/Developments/Personnals/msgLink/mobile/weylo/lib/app/modules/chat_detail/controllers/chat_detail_controller.dart`

### ÉTAPE 1.1 : Ajouter les imports

**En haut du fichier, ajouter :**
```dart
import 'package:weylo/app/data/services/message_cache_service.dart';
import 'dart:async'; // Pour Timer
```

### ÉTAPE 1.2 : Injecter MessageCacheService

**Chercher la ligne qui ressemble à :**
```dart
final ChatService _chatService = ChatService();
```

**Ajouter juste après :**
```dart
final MessageCacheService _cacheService = MessageCacheService();
```

### ÉTAPE 1.3 : Ajouter les observables pour typing indicator

**Chercher les déclarations de variables observables (lignes avec `.obs`), ajouter :**
```dart
  // Typing indicator
  final showTypingIndicator = false.obs;
  final typingUserName = ''.obs;
  Timer? _typingTimer;
  Timer? _typingDisplayTimer;
  DateTime? _lastTypingEmit;
  static const Duration _typingThrottle = Duration(seconds: 3);
  static const Duration _typingDisplayDuration = Duration(seconds: 3);
```

### ÉTAPE 1.4 : Modifier onClose()

**Chercher la méthode `onClose()`, ajouter AU DÉBUT de la méthode :**
```dart
    // Sauvegarder les messages dans le cache avant de fermer
    if (conversationId != null && messages.isNotEmpty) {
      print('💾 [ChatDetailController] Sauvegarde des messages dans le cache avant fermeture...');
      _cacheService.saveMessagesCache(conversationId!, messages.toList());
    }
```

**Et AVANT le `super.onClose()`, ajouter :**
```dart
    // Nettoyer les timers de typing
    _typingTimer?.cancel();
    _typingDisplayTimer?.cancel();
```

### ÉTAPE 1.5 : Remplacer la méthode loadMessages()

**Chercher `Future<void> loadMessages(` et remplacer TOUTE la méthode par :**

<details>
<summary>Cliquez pour voir le code complet de loadMessages()</summary>

```dart
  /// Charger les messages depuis le cache ou l'API
  Future<void> loadMessages({bool refresh = false}) async {
    print('💬 [ChatDetailController] loadMessages - conversationId: $conversationId, refresh: $refresh');

    if (conversationId == null) {
      print('❌ [ChatDetailController] conversationId is null, aborting');
      return;
    }

    if (refresh) {
      currentPage = 1;
      messages.clear();
      print('🔄 [ChatDetailController] Cleared messages for refresh');
    }

    if (isLoading.value || isLoadingMore.value) {
      print('⚠️ [ChatDetailController] Already loading, skipping...');
      return;
    }

    // NOUVEAU: Tentative de chargement depuis le cache si pas de refresh
    if (!refresh && _cacheService.isMessagesCacheValid(conversationId!)) {
      final cachedMessages = _cacheService.getMessagesCache(conversationId!);
      if (cachedMessages != null && cachedMessages.isNotEmpty) {
        messages.value = cachedMessages;
        currentPage = _cacheService.getMessagesCachedPage(conversationId!);
        print('📦 [ChatDetailController] ✅ Chargé depuis CACHE: ${cachedMessages.length} messages');
        return; // Sortir immédiatement
      }
    }

    // Si pas de cache valide ou refresh demandé: Fetch depuis API
    refresh ? isLoading.value = true : isLoadingMore.value = true;
    hasError.value = false;

    try {
      print('📡 [ChatDetailController] Calling ChatService.getMessages (API)...');
      final response = await _chatService.getMessages(
        conversationId: conversationId!,
        page: currentPage,
        perPage: 50,
      );

      print('✅ [ChatDetailController] Got ${response.messages.length} messages from API');

      if (refresh) {
        messages.value = response.messages.reversed.toList();
      } else {
        messages.insertAll(0, response.messages.reversed.toList());
      }

      currentPage = response.meta.currentPage;
      lastPage = response.meta.lastPage;
      canLoadMore.value = response.meta.hasMorePages;

      // NOUVEAU: Sauvegarder dans le cache après fetch API
      await _cacheService.saveMessagesCache(conversationId!, messages.toList(), page: currentPage);

      print('📊 [ChatDetailController] Total messages in list: ${messages.length}');
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      print('❌ [ChatDetailController] Error loading messages: $e');

      // NOUVEAU: Mode dégradé - Afficher le cache expiré si disponible
      if (!refresh) {
        final expiredCache = _cacheService.getMessagesCacheExpired(conversationId!);
        if (expiredCache != null && expiredCache.isNotEmpty) {
          messages.value = expiredCache;
          print('⚠️ [ChatDetailController] Mode hors ligne: ${expiredCache.length} messages depuis cache expiré');

          Get.snackbar(
            'Mode hors ligne',
            'Affichage des messages en cache',
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
      print('✅ [ChatDetailController] Loading completed');
    }
  }
```
</details>

### ÉTAPE 1.6 : Modifier sendMessage()

**Dans la méthode `sendMessage()`, APRÈS avoir ajouté le message à la liste et AVANT `await _chatService.markAsRead()`, ajouter :**

```dart
      // Invalider le cache après envoi
      await _cacheService.invalidateConversationCache(conversationId!);
      await _cacheService.invalidateAllConversationsCache();
      print('🗑️ [ChatDetailController] Cache invalidé après envoi de message');
```

### ÉTAPE 1.7 : Ajouter les nouvelles méthodes

**À la fin du fichier, AVANT l'accolade finale `}` de la classe, ajouter ces 5 nouvelles méthodes :**

<details>
<summary>Cliquez pour voir les 5 méthodes à ajouter</summary>

```dart
  /// Éditer un message existant
  Future<void> editMessage(ChatMessageModel message, String newContent) async {
    if (conversationId == null) {
      print('❌ Error: conversationId is null');
      return;
    }

    if (newContent.trim().isEmpty) {
      Get.snackbar(
        'Erreur',
        'Le message ne peut pas être vide',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Vérifier si le message peut être édité
    if (!message.canBeEdited(currentUserId!)) {
      Get.snackbar(
        'Erreur',
        'Ce message ne peut plus être modifié (délai de 15 minutes dépassé)',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      print('✏️ [ChatDetailController] Editing message ${message.id}...');

      final updatedMessage = await _chatService.updateMessage(
        conversationId: conversationId!,
        messageId: message.id,
        content: newContent.trim(),
      );

      // Mettre à jour le message dans la liste
      final index = messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        messages[index] = updatedMessage;
        print('✅ [ChatDetailController] Message mis à jour dans la liste');
      }

      // Invalider le cache
      await _cacheService.invalidateConversationCache(conversationId!);
      print('🗑️ [ChatDetailController] Cache invalidé après édition');

      Get.snackbar(
        'Succès',
        'Message modifié',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ [ChatDetailController] Error editing message: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de modifier le message',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Supprimer un message
  Future<void> deleteMessage(ChatMessageModel message) async {
    if (conversationId == null) {
      print('❌ Error: conversationId is null');
      return;
    }

    try {
      print('🗑️ [ChatDetailController] Deleting message ${message.id}...');

      await _chatService.deleteMessage(
        conversationId: conversationId!,
        messageId: message.id,
      );

      // Retirer le message de la liste
      messages.removeWhere((m) => m.id == message.id);
      print('✅ [ChatDetailController] Message supprimé de la liste');

      // Invalider le cache
      await _cacheService.invalidateConversationCache(conversationId!);
      print('🗑️ [ChatDetailController] Cache invalidé après suppression');

      Get.snackbar(
        'Succès',
        'Message supprimé',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ [ChatDetailController] Error deleting message: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le message',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Gérer le changement de texte dans le TextField (typing indicator)
  void onMessageTextChanged(String text) {
    if (conversationId == null) return;

    // Si le texte est vide, ne pas émettre
    if (text.trim().isEmpty) {
      return;
    }

    // Throttle: Émettre seulement si au moins 3 secondes se sont écoulées
    final now = DateTime.now();
    if (_lastTypingEmit != null && now.difference(_lastTypingEmit!) < _typingThrottle) {
      print('⚠️ [ChatDetailController] Typing throttled');
      return;
    }

    // Émettre l'événement de typing
    _emitTypingEvent();
    _lastTypingEmit = now;

    // Reset le timer pour arrêter l'émission après 3s d'inactivité
    _typingTimer?.cancel();
    _typingTimer = Timer(_typingThrottle, () {
      _lastTypingEmit = null;
      print('⏱️ [ChatDetailController] Typing timer reset');
    });
  }

  /// Émettre l'événement de typing vers l'API
  void _emitTypingEvent() async {
    if (conversationId == null) return;

    try {
      print('⌨️ [ChatDetailController] Emitting typing event...');
      await _chatService.sendTypingIndicator(conversationId!);
      print('✅ [ChatDetailController] Typing event sent');
    } catch (e) {
      // Fail silently - typing n'est pas critique
      print('⚠️ [ChatDetailController] Typing event failed (non-critical): $e');
    }
  }

  /// Afficher l'indicateur de typing (appelé par WebSocket - Phase 2)
  /// TODO: Implémenter avec Pusher/Laravel Echo
  void _showTypingIndicator(String username) {
    typingUserName.value = username;
    showTypingIndicator.value = true;

    print('⌨️ [ChatDetailController] Showing typing indicator for $username');

    // Cacher automatiquement après 3 secondes
    _typingDisplayTimer?.cancel();
    _typingDisplayTimer = Timer(_typingDisplayDuration, () {
      showTypingIndicator.value = false;
      print('⏱️ [ChatDetailController] Hiding typing indicator');
    });
  }

  // TODO PHASE 2: WebSocket listener pour typing
  // Décommenter et implémenter avec Pusher/Laravel Echo:
  /*
  void _initializeWebSocket() {
    // S'abonner au canal de la conversation
    final channel = pusher.subscribe('conversation.$conversationId');

    // Écouter l'événement user.typing
    channel.bind('user.typing', (event) {
      final data = json.decode(event.data);
      final username = data['username'];
      _showTypingIndicator(username);
    });
  }
  */
```
</details>

---

## 📌 PARTIE 2 : ChatDetailView.dart

**Fichier :** `/Users/macbookpro/Desktop/Developments/Personnals/msgLink/mobile/weylo/lib/app/modules/chat_detail/views/chat_detail_view.dart`

### ÉTAPE 2.1 : Modifier le TextField pour ajouter onChanged

**Chercher le `TextField` dans `_buildInputArea()` (ligne ~800+), modifier :**

**AVANT :**
```dart
TextField(
  controller: _messageController,
  focusNode: _messageFocusNode,
  style: context.textStyle(FontSizeType.body2),
  maxLines: null,
  decoration: InputDecoration(...),
),
```

**APRÈS :**
```dart
TextField(
  controller: _messageController,
  focusNode: _messageFocusNode,
  style: context.textStyle(FontSizeType.body2),
  maxLines: null,
  onChanged: (text) {
    controller.messageText.value = text;
    controller.onMessageTextChanged(text); // NOUVEAU - Typing indicator
  },
  decoration: InputDecoration(...),
),
```

### ÉTAPE 2.2 : Ajouter le typing indicator widget

**Chercher la partie où sont affichés les messages (ListView.builder), AVANT le Expanded qui contient la liste, ajouter :**

<details>
<summary>Cliquez pour voir le widget typing indicator</summary>

```dart
// NOUVEAU: Typing indicator
Obx(() {
  if (controller.showTypingIndicator.value) {
    return Container(
      padding: EdgeInsets.all(context.elementSpacing),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppThemeSystem.primaryColor,
              ),
            ),
          ),
          SizedBox(width: 8),
          Text(
            '${controller.typingUserName.value} est en train d\'écrire...',
            style: context.textStyle(FontSizeType.caption).copyWith(
              color: AppThemeSystem.primaryColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
  return const SizedBox.shrink();
}),
```
</details>

### ÉTAPE 2.3 : Ajouter long-press sur les messages

**Dans la méthode `_buildMessageBubble()`, envelopper le Container du message avec un GestureDetector :**

**AVANT :**
```dart
return Align(
  alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
  child: Container(
    // ... message bubble
  ),
);
```

**APRÈS :**
```dart
return GestureDetector(
  onLongPress: () {
    if (isSentByMe) {
      _showMessageActions(context, message);
    }
  },
  child: Align(
    alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      // ... message bubble existant
    ),
  ),
);
```

### ÉTAPE 2.4 : Ajouter le badge "(édité)"

**Dans le contenu du message bubble, APRÈS le texte du message et AVANT l'horodatage, ajouter :**

```dart
// NOUVEAU: Badge "édité" si message édité
if (message.isEdited)
  Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      '(édité)',
      style: context.textStyle(FontSizeType.caption).copyWith(
        fontSize: 10,
        fontStyle: FontStyle.italic,
        color: isSentByMe ? Colors.white70 : Colors.grey,
      ),
    ),
  ),
```

### ÉTAPE 2.5 : Ajouter les méthodes pour les dialogues

**À la fin du fichier `_ProfileViewState` (avant l'accolade finale), ajouter :**

<details>
<summary>Cliquez pour voir les 3 méthodes de dialogue</summary>

```dart
  /// Bottom sheet avec actions pour long-press
  void _showMessageActions(BuildContext context, ChatMessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppThemeSystem.darkCardColor
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final canEdit = message.canBeEdited(controller.currentUserId!);

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Modifier (si < 15 min et texte)
              if (canEdit && message.type == ChatMessageType.text)
                ListTile(
                  leading: Icon(Icons.edit, color: AppThemeSystem.primaryColor),
                  title: Text('Modifier'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(context, message);
                  },
                ),

              // Supprimer
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, message);
                },
              ),

              // Répondre (optionnel)
              ListTile(
                leading: Icon(Icons.reply, color: AppThemeSystem.primaryColor),
                title: Text('Répondre'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implémenter réponse
                },
              ),

              // Annuler
              ListTile(
                leading: Icon(Icons.close, color: Colors.grey),
                title: Text('Annuler'),
                onTap: () => Navigator.pop(context),
              ),

              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Dialogue d'édition
  void _showEditDialog(BuildContext context, ChatMessageModel message) {
    final TextEditingController editController = TextEditingController(text: message.content);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppThemeSystem.darkCardColor
              : Colors.white,
          title: Text('Modifier le message'),
          content: TextField(
            controller: editController,
            maxLines: 3,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Nouveau texte...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final newText = editController.text.trim();
                if (newText.isNotEmpty && newText != message.content) {
                  controller.editMessage(message, newText);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeSystem.primaryColor,
              ),
              child: Text('Modifier'),
            ),
          ],
        );
      },
    );
  }

  /// Confirmation de suppression
  void _showDeleteConfirmation(BuildContext context, ChatMessageModel message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppThemeSystem.darkCardColor
              : Colors.white,
          title: Text('Supprimer le message'),
          content: Text('Êtes-vous sûr de vouloir supprimer ce message ? Cette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                controller.deleteMessage(message);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }
```
</details>

---

## ✅ CHECKLIST FINALE

Après avoir fait toutes ces modifications :

### ChatDetailController.dart :
- [ ] Import MessageCacheService et Timer
- [ ] Injection du service
- [ ] Ajout des observables typing
- [ ] Modification de onClose()
- [ ] Remplacement de loadMessages()
- [ ] Modification de sendMessage()
- [ ] Ajout des 5 nouvelles méthodes

### ChatDetailView.dart :
- [ ] TextField.onChanged ajouté
- [ ] Widget typing indicator ajouté
- [ ] GestureDetector long-press ajouté
- [ ] Badge "(édité)" ajouté
- [ ] 3 méthodes de dialogue ajoutées

---

## 🧪 TESTER

```bash
flutter run
```

**Tests à faire :**
1. Ouvrir chat → Vérifier chargement depuis cache (logs 📦)
2. Long-press sur message → Bottom sheet visible
3. Éditer message < 15 min → Badge "(édité)" visible
4. Taper dans TextField → API /typing appelée (logs ⌨️)
5. Mode avion → Cache expiré affiché

---

**Date :** 2026-03-10
**Statut :** Backend ✅ | Mobile 60% → 100% après ces modifications
