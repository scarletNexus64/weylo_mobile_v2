import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:weylo/app/routes/app_pages.dart';
import 'storage_service.dart';
import '../../modules/profile/controllers/profile_controller.dart';
import '../../modules/home/controllers/home_controller.dart';

// Handler pour les notifications en arrière-plan
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 [FCM_BACKGROUND] Message reçu en arrière-plan');
  print('📩 [FCM_BACKGROUND] Titre: ${message.notification?.title}');
  print('📩 [FCM_BACKGROUND] Corps: ${message.notification?.body}');
  print('📩 [FCM_BACKGROUND] Data: ${message.data}');
}

class FCMService extends GetxService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final _storage = StorageService();

  static const String _fcmTokenKey = 'fcm_token';

  /// Initialiser le service FCM
  Future<FCMService> init() async {
    print('🔥 [FCM_SERVICE] ========================================');
    print('🔥 [FCM_SERVICE] Initialisation du service FCM...');
    print('🔥 [FCM_SERVICE] ========================================');

    try {
      // Configurer les notifications locales
      print('📱 [FCM_SERVICE] Configuration des notifications locales...');
      await _initLocalNotifications();
      print('✅ [FCM_SERVICE] Notifications locales configurées');

      // Demander les permissions
      print('🔐 [FCM_SERVICE] Demande des permissions...');
      await _requestPermissions();
      print('✅ [FCM_SERVICE] Permissions demandées');

      // Gérer les notifications en arrière-plan
      print('📩 [FCM_SERVICE] Configuration du handler en arrière-plan...');
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      print('✅ [FCM_SERVICE] Handler en arrière-plan configuré');

      // Écouter les notifications en foreground
      print('📨 [FCM_SERVICE] Configuration du listener en foreground...');
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      print('✅ [FCM_SERVICE] Listener en foreground configuré');

      // Écouter les clics sur les notifications
      print('🔔 [FCM_SERVICE] Configuration du listener de clics...');
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);
      print('✅ [FCM_SERVICE] Listener de clics configuré');

      // Vérifier si l'app a été ouverte via une notification
      print('🚀 [FCM_SERVICE] Vérification du message initial...');
      await _checkInitialMessage();
      print('✅ [FCM_SERVICE] Vérification du message initial terminée');

      // Récupérer et enregistrer le token
      print('🔑 [FCM_SERVICE] Récupération du FCM token...');
      await _initFCMToken();
      print('✅ [FCM_SERVICE] FCM token récupéré et sauvegardé');

      // Écouter le refresh du token
      print('🔄 [FCM_SERVICE] Configuration du listener de refresh du token...');
      _fcm.onTokenRefresh.listen(_onTokenRefresh);
      print('✅ [FCM_SERVICE] Listener de refresh configuré');

      print('🔥 [FCM_SERVICE] ========================================');
      print('🔥 [FCM_SERVICE] Service FCM initialisé avec succès !');
      print('🔥 [FCM_SERVICE] ========================================');

      return this;
    } catch (e, stackTrace) {
      print('❌ [FCM_SERVICE] Erreur lors de l\'initialisation: $e');
      print('❌ [FCM_SERVICE] StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Initialiser les notifications locales
  Future<void> _initLocalNotifications() async {
    print('📱 [FCM_LOCAL] Configuration des paramètres Android...');
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    print('📱 [FCM_LOCAL] Configuration des paramètres iOS...');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    print('📱 [FCM_LOCAL] Initialisation du plugin de notifications locales...');
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    print('✅ [FCM_LOCAL] Plugin de notifications locales initialisé');

    // Créer le canal de notification Android
    if (Platform.isAndroid) {
      print('📱 [FCM_LOCAL] Création du canal de notification Android...');
      const channel = AndroidNotificationChannel(
        'weylo_notifications',
        'Weylo Notifications',
        description: 'Notifications pour Weylo',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      print('✅ [FCM_LOCAL] Canal de notification Android créé');
    }
  }

  /// Demander les permissions
  Future<void> _requestPermissions() async {
    print('🔐 [FCM_PERMISSIONS] Demande des permissions FCM...');

    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('🔐 [FCM_PERMISSIONS] Statut: ${settings.authorizationStatus}');

    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
        print('✅ [FCM_PERMISSIONS] Autorisé');
        break;
      case AuthorizationStatus.provisional:
        print('⚠️ [FCM_PERMISSIONS] Autorisé provisoirement');
        break;
      case AuthorizationStatus.denied:
        print('❌ [FCM_PERMISSIONS] Refusé');
        break;
      case AuthorizationStatus.notDetermined:
        print('⚠️ [FCM_PERMISSIONS] Non déterminé');
        break;
    }

    // iOS: Demander aussi les permissions pour les notifications locales
    if (Platform.isIOS) {
      print('🍎 [FCM_PERMISSIONS] Demande des permissions iOS...');
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      print('✅ [FCM_PERMISSIONS] Permissions iOS demandées');
    }
  }

  /// Initialiser et enregistrer le FCM token
  Future<void> _initFCMToken() async {
    try {
      print('🔑 [FCM_TOKEN] Récupération du token FCM...');
      final token = await _fcm.getToken();

      if (token != null) {
        print('🔑 [FCM_TOKEN] Token récupéré: ${token.substring(0, 50)}...');
        print('🔑 [FCM_TOKEN] Longueur du token: ${token.length} caractères');
        await _saveFCMTokenLocally(token);
      } else {
        print('❌ [FCM_TOKEN] Impossible de récupérer le token FCM');
      }
    } catch (e, stackTrace) {
      print('❌ [FCM_TOKEN] Erreur récupération FCM token: $e');
      print('❌ [FCM_TOKEN] StackTrace: $stackTrace');
    }
  }

  /// Sauvegarder le token localement
  Future<void> _saveFCMTokenLocally(String token) async {
    final oldToken = _storage.read(_fcmTokenKey);

    if (oldToken == token) {
      print('🔑 [FCM_TOKEN] Token identique, pas de changement');
      return;
    }

    print('💾 [FCM_TOKEN] Sauvegarde du token en local...');
    await _storage.write(_fcmTokenKey, token);
    print('✅ [FCM_TOKEN] Token sauvegardé en local');
  }

  /// Envoyer le token au backend (appelé depuis auth_service après login/register)
  Future<void> sendTokenToBackend(String token) async {
    print('📡 [FCM_TOKEN] ========================================');
    print('📡 [FCM_TOKEN] Envoi du token au backend...');
    print('📡 [FCM_TOKEN] Token: ${token.substring(0, 50)}...');
    print('📡 [FCM_TOKEN] ========================================');
    // Note: L'envoi est maintenant géré par auth_service.dart
    // Cette méthode est gardée pour référence si besoin
  }

  /// Gérer le refresh du token
  void _onTokenRefresh(String token) {
    print('🔄 [FCM_TOKEN] ========================================');
    print('🔄 [FCM_TOKEN] Token FCM rafraîchi !');
    print('🔄 [FCM_TOKEN] Nouveau token: ${token.substring(0, 50)}...');
    print('🔄 [FCM_TOKEN] ========================================');
    _saveFCMTokenLocally(token);
    // TODO: Envoyer le nouveau token au backend via AuthService
  }

  /// Gérer les notifications en foreground
  void _handleForegroundMessage(RemoteMessage message) {
    print('📨 [FCM_FOREGROUND] ========================================');
    print('📨 [FCM_FOREGROUND] Notification reçue en foreground');
    print('📨 [FCM_FOREGROUND] Titre: ${message.notification?.title}');
    print('📨 [FCM_FOREGROUND] Corps: ${message.notification?.body}');
    print('📨 [FCM_FOREGROUND] Data: ${message.data}');
    print('📨 [FCM_FOREGROUND] ========================================');

    // Afficher une notification locale
    if (message.notification != null) {
      print('📨 [FCM_FOREGROUND] Affichage de la notification locale...');
      _showLocalNotification(message);
    }

    // Traiter les données
    _handleNotificationData(message.data);
  }

  /// Afficher une notification locale
  Future<void> _showLocalNotification(RemoteMessage message) async {
    print('🔔 [FCM_LOCAL_NOTIF] Préparation de la notification...');

    const androidDetails = AndroidNotificationDetails(
      'weylo_notifications',
      'Weylo Notifications',
      channelDescription: 'Notifications pour Weylo',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        message.hashCode,
        message.notification?.title,
        message.notification?.body,
        details,
        payload: message.data['type'],
      );
      print('✅ [FCM_LOCAL_NOTIF] Notification affichée');
    } catch (e) {
      print('❌ [FCM_LOCAL_NOTIF] Erreur affichage notification: $e');
    }
  }

  /// Gérer le clic sur une notification (notification locale)
  void _onNotificationTap(NotificationResponse response) {
    print('👆 [FCM_CLICK] ========================================');
    print('👆 [FCM_CLICK] Notification cliquée (locale)');
    print('👆 [FCM_CLICK] Payload: ${response.payload}');
    print('👆 [FCM_CLICK] ========================================');

    final payload = response.payload;
    if (payload != null) {
      _navigateBasedOnType(payload, {});
    }
  }

  /// Gérer le clic sur une notification (app en arrière-plan)
  void _handleNotificationClick(RemoteMessage message) {
    print('👆 [FCM_CLICK] ========================================');
    print('👆 [FCM_CLICK] Notification cliquée (arrière-plan)');
    print('👆 [FCM_CLICK] Titre: ${message.notification?.title}');
    print('👆 [FCM_CLICK] Data: ${message.data}');
    print('👆 [FCM_CLICK] ========================================');

    _handleNotificationData(message.data);
  }

  /// Vérifier si l'app a été ouverte via une notification
  Future<void> _checkInitialMessage() async {
    print('🚀 [FCM_INITIAL] Vérification du message initial...');

    final message = await _fcm.getInitialMessage();

    if (message != null) {
      print('🚀 [FCM_INITIAL] ========================================');
      print('🚀 [FCM_INITIAL] App ouverte via notification !');
      print('🚀 [FCM_INITIAL] Titre: ${message.notification?.title}');
      print('🚀 [FCM_INITIAL] Data: ${message.data}');
      print('🚀 [FCM_INITIAL] ========================================');

      _handleNotificationData(message.data);
    } else {
      print('🚀 [FCM_INITIAL] Pas de message initial');
    }
  }

  /// Traiter les données de la notification
  void _handleNotificationData(Map<String, dynamic> data) {
    print('📊 [FCM_DATA] Traitement des données: $data');

    final type = data['type'];
    if (type != null) {
      print('📊 [FCM_DATA] Type de notification: $type');
      _navigateBasedOnType(type, data);
    } else {
      print('⚠️ [FCM_DATA] Pas de type dans les données');
    }
  }

  /// Navigation basée sur le type de notification
  void _navigateBasedOnType(String type, Map<String, dynamic> data) {
    print('🧭 [FCM_NAV] Navigation pour le type: $type');

    switch (type) {
      case 'welcome':
        print('🧭 [FCM_NAV] Type: Bienvenue');
        // Navigation vers la page d'accueil
        // Get.toNamed('/home');
        break;

      case 'new_message':
        final messageId = data['message_id'];
        print('🧭 [FCM_NAV] Type: Nouveau message (ID: $messageId)');
        // Get.toNamed('/messages/$messageId');
        break;

      case 'new_chat_message':
        final conversationId = data['conversation_id'];
        print('🧭 [FCM_NAV] Type: Nouveau message chat (Conversation: $conversationId)');
        // Get.toNamed('/chat/$conversationId');
        break;

      case 'new_public_confession':
        final confessionId = data['confession_id'];
        print('🧭 [FCM_NAV] Type: Nouvelle confession publique (ID: $confessionId)');
        // Get.toNamed('/confessions/$confessionId');
        break;

      case 'new_story':
        final storyId = data['story_id'];
        final userId = data['user_id'];
        print('🧭 [FCM_NAV] Type: Nouvelle story (Story: $storyId, User: $userId)');
        // Get.toNamed('/stories/user/$userId');
        break;

      case 'global_announcement':
        print('🧭 [FCM_NAV] Type: Annonce globale de l\'admin');
        print('🧭 [FCM_NAV] Envoyée par: ${data['sent_by']}');
        print('🧭 [FCM_NAV] Date: ${data['sent_at']}');
        // Pas de navigation spécifique, juste afficher la notification
        // L'utilisateur peut déjà voir le message dans la notification
        break;

      case 'profile_view':
        print('🧭 [FCM_NAV] Type: Vue de profil (Admirateur secret)');
        print('🧭 [FCM_NAV] Navigation vers le profil et ouverture du bottomsheet...');

        // Naviguer vers la page home (qui contient le profil comme onglet)
        Get.offAllNamed(Routes.HOME);

        // Attendre que la navigation soit complète et que le profil se charge
        Future.delayed(const Duration(milliseconds: 1000), () {
          try {
            print('🧭 [FCM_NAV] Changement vers l\'onglet profil...');

            // Obtenir le HomeController et changer l'onglet vers Profile (index 4)
            final homeController = Get.find<HomeController>();
            homeController.tabController.animateTo(4); // Profile tab index

            print('🧭 [FCM_NAV] Tentative d\'ouverture du bottomsheet des visiteurs...');
            final profileController = Get.find<ProfileController>();

            // Recharger les visiteurs avant d'ouvrir le bottomsheet
            profileController.loadProfileVisitors().then((_) {
              print('🧭 [FCM_NAV] Visiteurs rechargés, ouverture du bottomsheet...');
              profileController.showProfileVisitors();
            });
          } catch (e) {
            print('❌ [FCM_NAV] Erreur affichage visiteurs: $e');
          }
        });
        break;

      default:
        print('⚠️ [FCM_NAV] Type de notification inconnu: $type');
    }
  }

  /// Souscrire à un topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      print('📢 [FCM_TOPIC] Souscription au topic: $topic...');
      await _fcm.subscribeToTopic(topic);
      print('✅ [FCM_TOPIC] Souscrit au topic: $topic');
    } catch (e) {
      print('❌ [FCM_TOPIC] Erreur souscription topic $topic: $e');
    }
  }

  /// Se désabonner d'un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      print('📢 [FCM_TOPIC] Désinscription du topic: $topic...');
      await _fcm.unsubscribeFromTopic(topic);
      print('✅ [FCM_TOPIC] Désinscrit du topic: $topic');
    } catch (e) {
      print('❌ [FCM_TOPIC] Erreur désinscription topic $topic: $e');
    }
  }

  /// Souscrire à tous les topics (appelé après login/register)
  Future<void> subscribeToAllTopics() async {
    print('📢 [FCM_TOPIC] ========================================');
    print('📢 [FCM_TOPIC] Souscription à tous les topics...');
    print('📢 [FCM_TOPIC] ========================================');

    await subscribeToTopic('global_announcements');  // Annonces globales de l'admin
    await subscribeToTopic('new_confessions');       // Nouvelles confessions publiques
    await subscribeToTopic('new_stories');           // Nouvelles stories

    print('📢 [FCM_TOPIC] ========================================');
    print('📢 [FCM_TOPIC] Souscription terminée (3 topics)');
    print('📢 [FCM_TOPIC] ========================================');
  }

  /// Se désabonner de tous les topics (appelé lors du logout)
  Future<void> unsubscribeFromAllTopics() async {
    print('📢 [FCM_TOPIC] ========================================');
    print('📢 [FCM_TOPIC] Désinscription de tous les topics...');
    print('📢 [FCM_TOPIC] ========================================');

    await unsubscribeFromTopic('global_announcements');
    await unsubscribeFromTopic('new_confessions');
    await unsubscribeFromTopic('new_stories');

    print('📢 [FCM_TOPIC] ========================================');
    print('📢 [FCM_TOPIC] Désinscription terminée (3 topics)');
    print('📢 [FCM_TOPIC] ========================================');
  }

  /// Récupérer le token FCM
  Future<String?> getToken() async {
    try {
      // D'abord essayer de lire depuis le storage
      final storedToken = _storage.read(_fcmTokenKey);
      if (storedToken != null) {
        print('🔑 [FCM_TOKEN] Token récupéré depuis le storage: ${storedToken.substring(0, 50)}...');
        return storedToken;
      }

      // Sinon récupérer depuis Firebase
      print('🔑 [FCM_TOKEN] Token non trouvé en storage, récupération depuis Firebase...');
      final token = await _fcm.getToken();

      if (token != null) {
        print('🔑 [FCM_TOKEN] Token récupéré depuis Firebase: ${token.substring(0, 50)}...');
        await _saveFCMTokenLocally(token);
      }

      return token;
    } catch (e) {
      print('❌ [FCM_TOKEN] Erreur récupération token: $e');
      return null;
    }
  }
}
