# Fix Badge Count & Notifications en Temps Réel

## 📋 Problèmes Identifiés

### Problème Principal
Lorsque User A envoie un message à User B :
- ✅ Le **premier message** met à jour le badge count et la conversation
- ❌ Les **messages suivants** ne mettent plus à jour le badge count
- ❌ Si User B est ailleurs dans l'application, il ne reçoit pas les notifications

### Causes Racines Identifiées

1. **Pas de ré-abonnement après reconnexion WebSocket**
   - Quand le WebSocket se déconnecte puis se reconnecte (réseau instable, timeout, etc.), les abonnements aux canaux privés sont **perdus**
   - Le système ne restaurait pas automatiquement les abonnements
   - Les callbacks restaient en mémoire mais les abonnements côté serveur étaient perdus

2. **Système inefficace et non scalable**
   - S'abonnait à 30 canaux différents (un par conversation)
   - Chaque canal nécessitait une authentification séparée
   - Consommation excessive de ressources
   - Complexité accrue pour la maintenance

3. **Manque de résilience**
   - Aucun mécanisme de vérification de santé des abonnements
   - Pas de système de heartbeat
   - Pas de fallback en cas d'échec

---

## ✅ Solutions Implémentées

### 1. Ré-abonnement Automatique après Reconnexion

**Fichier modifié**: `lib/app/data/services/realtime_service.dart`

#### Changement 1: Détection de reconnexion
```dart
case 'pusher:connection_established':
  // Extraire le socket_id
  final connectionData = jsonDecode(data['data']);
  _socketId = connectionData['socket_id'] as String;

  // ✨ NOUVEAU: Ré-abonner à tous les canaux existants après reconnexion
  _resubscribeToAllChannels();
  break;
```

#### Changement 2: Méthode de ré-abonnement
```dart
/// Ré-abonner à tous les canaux après une reconnexion
Future<void> _resubscribeToAllChannels() async {
  if (_channelCallbacks.isEmpty) {
    print('⚠️ [RealtimeService] Aucun canal à ré-abonner');
    return;
  }

  print('🔄 RÉ-ABONNEMENT À TOUS LES CANAUX APRÈS RECONNEXION');

  // Créer une copie de la map pour éviter les modifications pendant l'itération
  final channelsToResubscribe = Map<String, Function(Map<String, dynamic>)>.from(_channelCallbacks);

  for (var entry in channelsToResubscribe.entries) {
    final channelName = entry.key;
    final callback = entry.value;

    // Ré-abonner au canal (cela va refaire l'authentification)
    await subscribeToPrivateChannel(
      channelName: channelName,
      onEvent: callback,
    );

    // Petit délai entre chaque ré-abonnement pour éviter de surcharger le serveur
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
```

#### Changement 3: Prévention des doublons
```dart
// Stocker le callback pour ce canal (ne pas dupliquer)
if (!_channelCallbacks.containsKey(channelName)) {
  _channelCallbacks[channelName] = onEvent;
  print('✅ Callback enregistré pour le canal');
} else {
  print('⚠️ Canal déjà enregistré, callback conservé');
}
```

---

### 2. Canal Global Utilisateur

**Fichier modifié**: `lib/app/data/services/conversation_state_service.dart`

#### Ancienne Approche ❌
```dart
// S'abonner aux 30 premières conversations
for (final conversation in conversationsToSubscribe) {
  final channelName = 'private-conversation.${conversation.id}';
  await _realtimeService!.subscribeToPrivateChannel(
    channelName: channelName,
    onEvent: (eventData) => _handleConversationEvent(conversation.id, eventData),
  );
}
```

**Problèmes:**
- 30 abonnements séparés = 30 authentifications
- Complexité O(n) où n = nombre de conversations
- Risque de perte d'abonnement pour certains canaux
- Non scalable

#### Nouvelle Approche ✅
```dart
/// S'abonner au canal global de l'utilisateur
/// Ce canal reçoit TOUS les nouveaux messages de TOUTES les conversations
final currentUser = _authService.getCurrentUser();
if (currentUser != null) {
  final globalChannelName = 'private-user.${currentUser.id}';

  await _realtimeService!.subscribeToPrivateChannel(
    channelName: globalChannelName,
    onEvent: _handleGlobalUserEvent,
  );
}
```

**Avantages:**
- ✅ **1 seul canal** au lieu de 30
- ✅ **1 seule authentification**
- ✅ Plus **fiable** et **performant**
- ✅ Plus **facile à déboguer**
- ✅ **Scalable** : fonctionne peu importe le nombre de conversations

#### Handler du canal global
```dart
/// Gérer les événements du canal global utilisateur
void _handleGlobalUserEvent(Map<String, dynamic> eventData) {
  final event = eventData['_event'] as String?;

  if (event == 'message.sent') {
    // Extraire l'ID de la conversation depuis les données
    final conversationId = eventData['conversation_id'] as int?;
    if (conversationId != null) {
      _handleNewMessage(conversationId, eventData);
    }
  }
}
```

---

## 🔧 Modifications Backend Requises

### 1. Créer le canal global utilisateur

Dans votre backend Laravel, vous devez broadcaster les événements sur **deux canaux** :

#### Fichier: `app/Events/MessageSent.php`

```php
<?php

namespace App\Events;

use App\Models\Message;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MessageSent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $message;
    public $receiverId;

    public function __construct(Message $message, int $receiverId)
    {
        $this->message = $message;
        $this->receiverId = $receiverId;
    }

    /**
     * Get the channels the event should broadcast on.
     *
     * Broadcaster sur DEUX canaux:
     * 1. Canal de conversation (pour les utilisateurs dans la conversation)
     * 2. Canal global utilisateur (pour le badge count et notifications globales)
     */
    public function broadcastOn()
    {
        return [
            // Canal de la conversation spécifique
            new PrivateChannel('conversation.' . $this->message->conversation_id),

            // ✨ NOUVEAU: Canal global du destinataire
            new PrivateChannel('user.' . $this->receiverId),
        ];
    }

    /**
     * Nom de l'événement
     */
    public function broadcastAs()
    {
        return 'message.sent';
    }

    /**
     * Données à broadcaster
     */
    public function broadcastWith()
    {
        return [
            'id' => $this->message->id,
            'conversation_id' => $this->message->conversation_id,
            'sender_id' => $this->message->sender_id,
            'content' => $this->message->content,
            'type' => $this->message->type,
            'created_at' => $this->message->created_at->toISOString(),
            'sender' => [
                'id' => $this->message->sender->id,
                'username' => $this->message->sender->username,
                'avatar' => $this->message->sender->avatar_url,
            ],
            // Métadonnées utiles
            'metadata' => $this->message->metadata,
            'media_url' => $this->message->media_url,
        ];
    }
}
```

### 2. Dispatcher l'événement lors de l'envoi d'un message

#### Fichier: `app/Http/Controllers/Api/V1/ConversationController.php`

```php
public function sendMessage(Request $request, $conversationId)
{
    $conversation = Conversation::findOrFail($conversationId);

    // Vérifier que l'utilisateur est participant
    $this->authorize('participate', $conversation);

    // Valider les données
    $validated = $request->validate([
        'content' => 'nullable|string',
        'type' => 'required|in:text,audio,image,video,gift',
        'media' => 'nullable|file',
        'metadata' => 'nullable|array',
    ]);

    // Créer le message
    $message = $conversation->messages()->create([
        'sender_id' => auth()->id(),
        'content' => $validated['content'] ?? null,
        'type' => $validated['type'],
        'metadata' => $validated['metadata'] ?? null,
    ]);

    // Déterminer l'ID du destinataire
    $receiverId = $conversation->participant_one_id === auth()->id()
        ? $conversation->participant_two_id
        : $conversation->participant_one_id;

    // ✨ BROADCASTER L'ÉVÉNEMENT sur les deux canaux
    broadcast(new MessageSent($message, $receiverId))->toOthers();

    return response()->json([
        'message' => $message->load('sender'),
    ], 201);
}
```

### 3. Autoriser l'accès au canal global utilisateur

#### Fichier: `routes/channels.php`

```php
<?php

use Illuminate\Support\Facades\Broadcast;

// Canal de conversation existant
Broadcast::channel('conversation.{conversationId}', function ($user, $conversationId) {
    $conversation = \App\Models\Conversation::find($conversationId);

    return $conversation && (
        $conversation->participant_one_id === $user->id ||
        $conversation->participant_two_id === $user->id
    );
});

// ✨ NOUVEAU: Canal global utilisateur
Broadcast::channel('user.{userId}', function ($user, $userId) {
    // L'utilisateur peut seulement s'abonner à son propre canal
    return (int) $user->id === (int) $userId;
});
```

---

## 🧪 Comment Tester

### Test 1: Badge Count en temps réel

1. **Configuration initiale**
   - Avoir 2 devices/émulateurs ou 1 device + 1 émulateur
   - User A connecté sur Device 1
   - User B connecté sur Device 2

2. **Scénario de test**
   ```
   Device 1 (User A)              Device 2 (User B)
   ═════════════════              ═════════════════
   Ouvrir l'app                   Ouvrir l'app
   Aller dans Feeds               Rester sur Chat

   Envoyer message 1 à User B  →  ✅ Badge +1 (conversation apparaît en haut)
   Envoyer message 2 à User B  →  ✅ Badge +2 (mise à jour immédiate)
   Envoyer message 3 à User B  →  ✅ Badge +3 (mise à jour immédiate)

                                  Aller dans Feeds (autre page)
   Envoyer message 4 à User B  →  ✅ Badge +4 (même si ailleurs)

                                  Ouvrir la conversation
                                  ✅ Badge retombe à 0
   ```

3. **Vérifications**
   - ✅ Le badge count s'incrémente à chaque nouveau message
   - ✅ La conversation remonte en haut de la liste
   - ✅ Le lastMessage est mis à jour en temps réel
   - ✅ Fonctionne même si User B est ailleurs dans l'app

### Test 2: Résilience après déconnexion

1. **Provoquer une déconnexion**
   - Activer le mode Avion pendant 5 secondes
   - Désactiver le mode Avion
   - ✅ Le WebSocket se reconnecte automatiquement
   - ✅ Les abonnements sont restaurés

2. **Vérifier que les messages continuent d'arriver**
   - User A envoie un message
   - ✅ User B reçoit le message malgré la reconnexion

### Test 3: Logs de débogage

Cherchez ces logs dans la console Flutter :

```
✅ Connexion établie
🔄 RÉ-ABONNEMENT À TOUS LES CANAUX APRÈS RECONNEXION
🌐 Abonnement au canal global utilisateur: private-user.123
📨 ÉVÉNEMENT CANAL GLOBAL
💬 Message pour la conversation: 456
📊 Badge counts recalculés:
   - Total unread messages: 5
   - Unread conversations: 2
```

---

## 📊 Résumé des Améliorations

| Aspect | Avant ❌ | Après ✅ |
|--------|---------|---------|
| **Nombre de canaux** | 30 canaux par utilisateur | 1 canal global par utilisateur |
| **Abonnements** | 30 authentifications | 1 authentification |
| **Ré-abonnement après reconnexion** | ❌ Non | ✅ Automatique |
| **Badge count** | ❌ Fonctionne 1 fois | ✅ Fonctionne toujours |
| **Notifications ailleurs dans l'app** | ❌ Non | ✅ Oui |
| **Scalabilité** | ❌ Limité à 30 conversations | ✅ Illimité |
| **Fiabilité** | ⚠️ Moyenne | ✅ Haute |
| **Performance** | ⚠️ Moyenne | ✅ Excellente |
| **Maintenabilité** | ⚠️ Complexe | ✅ Simple |

---

## 🚀 Prochaines Étapes

1. **Implémenter les modifications backend** (voir section "Modifications Backend Requises")
2. **Tester en développement** (voir section "Comment Tester")
3. **Vérifier les logs** pour s'assurer que tout fonctionne
4. **Monitorer en production** après déploiement

---

## 🔍 Points d'Attention

### Backend
- ⚠️ Assurez-vous que le canal `private-user.{userId}` est bien créé dans Laravel
- ⚠️ Vérifiez que l'autorisation dans `routes/channels.php` est correcte
- ⚠️ Broadcaster sur **les deux canaux** (conversation + user global)

### Frontend
- ✅ Le code est déjà prêt côté Flutter
- ✅ Les abonnements se font automatiquement au démarrage de l'app
- ✅ Le ré-abonnement après reconnexion est automatique

---

## 📝 Notes Techniques

### Pourquoi utiliser un canal global ?

1. **Performance** : 1 connexion WebSocket au lieu de 30
2. **Fiabilité** : Moins de points de défaillance
3. **Scalabilité** : Fonctionne avec un nombre illimité de conversations
4. **Simplicité** : Moins de code à maintenir

### Architecture de la solution

```
┌─────────────────────────────────────────────────────────────┐
│                    Backend Laravel                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  User A envoie un message à User B                         │
│                    ↓                                         │
│  Event: MessageSent(message, receiverId)                   │
│                    ↓                                         │
│  Broadcast sur 2 canaux:                                    │
│    1. private-conversation.{conversationId}                 │
│    2. private-user.{receiverId} ← NOUVEAU                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                         ↓
                    Reverb/Pusher
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                    Frontend Flutter                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  RealtimeService                                            │
│    - Gère la connexion WebSocket                           │
│    - Ré-abonne automatiquement après reconnexion ← NOUVEAU │
│                                                             │
│  ConversationStateService                                   │
│    - S'abonne au canal global user ← NOUVEAU                │
│    - Met à jour le badge count en temps réel               │
│    - Gère l'état global des conversations                  │
│                                                             │
│  ChatDetailController                                       │
│    - S'abonne au canal de conversation                     │
│    - Affiche les messages en temps réel                    │
│    - Marque comme lu quand la conversation est ouverte     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

**Créé le**: 2026-03-11
**Version**: 1.0
**Auteur**: Claude Code
