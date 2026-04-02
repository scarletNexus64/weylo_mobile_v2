import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/modules/feeds/controllers/feeds_controller.dart';
import 'package:weylo/app/modules/anonymepage/controllers/anonymepage_controller.dart';
import 'package:weylo/app/modules/groupe/controllers/groupe_controller.dart';
import 'package:weylo/app/modules/chat/controllers/chat_controller.dart';
import 'package:weylo/app/data/services/realtime_service.dart';
import 'package:weylo/app/data/services/group_service.dart';
import 'package:weylo/app/data/services/auth_service.dart';
import 'package:weylo/app/data/services/notification_service.dart';

class HomeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // Scaffold key for drawer
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Tab controller
  late TabController tabController;

  // NestedScrollView controller - CRITIQUE pour éviter les problèmes de scroll
  final nestedScrollController = ScrollController();

  // Current tab index
  final currentTabIndex = 0.obs;

  // Unread counts
  final groupsUnreadCount = 0.obs;
  final notificationsUnreadCount = 0.obs;
  final activeStreaksCount = 0.obs;

  // Services
  final _groupService = GroupService();
  final _authService = AuthService();
  final _notificationService = NotificationService();
  RealtimeService? _realtimeService;
  int? _currentUserId;

  // Tab names
  final List<String> tabNames = [
    'Anonyme',
    'Chat',
    'Groupe',
    'Confession',
    'Profile',
  ];

  // Tab icons
  final List<IconData> tabIcons = [
    Icons.masks, // Icône pour Anonyme
    Icons.chat_bubble_rounded,
    Icons.groups_rounded, // Icône pour Groupe
    Icons.dynamic_feed_rounded,
    Icons.account_circle_rounded,
  ];

  @override
  void onInit() {
    super.onInit();
    print('🎬 [HOME_CONTROLLER] Initialisation du HomeController');

    tabController = TabController(length: 5, vsync: this);
    tabController.addListener(_onTabChanged);

    // Écouter le scroll du NestedScrollView pour détecter les anomalies
    nestedScrollController.addListener(_onNestedScrollChanged);

    // ═══════════════════════════════════════════════════════════
    // INITIALISER LA CONNEXION WEBSOCKET (TEMPS RÉEL)
    // ═══════════════════════════════════════════════════════════
    _initializeRealtimeConnection();

    // Charger les counts de notifications
    _loadNotificationCounts();
  }

  /// Initialiser la connexion WebSocket pour les messages en temps réel
  void _initializeRealtimeConnection() async {
    print('');
    print('╔═══════════════════════════════════════════════════════════╗');
    print('║ 🔌 INITIALISATION WEBSOCKET DEPUIS HOME CONTROLLER');
    print('╚═══════════════════════════════════════════════════════════╝');

    try {
      // Créer ou récupérer le RealtimeService
      if (!Get.isRegistered<RealtimeService>()) {
        print('📝 RealtimeService n\'est pas encore enregistré, création...');
        Get.put(RealtimeService());
        print('✅ RealtimeService créé et enregistré dans GetX');
      } else {
        print('✅ RealtimeService déjà enregistré');
      }

      _realtimeService = Get.find<RealtimeService>();

      // Récupérer l'ID utilisateur
      final user = await _authService.getCurrentUser();
      _currentUserId = user?.id;

      if (_currentUserId != null) {
        print('👤 [HOME_CONTROLLER] User ID: $_currentUserId');

        // S'abonner au canal privé de l'utilisateur pour recevoir les notifications de groupe
        await _realtimeService!.subscribeToPrivateChannel(
          channelName: 'private-user.$_currentUserId',
          onEvent: _handleGroupMessageNotification,
        );

        print(
          '✅ [HOME_CONTROLLER] Subscribed to private-user.$_currentUserId for group notifications',
        );
      }

      // La connexion WebSocket se fera automatiquement dans onInit() du service
      print('⏳ La connexion WebSocket démarre automatiquement...');
      print('╚═══════════════════════════════════════════════════════════╝');
      print('');
    } catch (e) {
      print('');
      print('❌❌❌ ERREUR LORS DE L\'INITIALISATION WEBSOCKET ❌❌❌');
      print('Erreur: $e');
      print('Stack trace: ${StackTrace.current}');
      print('═══════════════════════════════════════════════════════════');
      print('');
    }
  }

  /// Callback appelé quand on change de tab
  void _onTabChanged() {
    final newIndex = tabController.index;
    final previousIndex = currentTabIndex.value;
    currentTabIndex.value = newIndex;

    print(
      '🔀 [HOME_CONTROLLER] Changement de tab: $previousIndex -> $newIndex (${tabNames[newIndex]})',
    );

    // CRITIQUE: Réinitialiser le NestedScrollView à chaque changement de tab
    _resetNestedScroll(reason: 'Changement de tab vers ${tabNames[newIndex]}');

    // Vérifier le scroll du tab spécifique
    _checkTabScroll(newIndex, previousIndex);
  }

  /// Callback appelé quand le scroll du NestedScrollView change
  void _onNestedScrollChanged() {
    if (nestedScrollController.hasClients) {
      final offset = nestedScrollController.offset;

      // Détecter les offsets anormaux (hors limites)
      if (offset < 0 ||
          offset > nestedScrollController.position.maxScrollExtent + 100) {
        print(
          '⚠️ [HOME_CONTROLLER] Offset NestedScroll ANORMAL détecté: $offset',
        );
        _resetNestedScroll(reason: 'Offset anormal détecté');
      }
    }
  }

  /// Vérifier la santé du scroll du tab Confession quand on y revient
  void _checkConfessionScroll() {
    print(
      '🔍 [HOME_CONTROLLER] _checkConfessionScroll() - Début de la vérification',
    );
    // Attendre plusieurs frames pour que le tab soit complètement affiché et rendu
    // Utiliser plusieurs vérifications espacées pour garantir la stabilité
    Future.delayed(const Duration(milliseconds: 50), () {
      print('⏰ [HOME_CONTROLLER] Première vérification (50ms)');
      _performScrollCheck();
    });

    // Deuxième vérification après un délai plus long pour garantir que tout est stable
    Future.delayed(const Duration(milliseconds: 250), () {
      print('⏰ [HOME_CONTROLLER] Deuxième vérification (250ms)');
      _performScrollCheck();
    });
  }

  /// Effectuer une vérification du scroll avec gestion d'erreur robuste
  void _performScrollCheck() {
    // Vérifier si le controller existe avant de l'utiliser
    if (!Get.isRegistered<ConfessionsController>()) {
      print(
        '⚠️ [HOME] ConfessionsController pas encore enregistré, vérification ignorée',
      );
      return;
    }

    try {
      final confessionsController = Get.find<ConfessionsController>();

      // Vérifier que le controller a des clients
      if (!confessionsController.scrollController.hasClients) {
        print('⚠️ [HOME] ScrollController n\'a pas encore de clients');
        return;
      }

      final currentOffset = confessionsController.scrollController.offset;
      final position = confessionsController.scrollController.position;

      // Vérifier si la position a des dimensions valides
      if (!position.hasContentDimensions) {
        print('⚠️ [HOME] Position n\'a pas encore de dimensions de contenu');
        return;
      }

      final maxExtent = position.maxScrollExtent;
      final minExtent = position.minScrollExtent;

      // IMPORTANT: Toujours réinitialiser le scroll à 0 quand on revient au tab Confessions
      // pour s'assurer que les stories sont visibles en haut
      if (currentOffset != 0) {
        print(
          '🔧 [HOME] Scroll détecté à $currentOffset (limites: [$minExtent, $maxExtent]), RÉINITIALISATION forcée à 0...',
        );

        // Utiliser animateTo pour un retour en douceur si le scroll est petit
        if (currentOffset < 200) {
          confessionsController.scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
          print('✅ [HOME] Scroll animé vers 0');
        } else {
          // Utiliser jumpTo pour un reset immédiat si le scroll est important
          confessionsController.scrollController.jumpTo(0);
          print('✅ [HOME] Scroll sauté vers 0');
        }
      } else {
        print('✅ [HOME] Scroll déjà à 0, aucune action nécessaire');
      }
    } catch (e) {
      print('⚠️ [HOME] Erreur lors de la vérification du scroll: $e');
    }
  }

  @override
  void onClose() {
    print('🗑️ [HOME_CONTROLLER] Destruction du HomeController');
    tabController.removeListener(_onTabChanged);
    tabController.dispose();
    nestedScrollController.removeListener(_onNestedScrollChanged);
    nestedScrollController.dispose();

    // Unsubscribe du WebSocket
    if (_realtimeService != null && _currentUserId != null) {
      _realtimeService!.unsubscribeFromChannel('private-user.$_currentUserId');
      print('🔌 [HOME_CONTROLLER] Unsubscribed from WebSocket');
    }

    super.onClose();
  }

  /// MÉTHODE CENTRALE: Réinitialiser le scroll du NestedScrollView
  /// Cette méthode est la CLÉ pour résoudre tous les problèmes de scroll
  void _resetNestedScroll({required String reason}) {
    print('🔧 [HOME_CONTROLLER] Réinitialisation NestedScroll: $reason');

    if (!nestedScrollController.hasClients) {
      print('⚠️ [HOME_CONTROLLER] NestedScrollController n\'a pas de clients');
      return;
    }

    try {
      final currentOffset = nestedScrollController.offset;
      final position = nestedScrollController.position;

      if (!position.hasContentDimensions) {
        print(
          '⚠️ [HOME_CONTROLLER] Position n\'a pas de dimensions de contenu',
        );
        return;
      }

      final maxExtent = position.maxScrollExtent;
      final minExtent = position.minScrollExtent;

      print(
        '📊 [HOME_CONTROLLER] État actuel - Offset: $currentOffset, Limites: [$minExtent, $maxExtent]',
      );

      // TOUJOURS réinitialiser à 0 pour garantir un état propre
      if (currentOffset != 0) {
        print('🔄 [HOME_CONTROLLER] Réinitialisation de $currentOffset vers 0');
        nestedScrollController.jumpTo(0);
        print('✅ [HOME_CONTROLLER] NestedScroll réinitialisé à 0');
      } else {
        print('✅ [HOME_CONTROLLER] NestedScroll déjà à 0');
      }
    } catch (e) {
      print('❌ [HOME_CONTROLLER] Erreur lors de la réinitialisation: $e');
      // En dernier recours, forcer un jumpTo(0)
      try {
        nestedScrollController.jumpTo(0);
        print('✅ [HOME_CONTROLLER] Réinitialisation forcée réussie');
      } catch (e2) {
        print('❌ [HOME_CONTROLLER] Échec complet de la réinitialisation: $e2');
      }
    }
  }

  /// Vérifier le scroll du tab spécifique après changement
  void _checkTabScroll(int newIndex, int previousIndex) {
    // Délai pour laisser le temps au widget de se monter
    Future.delayed(const Duration(milliseconds: 50), () {
      switch (newIndex) {
        case 3: // Confessions
          print('📱 [HOME_CONTROLLER] Vérification du scroll Confessions');
          _checkConfessionScroll();
          break;
        case 0: // Anonyme
        case 1: // Chat
        case 2: // Groupe
          print(
            '📱 [HOME_CONTROLLER] Vérification du scroll ${tabNames[newIndex]}',
          );
          // Les autres tabs peuvent aussi avoir besoin de vérification
          break;
        case 4: // Profile
          print(
            '📱 [HOME_CONTROLLER] Profile affiché, pas de vérification nécessaire',
          );
          break;
      }
    });

    // Deuxième vérification après un délai plus long
    Future.delayed(const Duration(milliseconds: 250), () {
      _resetNestedScroll(
        reason: 'Vérification tardive après changement de tab',
      );
    });
  }

  // Change tab programmatically
  void changeTab(int index) {
    print(
      '🎯 [HOME_CONTROLLER] Changement de tab programmé vers ${tabNames[index]}',
    );
    tabController.animateTo(index);
  }

  /// MÉTHODE PUBLIQUE: Réinitialiser tous les scrolls (NestedScroll + tab actuel)
  /// À appeler après un retour de navigation problématique
  void resetAllScrolls() {
    print('🔄 [HOME_CONTROLLER] Réinitialisation COMPLÈTE de tous les scrolls');

    // 1. Réinitialiser le NestedScrollView
    _resetNestedScroll(reason: 'Réinitialisation complète demandée');

    // 2. Réinitialiser le scroll du tab actuel
    final currentTab = currentTabIndex.value;
    switch (currentTab) {
      case 0: // Anonyme
        _resetAnonymeScroll();
        break;
      case 1: // Chat
        _resetChatScroll();
        break;
      case 2: // Groupe
        _resetGroupeScroll();
        break;
      case 3: // Confessions
        _resetConfessionsScroll();
        break;
      case 4: // Profile
        _resetProfileScroll();
        break;
    }

    print('✅ [HOME_CONTROLLER] Réinitialisation complète terminée');
  }

  /// Réinitialiser le scroll du tab Anonyme
  void _resetAnonymeScroll() {
    print('🔄 [HOME_CONTROLLER] Réinitialisation scroll Anonyme');

    // Vérifier si le controller existe avant de l'utiliser
    if (!Get.isRegistered<AnonymepageController>()) {
      print('⚠️ [HOME_CONTROLLER] AnonymepageController pas encore enregistré');
      return;
    }

    try {
      final anonymeController = Get.find<AnonymepageController>();
      if (anonymeController.scrollController.hasClients) {
        anonymeController.scrollController.jumpTo(0);
        print('✅ [HOME_CONTROLLER] Scroll Anonyme réinitialisé');
      }
    } catch (e) {
      print(
        '⚠️ [HOME_CONTROLLER] Erreur lors de la réinitialisation du scroll Anonyme: $e',
      );
    }
  }

  /// Réinitialiser le scroll du tab Chat
  void _resetChatScroll() {
    print('🔄 [HOME_CONTROLLER] Réinitialisation scroll Chat');
    try {
      // ChatView n'a pas de scroll controller propre (ListView interne)
      // Pas besoin de réinitialiser
      print('✅ [HOME_CONTROLLER] Chat n\'a pas de scroll à réinitialiser');
    } catch (e) {
      print('⚠️ [HOME_CONTROLLER] Erreur Chat: $e');
    }
  }

  /// Réinitialiser le scroll du tab Groupe
  void _resetGroupeScroll() {
    print('🔄 [HOME_CONTROLLER] Réinitialisation scroll Groupe');
    try {
      // GroupeView n'a pas de scroll controller propre (ListView interne)
      // Pas besoin de réinitialiser
      print('✅ [HOME_CONTROLLER] Groupe n\'a pas de scroll à réinitialiser');
    } catch (e) {
      print('⚠️ [HOME_CONTROLLER] Erreur Groupe: $e');
    }
  }

  /// Réinitialiser le scroll du tab Confessions
  void _resetConfessionsScroll() {
    print('🔄 [HOME_CONTROLLER] Réinitialisation scroll Confessions');

    // Vérifier si le controller existe avant de l'utiliser
    if (!Get.isRegistered<ConfessionsController>()) {
      print('⚠️ [HOME_CONTROLLER] ConfessionsController pas encore enregistré');
      return;
    }

    try {
      final confessionsController = Get.find<ConfessionsController>();
      if (confessionsController.scrollController.hasClients) {
        confessionsController.scrollController.jumpTo(0);
        print('✅ [HOME_CONTROLLER] Scroll Confessions réinitialisé');
      }
    } catch (e) {
      print(
        '⚠️ [HOME_CONTROLLER] Erreur lors de la réinitialisation du scroll Confessions: $e',
      );
    }
  }

  /// Réinitialiser le scroll du tab Profile
  void _resetProfileScroll() {
    print('🔄 [HOME_CONTROLLER] Réinitialisation scroll Profile');
    try {
      // ProfileView utilise un SingleChildScrollView sans controller exposé
      // Le RefreshIndicator gère déjà le reset
      print('✅ [HOME_CONTROLLER] Profile se gère automatiquement');
    } catch (e) {
      print('⚠️ [HOME_CONTROLLER] Erreur Profile: $e');
    }
  }

  // Handle tab tap - scroll to top if tapping on same tab
  void handleTabTap(int index) {
    // If tapping on Feed/Confession tab (index 3) and already on it
    if (index == 3 && currentTabIndex.value == 3) {
      try {
        final confessionsController = Get.find<ConfessionsController>();
        confessionsController.scrollToTop();
      } catch (e) {
        // Controller not found or not initialized
        print('ConfessionsController not found: $e');
      }
    }

    // If tapping on Groupe tab (index 2), refresh groups and badges
    if (index == 2) {
      try {
        final groupeController = Get.find<GroupeController>();
        groupeController.onPageResumed();
        print('🔄 [HOME_CONTROLLER] Refreshing Groupe page');
      } catch (e) {
        print('❌ [HOME_CONTROLLER] GroupeController not found: $e');
      }
    }

    // Always allow tab change
    tabController.animateTo(index);
  }

  /// Gérer les notifications de nouveaux messages de groupe en temps réel
  void _handleGroupMessageNotification(Map<String, dynamic> eventData) {
    try {
      // Extraire l'événement
      final event = eventData['_event'] as String?;

      // On s'intéresse uniquement aux messages envoyés
      if (event != 'message.sent') return;

      // Vérifier si c'est un message de groupe
      final groupId = eventData['group_id'] as int?;
      if (groupId == null) return;

      // Vérifier si ce n'est pas notre propre message
      final senderId = eventData['sender_id'] as int?;
      if (senderId == _currentUserId) {
        print('📨 [HOME_CONTROLLER] Own message, not incrementing badge');
        return;
      }

      print(
        '📨 [HOME_CONTROLLER] New group message received, incrementing badge',
      );
      print('   - Group ID: $groupId');
      print('   - Sender ID: $senderId');
      print('   - Current badge: ${groupsUnreadCount.value}');

      // Incrémenter le badge
      groupsUnreadCount.value++;

      print('   - New badge: ${groupsUnreadCount.value}');
    } catch (e) {
      print(
        '❌ [HOME_CONTROLLER] Error handling group message notification: $e',
      );
    }
  }

  /// Charger les counts de notifications
  Future<void> _loadNotificationCounts() async {
    try {
      // Récupérer le count des groupes non lus
      final groupsCount = await _groupService.getUnreadCount();
      groupsUnreadCount.value = groupsCount;
      print('📊 [HOME_CONTROLLER] Groups unread count: $groupsCount');

      // Récupérer le count des notifications non lues
      final notificationsCount = await _notificationService.getUnreadCount();
      notificationsUnreadCount.value = notificationsCount;
      print(
        '📊 [HOME_CONTROLLER] Notifications unread count: $notificationsCount',
      );

      // Le compteur de flammes est maintenant réactif et mis à jour automatiquement
      // via le ChatController.totalStreakDays qui est un RxInt
      print('🔥 [HOME_CONTROLLER] Flame counter is reactive and auto-updated');
    } catch (e) {
      print('❌ [HOME_CONTROLLER] Error loading notification counts: $e');
    }
  }

  /// Rafraîchir les counts de notifications (appelé quand on revient d'un groupe)
  void refreshNotificationCounts() {
    _loadNotificationCounts();
  }

  /// Naviguer vers la page des notifications
  void openNotificationsPage() {
    print('🔔 [HOME_CONTROLLER] Opening notifications page');
    Get.toNamed('/notification');
  }

  // Open drawer
  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  // Close drawer
  void closeDrawer() {
    scaffoldKey.currentState?.closeDrawer();
  }
}
