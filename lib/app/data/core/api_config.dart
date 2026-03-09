class ApiConfig {
  // Pour le développement local, utilisez:
  // 10.0.2.2 pour Android Emulator (redirige vers localhost de votre Mac)
  // 127.0.0.1 pour iOS Simulator
  // 10.83.249.46 pour un vrai téléphone sur le même WiFi
  // Changez cette ligne selon votre device de test
  static const String baseUrl = 'http://10.83.249.46:8001/api/v1';

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String refresh = '/auth/refresh';

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
