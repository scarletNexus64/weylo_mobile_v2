# 🔌 Guide de Test WebSocket - Messages en Temps Réel

## 📋 Étapes de Test

### 1️⃣ Lancer le serveur Laravel Reverb

Dans le terminal backend :
```bash
cd /Users/macbookpro/Desktop/Developments/Personnals/msgLink/MSG-Link-Back
php artisan reverb:start
```

**Vous devriez voir :**
```
INFO  Starting server on 0.0.0.0:8080.
```

---

### 2️⃣ Lancer l'application Flutter

```bash
cd /Users/macbookpro/Desktop/Developments/Personnals/msgLink/mobile/weylo
flutter run
```

---

### 3️⃣ Logs à surveiller au démarrage

Après le login, sur l'écran Home, **vous devriez voir ces logs dans l'ordre** :

#### **A. Initialisation depuis HomeController**
```
╔═══════════════════════════════════════════════════════════╗
║ 🔌 INITIALISATION WEBSOCKET DEPUIS HOME CONTROLLER
╚═══════════════════════════════════════════════════════════╝
📝 RealtimeService n'est pas encore enregistré, création...
✅ RealtimeService créé et enregistré dans GetX
⏳ La connexion WebSocket démarre automatiquement...
╚═══════════════════════════════════════════════════════════╝
```

#### **B. Connexion au serveur Reverb**
```
═══════════════════════════════════════════════════════════
🚀 [RealtimeService] DÉMARRAGE CONNEXION WEBSOCKET
═══════════════════════════════════════════════════════════
📍 Host: 192.168.1.185
📍 Port: 8080
🔑 App Key: 1425cdd3ef7425fa6746d2895a233e52
🔑 App ID: Weylo-app
🌐 WebSocket URL: ws://192.168.1.185:8080/app/1425cdd3ef7425fa6746d2895a233e52?protocol=7&client=js&version=8.4.0-rc2&flash=false
⏳ Tentative de connexion...
✅ [RealtimeService] Stream listener configuré
✅ [RealtimeService] Connexion établie - En attente du message pusher:connection_established
═══════════════════════════════════════════════════════════
```

#### **C. Confirmation de connexion du serveur**
```
┌─────────────────────────────────────────────────────────┐
│ 📨 MESSAGE REÇU DU SERVEUR
└─────────────────────────────────────────────────────────┘
Message brut: {"event":"pusher:connection_established","data":"{\"socket_id\":\"123.456\",\"activity_timeout\":120}"}
Type: String
🎯 Event: pusher:connection_established
📺 Channel: null
📦 Data: {"socket_id":"123.456","activity_timeout":120}

🎉🎉🎉 CONNEXION WEBSOCKET ÉTABLIE AVEC SUCCÈS! 🎉🎉🎉

🔑 Socket ID reçu: 123.456
✅ WebSocket est maintenant prêt à recevoir des événements

└─────────────────────────────────────────────────────────┘
```

---

### 4️⃣ Ouvrir une conversation

Naviguez vers l'onglet **Chat** > Ouvrez une conversation

**Vous devriez voir :**
```
🔌 [ChatDetailController] Initializing WebSocket for conversation 5

╔═══════════════════════════════════════════════════════════╗
║ 🔔 ABONNEMENT À UN CANAL
╚═══════════════════════════════════════════════════════════╝
📺 Canal: private-conversation.5
🔌 État connexion: CONNECTÉ
🔑 Token trouvé: eyJ0eXAiOiJKV1QiLCJ...
📤 Message d'abonnement:
{"event":"pusher:subscribe","data":{"channel":"private-conversation.5","auth":""}}
✅ Callback enregistré pour le canal
📋 Total canaux actifs: 1
✅ Message d'abonnement envoyé au serveur
⏳ En attente de la confirmation d'abonnement...
╚═══════════════════════════════════════════════════════════╝
```

---

### 5️⃣ Tester la réception de messages

#### **Option 1: Depuis un autre téléphone/compte**
1. Connectez-vous avec un autre compte
2. Ouvrez la même conversation
3. Envoyez un message

#### **Option 2: Test manuel avec Postman**
```http
POST http://192.168.1.185:8001/api/v1/chat/conversations/{conversation_id}/messages
Authorization: Bearer {token}
Content-Type: application/json

{
  "content": "Message de test",
  "type": "text"
}
```

**Logs attendus sur le téléphone qui écoute :**
```
┌─────────────────────────────────────────────────────────┐
│ 📨 MESSAGE REÇU DU SERVEUR
└─────────────────────────────────────────────────────────┘
Message brut: {"event":"message.sent","channel":"private-conversation.5","data":{...}}
Type: String
🎯 Event: message.sent
📺 Channel: private-conversation.5
📦 Data: {...}

🔔 ÉVÉNEMENT CUSTOM REÇU: message.sent
Canal: private-conversation.5
✅ Callback trouvé pour ce canal
📦 Data déjà en Map
📋 Contenu du message:
   - id: 123
   - conversation_id: 5
   - sender_id: 2
   - content: Message de test
   - type: text
   - created_at: 2025-03-10T12:00:00Z
🚀 Appel du callback...

📨 [ChatDetailController] New message received from WebSocket
📨 [ChatDetailController] Event data: {...}
📨 [ChatDetailController] Event name: message.sent
✅ [ChatDetailController] New message added to list

✅ Callback exécuté avec succès
└─────────────────────────────────────────────────────────┘
```

**Le message devrait apparaître instantanément dans l'UI ! 🎉**

---

## ❌ Problèmes possibles et solutions

### Problème 1: Pas de connexion WebSocket
**Logs:**
```
❌❌❌ [RealtimeService] ERREUR DE CONNEXION ❌❌❌
```

**Solutions:**
- Vérifiez que Reverb tourne : `php artisan reverb:start`
- Vérifiez l'IP : `192.168.1.185` est-elle correcte ?
- Vérifiez le port : `8080` est-il ouvert ?
- Essayez avec `localhost` si en émulateur Android : changez en `10.0.2.2`

---

### Problème 2: Connexion établie mais pas de socket_id
**Logs:**
```
✅ [RealtimeService] Connexion établie
(mais pas de message pusher:connection_established)
```

**Solutions:**
- Vérifiez que le serveur Reverb répond
- Vérifiez la configuration dans `.env` du backend
- Redémarrez Reverb : `Ctrl+C` puis `php artisan reverb:start`

---

### Problème 3: Abonnement échoue (pour canaux privés)
**Logs:**
```
❌❌❌ ERREUR PUSHER ❌❌❌
Erreur: {"code":4009,"message":"Connection not authorized"}
```

**Solutions:**
- **TEMPORAIRE:** Changez le canal en public dans `ChatDetailController.dart` ligne 1134:
  ```dart
  // AVANT
  channelName: 'private-conversation.$conversationId',

  // APRÈS (test uniquement)
  channelName: 'conversation.$conversationId',
  ```

- **PERMANENT:** Implémentez l'authentification dans `RealtimeService` ligne 175-178

---

### Problème 4: Messages pas reçus en temps réel
**Checklist:**
- [ ] Reverb tourne sur le backend
- [ ] Logs de connexion OK (`🎉 CONNEXION WEBSOCKET ÉTABLIE`)
- [ ] Logs d'abonnement OK (`✅✅✅ ABONNEMENT RÉUSSI`)
- [ ] Backend envoie bien l'événement (vérifier logs Laravel)
- [ ] L'événement est `message.sent` (pas autre chose)
- [ ] Le canal correspond : `private-conversation.{id}`

---

## 🔍 Commandes de débogage utiles

### Voir les logs Laravel en temps réel
```bash
cd /Users/macbookpro/Desktop/Developments/Personnals/msgLink/MSG-Link-Back
tail -f storage/logs/laravel.log
```

### Voir tous les logs Flutter filtrés
```bash
flutter run | grep -E "RealtimeService|ChatDetailController|MESSAGE"
```

### Tester manuellement WebSocket avec wscat
```bash
npm install -g wscat
wscat -c "ws://192.168.1.185:8080/app/1425cdd3ef7425fa6746d2895a233e52?protocol=7&client=js&version=8.4.0-rc2"
```

---

## ✅ Checklist finale

- [ ] Backend Laravel tourne
- [ ] Reverb tourne (`php artisan reverb:start`)
- [ ] App Flutter lancée
- [ ] Logs de connexion WebSocket visibles
- [ ] Socket ID reçu (`🔑 Socket ID reçu: ...`)
- [ ] Conversation ouverte
- [ ] Abonnement au canal réussi
- [ ] Message de test envoyé
- [ ] Message reçu en temps réel ! 🎉

---

## 📝 Notes

- Les logs sont **très verbeux** pour le debug - vous pouvez les réduire plus tard
- La connexion WebSocket se maintient même si vous changez d'écran
- Si vous fermez la conversation, elle se désabonne du canal
- Si vous fermez l'app, la connexion se ferme automatiquement

**Bon test ! 🚀**
