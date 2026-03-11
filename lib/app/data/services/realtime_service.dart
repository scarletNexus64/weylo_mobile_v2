import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'auth_service.dart';

/// Service pour gérer la connexion WebSocket en temps réel avec Laravel Reverb
class RealtimeService extends GetxService {
  static RealtimeService get to => Get.find();

  final _authService = AuthService();

  // WebSocket connection
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  // État de la connexion
  final isConnected = false.obs;
  final connectionState = 'disconnected'.obs;

  // Socket ID reçu du serveur (nécessaire pour l'auth)
  String? _socketId;

  // Map pour stocker les callbacks des canaux
  final Map<String, Function(Map<String, dynamic>)> _channelCallbacks = {};

  // Configuration Reverb
  static const String wsHost = '192.168.1.185';
  static const int wsPort = 8080;
  static const String appKey = '1425cdd3ef7425fa6746d2895a233e52';
  static const String appId = 'Weylo-app';

  @override
  Future<void> onInit() async {
    super.onInit();
    await connect();
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }

  /// Se connecter au serveur WebSocket Reverb
  Future<void> connect() async {
    try {
      if (isConnected.value) {
        print('⚠️ [RealtimeService] Already connected');
        return;
      }

      connectionState.value = 'connecting';
      print('');
      print('═══════════════════════════════════════════════════════════');
      print('🚀 [RealtimeService] DÉMARRAGE CONNEXION WEBSOCKET');
      print('═══════════════════════════════════════════════════════════');
      print('📍 Host: $wsHost');
      print('📍 Port: $wsPort');
      print('🔑 App Key: $appKey');
      print('🔑 App ID: $appId');

      // Créer la connexion WebSocket avec Reverb
      final wsUrl = Uri.parse('ws://$wsHost:$wsPort/app/$appKey?protocol=7&client=js&version=8.4.0-rc2&flash=false');
      print('🌐 WebSocket URL: $wsUrl');
      print('⏳ Tentative de connexion...');

      _channel = WebSocketChannel.connect(wsUrl);

      // Écouter les messages du serveur
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: false,
      );

      isConnected.value = true;
      connectionState.value = 'connected';
      print('✅ [RealtimeService] Stream listener configuré');
      print('✅ [RealtimeService] Connexion établie - En attente du message pusher:connection_established');
      print('═══════════════════════════════════════════════════════════');
      print('');

      // Une fois connecté, s'authentifier si nécessaire
    } catch (e) {
      print('');
      print('❌❌❌ [RealtimeService] ERREUR DE CONNEXION ❌❌❌');
      print('Erreur: $e');
      print('Type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');
      print('═══════════════════════════════════════════════════════════');
      print('');
      connectionState.value = 'error';
      isConnected.value = false;

      // Réessayer après 5 secondes
      print('⏰ Nouvelle tentative dans 5 secondes...');
      Future.delayed(const Duration(seconds: 5), () {
        if (!isConnected.value) {
          print('🔄 Reconnexion automatique...');
          connect();
        }
      });
    }
  }

  /// Se déconnecter
  Future<void> disconnect() async {
    try {
      connectionState.value = 'disconnecting';

      await _subscription?.cancel();
      await _channel?.sink.close(status.goingAway);

      _channelCallbacks.clear();

      isConnected.value = false;
      connectionState.value = 'disconnected';
      print('🔌 [RealtimeService] Disconnected from Reverb');
    } catch (e) {
      print('❌ [RealtimeService] Disconnect error: $e');
    }
  }

  /// S'abonner à un canal privé
  Future<void> subscribeToPrivateChannel({
    required String channelName,
    required Function(Map<String, dynamic>) onEvent,
  }) async {
    print('');
    print('╔═══════════════════════════════════════════════════════════╗');
    print('║ 🔔 ABONNEMENT À UN CANAL');
    print('╚═══════════════════════════════════════════════════════════╝');
    print('📺 Canal: $channelName');
    print('🔌 État connexion: ${isConnected.value ? "CONNECTÉ" : "DÉCONNECTÉ"}');

    if (!isConnected.value) {
      print('⚠️ Pas encore connecté, connexion en cours...');
      await connect();
      // Attendre un peu que la connexion soit établie
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Attendre d'avoir le socket_id
    int retries = 0;
    while (_socketId == null && retries < 10) {
      print('⏳ En attente du Socket ID... (tentative ${retries + 1}/10)');
      await Future.delayed(const Duration(milliseconds: 100));
      retries++;
    }

    if (_socketId == null) {
      print('❌ ERREUR: Socket ID non reçu après 1 seconde');
      print('Impossible de s\'abonner sans Socket ID');
      return;
    }

    try {
      final token = _authService.getToken();
      if (token == null) {
        print('❌ ERREUR: Aucun token d\'authentification trouvé');
        print('Impossible de s\'abonner aux canaux privés sans token');
        return;
      }

      print('🔑 Token trouvé: ${token.substring(0, 20)}...');
      print('🔑 Socket ID disponible: $_socketId');

      // Obtenir la signature d'authentification du backend
      print('');
      print('🔐 Demande d\'authentification au serveur Laravel...');
      final authSignature = await _authenticateChannel(
        channelName: channelName,
        socketId: _socketId!,
        token: token,
      );

      if (authSignature == null) {
        print('❌ ERREUR: Impossible d\'obtenir la signature d\'authentification');
        return;
      }

      print('✅ Signature d\'authentification reçue');

      // Construire le message d'abonnement avec l'auth
      final subscribeMessage = {
        'event': 'pusher:subscribe',
        'data': {
          'channel': channelName,
          'auth': authSignature,
        },
      };

      print('📤 Message d\'abonnement avec authentification:');
      print(jsonEncode(subscribeMessage));

      // Stocker le callback pour ce canal (ne pas dupliquer)
      if (!_channelCallbacks.containsKey(channelName)) {
        _channelCallbacks[channelName] = onEvent;
        print('✅ Callback enregistré pour le canal');
      } else {
        print('⚠️ Canal déjà enregistré, callback conservé');
      }
      print('📋 Total canaux actifs: ${_channelCallbacks.length}');

      // Envoyer le message d'abonnement
      _channel?.sink.add(jsonEncode(subscribeMessage));

      print('✅ Message d\'abonnement envoyé au serveur');
      print('⏳ En attente de la confirmation d\'abonnement...');
      print('╚═══════════════════════════════════════════════════════════╝');
      print('');
    } catch (e) {
      print('');
      print('❌❌❌ ERREUR LORS DE L\'ABONNEMENT ❌❌❌');
      print('Erreur: $e');
      print('Canal: $channelName');
      print('Stack trace: ${StackTrace.current}');
      print('═══════════════════════════════════════════════════════════');
      print('');
    }
  }

  /// Authentifier un canal privé auprès du backend Laravel
  Future<String?> _authenticateChannel({
    required String channelName,
    required String socketId,
    required String token,
  }) async {
    try {
      print('🔐 Authentication - Canal: $channelName');
      print('🔐 Authentication - Socket ID: $socketId');

      final authUrl = Uri.parse('http://$wsHost:8001/api/v1/broadcasting/auth');
      print('🔐 Auth URL: $authUrl');

      final response = await http.post(
        authUrl,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'socket_id': socketId,
          'channel_name': channelName,
        },
      );

      print('🔐 Auth response status: ${response.statusCode}');
      print('🔐 Auth response body: ${response.body}');

      if (response.statusCode == 200) {
        final authData = jsonDecode(response.body);
        final auth = authData['auth'] as String;
        print('✅ Auth signature obtenue: ${auth.substring(0, 20)}...');
        return auth;
      } else {
        print('❌ Auth failed with status ${response.statusCode}');
        print('❌ Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception during authentication: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Se désabonner d'un canal
  Future<void> unsubscribeFromChannel(String channelName) async {
    try {
      print('🔕 [RealtimeService] Unsubscribing from $channelName');

      final unsubscribeMessage = jsonEncode({
        'event': 'pusher:unsubscribe',
        'data': {
          'channel': channelName,
        },
      });

      _channel?.sink.add(unsubscribeMessage);
      _channelCallbacks.remove(channelName);

      print('✅ [RealtimeService] Unsubscribed from $channelName');
    } catch (e) {
      print('❌ [RealtimeService] Unsubscribe error: $e');
    }
  }

  /// Gérer les messages reçus du serveur
  void _handleMessage(dynamic message) {
    try {
      print('');
      print('┌─────────────────────────────────────────────────────────┐');
      print('│ 📨 MESSAGE REÇU DU SERVEUR');
      print('└─────────────────────────────────────────────────────────┘');
      print('Message brut: $message');
      print('Type: ${message.runtimeType}');

      final data = jsonDecode(message as String);
      final event = data['event'] as String?;
      final channelName = data['channel'] as String?;

      print('🎯 Event: $event');
      print('📺 Channel: $channelName');
      print('📦 Data: ${data['data']}');

      switch (event) {
        case 'pusher:connection_established':
          print('');
          print('🎉🎉🎉 CONNEXION WEBSOCKET ÉTABLIE AVEC SUCCÈS! 🎉🎉🎉');
          print('');
          // Extraire le socket_id
          final connectionData = jsonDecode(data['data']);
          _socketId = connectionData['socket_id'] as String;
          print('🔑 Socket ID reçu et stocké: $_socketId');
          print('✅ WebSocket est maintenant prêt à recevoir des événements');
          print('✅ Authentification des canaux privés activée');
          print('');

          // IMPORTANT: Ré-abonner à tous les canaux existants après reconnexion
          _resubscribeToAllChannels();
          break;

        case 'pusher_internal:subscription_succeeded':
          print('');
          print('✅✅✅ ABONNEMENT RÉUSSI AU CANAL: $channelName');
          print('Vous allez maintenant recevoir les événements de ce canal');
          print('');
          break;

        case 'pusher:error':
          print('');
          print('❌❌❌ ERREUR PUSHER ❌❌❌');
          print('Erreur: ${data['data']}');
          print('');
          break;

        default:
          // C'est un événement custom (ex: message.sent)
          print('');
          print('🔔 ÉVÉNEMENT CUSTOM REÇU: $event');
          print('Canal: $channelName');

          if (channelName != null && _channelCallbacks.containsKey(channelName)) {
            print('✅ Callback trouvé pour ce canal');

            final eventData = data['data'];
            Map<String, dynamic> parsedData;

            if (eventData is String) {
              parsedData = jsonDecode(eventData);
              print('📦 Data parsée depuis JSON string');
            } else {
              parsedData = eventData as Map<String, dynamic>;
              print('📦 Data déjà en Map');
            }

            print('📋 Contenu du message:');
            parsedData.forEach((key, value) {
              print('   - $key: $value');
            });

            // Ajouter le nom de l'événement aux données
            parsedData['_event'] = event;

            print('🚀 Appel du callback...');
            // Appeler le callback du canal
            _channelCallbacks[channelName]!(parsedData);
            print('✅ Callback exécuté avec succès');
          } else {
            print('⚠️ Aucun callback enregistré pour le canal: $channelName');
            print('Canaux enregistrés: ${_channelCallbacks.keys.toList()}');
          }
          print('');
      }

      print('└─────────────────────────────────────────────────────────┘');
      print('');
    } catch (e) {
      print('');
      print('❌❌❌ ERREUR LORS DU TRAITEMENT DU MESSAGE ❌❌❌');
      print('Erreur: $e');
      print('Type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');
      print('Message original: $message');
      print('═══════════════════════════════════════════════════════════');
      print('');
    }
  }

  /// Gérer les erreurs
  void _handleError(dynamic error) {
    print('');
    print('╔═══════════════════════════════════════════════════════════╗');
    print('║ ❌ ERREUR WEBSOCKET');
    print('╚═══════════════════════════════════════════════════════════╝');
    print('Erreur: $error');
    print('Type: ${error.runtimeType}');
    isConnected.value = false;
    connectionState.value = 'error';
    print('État: ERREUR');
    print('');
    print('⏰ Reconnexion dans 5 secondes...');
    print('═══════════════════════════════════════════════════════════');
    print('');

    // Réessayer la connexion après 5 secondes
    Future.delayed(const Duration(seconds: 5), () {
      if (!isConnected.value) {
        print('🔄 Tentative de reconnexion...');
        connect();
      }
    });
  }

  /// Gérer la fermeture de la connexion
  void _handleDone() {
    print('');
    print('╔═══════════════════════════════════════════════════════════╗');
    print('║ 🔌 CONNEXION WEBSOCKET FERMÉE');
    print('╚═══════════════════════════════════════════════════════════╝');
    isConnected.value = false;
    connectionState.value = 'disconnected';
    print('État: DÉCONNECTÉ');
    print('');
    print('⏰ Reconnexion dans 3 secondes...');
    print('═══════════════════════════════════════════════════════════');
    print('');

    // Réessayer la connexion après 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      if (!isConnected.value) {
        print('🔄 Tentative de reconnexion automatique...');
        connect();
      }
    });
  }


  /// Ré-abonner à tous les canaux après une reconnexion
  Future<void> _resubscribeToAllChannels() async {
    if (_channelCallbacks.isEmpty) {
      print('⚠️ [RealtimeService] Aucun canal à ré-abonner');
      return;
    }

    print('');
    print('╔═══════════════════════════════════════════════════════════╗');
    print('║ 🔄 RÉ-ABONNEMENT À TOUS LES CANAUX APRÈS RECONNEXION');
    print('╚═══════════════════════════════════════════════════════════╝');
    print('📋 Nombre de canaux à ré-abonner: ${_channelCallbacks.length}');
    print('');

    // Créer une copie de la map pour éviter les modifications pendant l'itération
    final channelsToResubscribe = Map<String, Function(Map<String, dynamic>)>.from(_channelCallbacks);

    for (var entry in channelsToResubscribe.entries) {
      final channelName = entry.key;
      final callback = entry.value;

      print('🔄 [RealtimeService] Ré-abonnement au canal: $channelName');

      // Ré-abonner au canal (cela va refaire l'authentification)
      await subscribeToPrivateChannel(
        channelName: channelName,
        onEvent: callback,
      );

      // Petit délai entre chaque ré-abonnement pour éviter de surcharger le serveur
      await Future.delayed(const Duration(milliseconds: 100));
    }

    print('');
    print('✅✅✅ RÉ-ABONNEMENT TERMINÉ AVEC SUCCÈS');
    print('📊 Total canaux ré-abonnés: ${_channelCallbacks.length}');
    print('╚═══════════════════════════════════════════════════════════╝');
    print('');
  }

  /// Obtenir l'état de connexion sous forme lisible
  String get connectionStateText {
    switch (connectionState.value) {
      case 'connecting':
        return 'Connexion en cours...';
      case 'connected':
        return 'Connecté';
      case 'disconnecting':
        return 'Déconnexion en cours...';
      case 'disconnected':
        return 'Déconnecté';
      case 'error':
        return 'Erreur de connexion';
      default:
        return 'Inconnu';
    }
  }
}
