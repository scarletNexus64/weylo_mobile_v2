class ApiConfig {
  // // PRODUCTION CONFIGURATION
  // static const String baseUrl = 'https://weylo-adminpanel.space/api/v1';

  // // Anonymous link base URL (without trailing slash, will be appended with /username)
  // static const String anonymousLinkUrl = 'https://weylo.app/u';

  // // Anonymous link host (extracted from anonymousLinkUrl for deeplink validation)
  // static const String anonymousLinkHost = 'weylo.app';

  // // WebSocket/Reverb configuration (Production)
  // static const String wsHost = 'weylo-adminpanel.space';
  // static const int wsPort = 443;
  // static const String wsAppKey = '1425cdd3ef7425fa6746d2895a233e52';
  // static const String wsAppId = 'Weylo-app';
  // static const bool forceTLS = true;

  // DEVELOPMENT CONFIGURATION (Uncomment for local development)
  // Pour le développement local, utilisez:
  // 10.0.2.2 pour Android Emulator (redirige vers localhost de votre Mac)
  // 127.0.0.1 pour iOS Simulator
  // nonhedonic-slung-aura.ngrok-free.dev pour un vrai téléphone sur le même WiFi
  // Changez cette ligne selon votre device de test
  static const String baseUrl = 'http://10.195.115.28:8001/api/v1';

  // Anonymous link base URL (without trailing slash, will be appended with /username)
  static const String anonymousLinkUrl = 'http://10.195.115.28:3000/u';

  // Anonymous link host (extracted from anonymousLinkUrl for deeplink validation)
  static const String anonymousLinkHost = '10.195.115.28:3000';

  // WebSocket/Reverb configuration (Development)
  static const String wsHost = '10.195.115.28';
  static const int wsPort = 8080;
  static const String wsAppKey = '1425cdd3ef7425fa6746d2895a233e52';
  static const String wsAppId = 'Weylo-app';
  static const bool forceTLS = false;

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String refresh = '/auth/refresh';
  static const String updateFcmToken = '/auth/fcm-token';

  // Users endpoints
  static const String users = '/users';
  static const String updateProfile = '/users/profile';
  static const String updateSettings = '/users/settings';
  static const String changePassword = '/users/password';
  static const String uploadAvatar = '/users/avatar';
  static const String deleteAvatar = '/users/avatar';
  static const String uploadCoverPhoto = '/users/cover-photo';
  static const String deleteCoverPhoto = '/users/cover-photo';
  static const String dashboard = '/users/dashboard';
  static const String stats = '/users/stats';
  static const String shareLink = '/users/share-link';

  // Messages endpoints
  static const String messages = '/messages';
  static const String sentMessages = '/messages/sent';
  static const String messageStats = '/messages/stats';
  static String sendMessage(String username) => '/messages/send/$username';
  static const String sendReply = '/messages/send/reply';

  // Confessions endpoints
  static const String confessions = '/confessions';
  static const String receivedConfessions = '/confessions/received';
  static const String sentConfessions = '/confessions/sent';
  static const String favoriteConfessions = '/confessions/favorites';

  // Chat endpoints
  static const String conversations = '/chat/conversations';
  static const String chatStats = '/chat/stats';

  // Groups endpoints
  static const String groups = '/groups';
  static const String discoverGroups = '/groups/discover';
  static const String groupCategories = '/group-categories';

  // Gifts endpoints
  static const String gifts = '/gifts';
  static const String receivedGifts = '/gifts/received';
  static const String sentGifts = '/gifts/sent';

  // Premium endpoints
  static const String premiumSubscriptions = '/premium/subscriptions';
  static const String premiumCheck = '/premium/check';

  // Wallet endpoints
  static const String wallet = '/wallet';
  static const String transactions = '/wallet/transactions';
  static const String walletStats = '/wallet/stats';

  // Sponsoring endpoints
  static const String sponsorshipPackages = '/sponsorship-packages';
  static const String sponsorshipPurchase = '/sponsorships/purchase';
  static const String sponsorshipMine = '/sponsorships/mine';
  static const String sponsorshipDashboard = '/sponsorships/dashboard';

  // Notifications endpoints
  static const String notifications = '/notifications';
  static const String unreadCount = '/notifications/unread-count';

  // Stories endpoints
  static const String stories = '/stories';
  static const String myStories = '/stories/my-stories';

  // Timeout configuration
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(
    seconds: 120,
  ); // 2 min pour upload de gros fichiers
}
