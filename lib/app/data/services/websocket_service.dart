import 'dart:async';
import 'dart:convert';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../core/api_config.dart';

class WebSocketService extends GetxService {
  static WebSocketService get to => Get.find();

  late PusherChannelsFlutter pusher;
  final _authService = AuthService();

  // État de la connexion
  final isConnected = false.obs;
  final connectionState = 'disconnected'.obs;

  // Map pour stocker les channels actifs
  final Map<String, dynamic> _activeChannels = {};

  // Configuration - Utilise les paramètres depuis ApiConfig
  static String get wsHost => ApiConfig.wsHost;
  static int get wsPort => ApiConfig.wsPort;
  static String get authEndpoint => '${ApiConfig.baseUrl.replaceAll('/api/v1', '')}/broadcasting/auth';
  static String get appId => ApiConfig.wsAppId;
  static String get appKey => ApiConfig.wsAppKey;
  static bool get useTLS => ApiConfig.forceTLS;
  static const String cluster = 'mt1'; // Cluster par défaut

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializePusher();
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }

  /// Initialiser Pusher/Reverb
  Future<void> _initializePusher() async {
    try {
      pusher = PusherChannelsFlutter.getInstance();

      // Récupérer le token d'authentification
      final user = _authService.getCurrentUser();
      final token = _authService.getToken();

      await pusher.init(
        apiKey: appKey,
        cluster: cluster,
        onConnectionStateChange: _onConnectionStateChange,
        onError: _onError,
        onSubscriptionSucceeded: _onSubscriptionSucceeded,
        onEvent: _onEvent,
        onSubscriptionError: _onSubscriptionError,
        onDecryptionFailure: _onDecryptionFailure,
        onMemberAdded: _onMemberAdded,
        onMemberRemoved: _onMemberRemoved,
        // Configuration pour Reverb (Laravel)
        useTLS: useTLS, // Active TLS en production
        activityTimeout: 120000, // 2 minutes
        pongTimeout: 30000, // 30 secondes
        // Configuration de l'authentification pour les canaux privés
        onAuthorizer: (channelName, socketId, options) async {
          print('🔐 [WebSocketService] Authorizing channel: $channelName');
          print('🔐 [WebSocketService] Socket ID: $socketId');

          // Construire la requête d'authentification vers Laravel
          final authUrl = Uri.parse(authEndpoint);

          try {
            final response = await http.post(
              authUrl,
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
              body: {'socket_id': socketId, 'channel_name': channelName},
            );

            print(
              '🔐 [WebSocketService] Auth response status: ${response.statusCode}',
            );
            print('🔐 [WebSocketService] Auth response body: ${response.body}');

            if (response.statusCode == 200) {
              final authData = jsonDecode(response.body);
              return authData;
            } else {
              throw Exception('Auth failed: ${response.statusCode}');
            }
          } catch (e) {
            print('❌ [WebSocketService] Auth error: $e');
            rethrow;
          }
        },
      );

      // Configuration custom pour Reverb
      await pusher.connect();

      print('✅ [WebSocketService] Pusher initialized and connecting...');
    } catch (e) {
      print('❌ [WebSocketService] Error initializing Pusher: $e');
    }
  }

  /// Se connecter à WebSocket
  Future<void> connect() async {
    try {
      if (isConnected.value) {
        print('⚠️ [WebSocketService] Already connected');
        return;
      }

      await pusher.connect();
      print('🔌 [WebSocketService] Connecting to Reverb...');
    } catch (e) {
      print('❌ [WebSocketService] Error connecting: $e');
    }
  }

  /// Se déconnecter
  Future<void> disconnect() async {
    try {
      // Unsubscribe de tous les channels
      for (var channelName in _activeChannels.keys) {
        await pusher.unsubscribe(channelName: channelName);
      }
      _activeChannels.clear();

      await pusher.disconnect();
      print('🔌 [WebSocketService] Disconnected from Reverb');
    } catch (e) {
      print('❌ [WebSocketService] Error disconnecting: $e');
    }
  }

  /// S'abonner à un canal privé de conversation
  Future<void> subscribeToConversation({
    required int conversationId,
    required Function(dynamic) onMessageReceived,
    Function(String)? onTyping,
    Function? onMessageRead,
  }) async {
    try {
      final channelName = 'private-conversation.$conversationId';

      print('🔔 [WebSocketService] Subscribing to channel: $channelName');

      // S'abonner au canal privé avec authentification
      final user = _authService.getCurrentUser();
      if (user == null) {
        print('❌ [WebSocketService] No authenticated user');
        return;
      }

      // Pour les canaux privés, Pusher va faire une requête d'auth vers votre backend
      await pusher.subscribe(
        channelName: channelName,
        onEvent: (event) {
          print('📨 [WebSocketService] Event received: ${event.eventName}');
          print('📨 [WebSocketService] Event data: ${event.data}');

          // Gérer les différents types d'événements
          switch (event.eventName) {
            case 'message.sent':
              onMessageReceived(event.data);
              break;
            case 'user.typing':
              if (onTyping != null) {
                // Extraire le username depuis les données
                final data = event.data as Map<String, dynamic>?;
                final username = data?['username'] as String? ?? 'Utilisateur';
                onTyping(username);
              }
              break;
            case 'message.read':
              if (onMessageRead != null) {
                onMessageRead();
              }
              break;
            default:
              print('⚠️ [WebSocketService] Unknown event: ${event.eventName}');
          }
        },
      );

      // Stocker le channel
      _activeChannels[channelName] = {
        'conversationId': conversationId,
        'onMessageReceived': onMessageReceived,
        'onTyping': onTyping,
        'onMessageRead': onMessageRead,
      };

      print('✅ [WebSocketService] Subscribed to conversation $conversationId');
    } catch (e) {
      print('❌ [WebSocketService] Error subscribing to conversation: $e');
    }
  }

  /// Se désabonner d'une conversation
  Future<void> unsubscribeFromConversation(int conversationId) async {
    try {
      final channelName = 'private-conversation.$conversationId';

      await pusher.unsubscribe(channelName: channelName);
      _activeChannels.remove(channelName);

      print(
        '🔕 [WebSocketService] Unsubscribed from conversation $conversationId',
      );
    } catch (e) {
      print('❌ [WebSocketService] Error unsubscribing: $e');
    }
  }

  /// S'abonner au canal de présence (utilisateurs en ligne)
  Future<void> subscribeToPresence() async {
    try {
      final channelName = 'presence-online';

      await pusher.subscribe(
        channelName: channelName,
        onEvent: (event) {
          print('👥 [WebSocketService] Presence event: ${event.eventName}');
        },
      );

      print('✅ [WebSocketService] Subscribed to presence channel');
    } catch (e) {
      print('❌ [WebSocketService] Error subscribing to presence: $e');
    }
  }

  // ==================== EVENT HANDLERS ====================

  void _onConnectionStateChange(dynamic currentState, dynamic previousState) {
    print(
      '🔄 [WebSocketService] Connection state changed: $previousState -> $currentState',
    );
    connectionState.value = currentState.toString();

    if (currentState == 'CONNECTED') {
      isConnected.value = true;
      print('✅ [WebSocketService] Connected to Reverb');
    } else {
      isConnected.value = false;
      if (currentState == 'DISCONNECTED') {
        print('🔌 [WebSocketService] Disconnected from Reverb');
      }
    }
  }

  void _onError(String message, int? code, dynamic e) {
    print('❌ [WebSocketService] Error: $message (code: $code)');
    print('❌ [WebSocketService] Error details: $e');
  }

  void _onEvent(PusherEvent event) {
    print(
      '📨 [WebSocketService] Global event: ${event.eventName} on ${event.channelName}',
    );
  }

  void _onSubscriptionSucceeded(String channelName, dynamic data) {
    print('✅ [WebSocketService] Subscription succeeded: $channelName');
    print('📊 [WebSocketService] Channel data: $data');
  }

  void _onSubscriptionError(String message, dynamic e) {
    print('❌ [WebSocketService] Subscription error: $message');
    print('❌ [WebSocketService] Error details: $e');
  }

  void _onDecryptionFailure(String event, String reason) {
    print('❌ [WebSocketService] Decryption failure: $event - $reason');
  }

  void _onMemberAdded(String channelName, PusherMember member) {
    print(
      '👤 [WebSocketService] Member added to $channelName: ${member.userId}',
    );
  }

  void _onMemberRemoved(String channelName, PusherMember member) {
    print(
      '👤 [WebSocketService] Member removed from $channelName: ${member.userId}',
    );
  }

  /// Obtenir l'état de connexion sous forme lisible
  String get connectionStateText {
    switch (connectionState.value) {
      case 'CONNECTING':
        return 'Connexion en cours...';
      case 'CONNECTED':
        return 'Connecté';
      case 'DISCONNECTING':
        return 'Déconnexion en cours...';
      case 'DISCONNECTED':
        return 'Déconnecté';
      case 'RECONNECTING':
        return 'Reconnexion...';
      default:
        return 'Inconnu';
    }
  }
}
