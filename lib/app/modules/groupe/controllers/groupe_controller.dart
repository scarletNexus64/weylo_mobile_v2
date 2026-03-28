import 'package:get/get.dart';
import 'package:weylo/app/data/services/group_service.dart';
import 'package:weylo/app/data/models/group_model.dart';
import 'package:weylo/app/data/models/group_message_model.dart';
import 'package:weylo/app/data/models/group_category_model.dart';
import 'package:weylo/app/data/services/realtime_service.dart';
import 'package:weylo/app/data/services/auth_service.dart';
import 'package:weylo/app/modules/home/controllers/home_controller.dart';
import 'dart:async';

enum GroupTab { myGroups, discover }

class GroupeController extends GetxController {
  final GroupService _groupService = GroupService();
  final AuthService _authService = AuthService();
  RealtimeService? _realtimeService;
  Timer? _searchDebounce;
  int? _currentUserId;

  // Tab selection
  final selectedTab = GroupTab.myGroups.obs;

  // My Groups - États
  final isLoadingMyGroups = false.obs;
  final isLoadingMoreMyGroups = false.obs;
  final hasErrorMyGroups = false.obs;
  final errorMessageMyGroups = ''.obs;

  // My Groups - Données
  final myGroups = <GroupModel>[].obs;

  // My Groups - Pagination
  int myGroupsCurrentPage = 1;
  int myGroupsLastPage = 1;
  final canLoadMoreMyGroups = false.obs;

  // Discover Groups - États
  final isLoadingDiscoverGroups = false.obs;
  final isLoadingMoreDiscoverGroups = false.obs;
  final hasErrorDiscoverGroups = false.obs;
  final errorMessageDiscoverGroups = ''.obs;

  // Discover Groups - Données
  final discoverGroups = <GroupModel>[].obs;

  // Discover Groups - Pagination
  int discoverGroupsCurrentPage = 1;
  int discoverGroupsLastPage = 1;
  final canLoadMoreDiscoverGroups = false.obs;

  // Categories
  final categories = <GroupCategoryModel>[].obs;
  final isLoadingCategories = false.obs;
  final Rxn<int> selectedCategoryId = Rxn<int>();

  // Search
  final searchQuery = ''.obs;
  final isSearching = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onReady() {
    super.onReady();
    // Appelé quand la page est complètement construite et visible
    print('🔄 [GroupeController] Page ready, refreshing data...');
  }

  /// Appelé quand on revient sur la page (changement de tab)
  Future<void> onPageResumed() async {
    print('🔄 [GroupeController] Page resumed, refreshing groups and badges...');

    // Rafraîchir les groupes
    await refreshMyGroups();

    // Mettre à jour les badges dans le HomeController
    try {
      final homeController = Get.find<HomeController>();
      final count = await _groupService.getUnreadCount();
      homeController.groupsUnreadCount.value = count;
      print('📊 [GroupeController] Updated badge count: $count');
    } catch (e) {
      print('❌ [GroupeController] Error updating badge: $e');
    }
  }

  Future<void> _initialize() async {
    // Récupérer l'ID utilisateur
    final user = await _authService.getCurrentUser();
    _currentUserId = user?.id;

    // Charger les données
    await loadMyGroups();
    loadCategories();
    loadDiscoverGroups();

    // Configurer les listeners WebSocket
    _setupRealtimeListeners();
  }

  void setTab(GroupTab tab) {
    selectedTab.value = tab;
    // Plus besoin de charger ici car on charge dès le départ dans onInit()
  }

  /// Charger les catégories depuis l'API
  Future<void> loadCategories() async {
    if (isLoadingCategories.value) return;

    isLoadingCategories.value = true;

    try {
      final loadedCategories = await _groupService.getCategories();
      categories.value = loadedCategories;
    } catch (e) {
      print('Error loading categories: $e');
    } finally {
      isLoadingCategories.value = false;
    }
  }

  /// Sélectionner une catégorie et filtrer les groupes
  void selectCategory(int? categoryId) {
    selectedCategoryId.value = categoryId;
    // Recharger les groupes avec le nouveau filtre
    loadDiscoverGroups(refresh: true);
  }

  /// Charger mes groupes depuis l'API
  Future<void> loadMyGroups({bool refresh = false}) async {
    if (refresh) {
      myGroupsCurrentPage = 1;
      myGroups.clear();
    }

    if (isLoadingMyGroups.value || isLoadingMoreMyGroups.value) return;

    refresh ? isLoadingMyGroups.value = true : isLoadingMoreMyGroups.value = true;
    hasErrorMyGroups.value = false;

    try {
      final response = await _groupService.getMyGroups(
        page: myGroupsCurrentPage,
        perPage: 20,
      );

      if (refresh) {
        myGroups.value = response.groups;
      } else {
        myGroups.addAll(response.groups);
      }

      myGroupsCurrentPage = response.meta.currentPage;
      myGroupsLastPage = response.meta.lastPage;
      canLoadMoreMyGroups.value = response.meta.hasMorePages;
    } catch (e) {
      hasErrorMyGroups.value = true;
      errorMessageMyGroups.value = e.toString();
      print('Error loading my groups: $e');
    } finally {
      isLoadingMyGroups.value = false;
      isLoadingMoreMyGroups.value = false;
    }
  }

  /// Charger plus de mes groupes (pagination)
  Future<void> loadMoreMyGroups() async {
    if (canLoadMoreMyGroups.value && !isLoadingMoreMyGroups.value) {
      myGroupsCurrentPage++;
      await loadMyGroups();
    }
  }

  /// Rafraîchir mes groupes
  Future<void> refreshMyGroups() async {
    await loadMyGroups(refresh: true);
  }

  /// Charger les groupes à découvrir depuis l'API
  Future<void> loadDiscoverGroups({bool refresh = false}) async {
    if (refresh) {
      discoverGroupsCurrentPage = 1;
      discoverGroups.clear();
    }

    if (isLoadingDiscoverGroups.value || isLoadingMoreDiscoverGroups.value) return;

    refresh ? isLoadingDiscoverGroups.value = true : isLoadingMoreDiscoverGroups.value = true;
    hasErrorDiscoverGroups.value = false;

    try {
      final response = await _groupService.discoverGroups(
        page: discoverGroupsCurrentPage,
        perPage: 10,
        categoryId: selectedCategoryId.value,
      );

      if (refresh) {
        discoverGroups.value = response.groups;
      } else {
        discoverGroups.addAll(response.groups);
      }

      discoverGroupsCurrentPage = response.meta.currentPage;
      discoverGroupsLastPage = response.meta.lastPage;
      canLoadMoreDiscoverGroups.value = response.meta.hasMorePages;
    } catch (e) {
      hasErrorDiscoverGroups.value = true;
      errorMessageDiscoverGroups.value = e.toString();
      print('Error loading discover groups: $e');
    } finally {
      isLoadingDiscoverGroups.value = false;
      isLoadingMoreDiscoverGroups.value = false;
    }
  }

  /// Charger plus de groupes à découvrir (pagination)
  Future<void> loadMoreDiscoverGroups() async {
    if (canLoadMoreDiscoverGroups.value && !isLoadingMoreDiscoverGroups.value) {
      discoverGroupsCurrentPage++;
      await loadDiscoverGroups();
    }
  }

  /// Rafraîchir les groupes à découvrir
  Future<void> refreshDiscoverGroups() async {
    await loadDiscoverGroups(refresh: true);
  }

  /// Rechercher des groupes avec debounce
  void searchGroups(String query) {
    searchQuery.value = query;

    // Annuler le précédent timer s'il existe
    _searchDebounce?.cancel();

    // Si la recherche est vide, recharger tous les groupes
    if (query.trim().isEmpty) {
      loadDiscoverGroups(refresh: true);
      return;
    }

    // Ajouter un délai de 500ms avant de lancer la recherche
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  /// Effectuer la recherche
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    isSearching.value = true;
    discoverGroupsCurrentPage = 1;
    discoverGroups.clear();
    hasErrorDiscoverGroups.value = false;

    try {
      final response = await _groupService.searchGroups(
        search: query,
        page: 1,
        perPage: 10,
        categoryId: selectedCategoryId.value,
      );

      discoverGroups.value = response.groups;
      discoverGroupsCurrentPage = response.meta.currentPage;
      discoverGroupsLastPage = response.meta.lastPage;
      canLoadMoreDiscoverGroups.value = response.meta.hasMorePages;
    } catch (e) {
      hasErrorDiscoverGroups.value = true;
      errorMessageDiscoverGroups.value = e.toString();
      print('Error searching groups: $e');
    } finally {
      isSearching.value = false;
    }
  }

  /// Rejoindre un groupe public par ID
  Future<bool> joinGroupById(int groupId) async {
    try {
      final joinedGroup = await _groupService.joinGroupById(groupId);

      // Ajouter le groupe aux "Mes groupes"
      myGroups.insert(0, joinedGroup);

      // Mettre à jour le groupe dans la liste discover au lieu de le retirer
      // Cela permet de garder le groupe visible mais avec l'état "membre"
      final index = discoverGroups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        discoverGroups[index] = joinedGroup;
        // Forcer le rafraîchissement de l'UI
        discoverGroups.refresh();
      }

      Get.snackbar(
        'Succès',
        'Vous avez rejoint le groupe avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
        duration: const Duration(seconds: 2),
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de rejoindre le groupe: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 3),
      );
      return false;
    }
  }

  /// Rejoindre un groupe privé par code d'invitation
  Future<bool> joinGroupByCode(String inviteCode) async {
    if (inviteCode.trim().isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez entrer un code d\'invitation',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    }

    try {
      final joinedGroup = await _groupService.joinGroupByCode(inviteCode.trim());

      // Ajouter le groupe aux "Mes groupes"
      myGroups.insert(0, joinedGroup);

      // Mettre à jour le groupe dans la liste discover si présent
      final index = discoverGroups.indexWhere((g) => g.id == joinedGroup.id);
      if (index != -1) {
        discoverGroups[index] = joinedGroup;
        // Forcer le rafraîchissement de l'UI
        discoverGroups.refresh();
      }

      Get.snackbar(
        'Succès',
        'Vous avez rejoint le groupe avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
        duration: const Duration(seconds: 2),
      );

      // Changer de tab pour afficher les groupes rejoints
      selectedTab.value = GroupTab.myGroups;

      return true;
    } catch (e) {
      String errorMessage = 'Impossible de rejoindre le groupe';

      // Parser l'erreur pour afficher un message plus explicite
      if (e.toString().contains('404')) {
        errorMessage = 'Code d\'invitation invalide';
      } else if (e.toString().contains('déjà membre')) {
        errorMessage = 'Vous êtes déjà membre de ce groupe';
      } else if (e.toString().contains('limite')) {
        errorMessage = 'Le groupe a atteint sa limite de membres';
      }

      Get.snackbar(
        'Erreur',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 3),
      );
      return false;
    }
  }

  /// Configurer les listeners WebSocket pour les mises à jour en temps réel
  void _setupRealtimeListeners() {
    try {
      if (_currentUserId == null) {
        print('⚠️ [GroupeController] Cannot setup listeners: user ID is null');
        return;
      }

      // Récupérer ou créer le RealtimeService
      if (!Get.isRegistered<RealtimeService>()) {
        Get.put(RealtimeService());
      }
      _realtimeService = Get.find<RealtimeService>();

      print('🔌 [GroupeController] Setting up WebSocket listeners for user $_currentUserId');

      // S'abonner au canal utilisateur pour recevoir les notifications de tous les groupes
      _realtimeService!.subscribeToPrivateChannel(
        channelName: 'private-user.$_currentUserId',
        onEvent: _handleNewGroupMessage,
      );

      print('✅ [GroupeController] WebSocket listeners configured');
    } catch (e) {
      print('❌ [GroupeController] Error setting up WebSocket: $e');
    }
  }

  /// Gérer la réception d'un nouveau message de groupe
  void _handleNewGroupMessage(Map<String, dynamic> eventData) {
    try {
      // Extraire l'événement
      final event = eventData['_event'] as String?;

      // On s'intéresse uniquement aux messages envoyés
      if (event != 'message.sent') return;

      // Vérifier si c'est un message de groupe
      final groupId = eventData['group_id'] as int?;
      if (groupId == null) return;

      print('📨 [GroupeController] New group message received for group $groupId');

      // Trouver le groupe dans la liste
      final groupIndex = myGroups.indexWhere((g) => g.id == groupId);
      if (groupIndex == -1) {
        // Le groupe n'est pas dans notre liste, recharger
        print('⚠️ [GroupeController] Group $groupId not found in list, reloading...');
        loadMyGroups(refresh: true);
        return;
      }

      final group = myGroups[groupIndex];
      final senderId = eventData['sender_id'] as int?;
      final isOwnMessage = senderId == _currentUserId;

      // Créer un GroupMessageModel pour le dernier message
      final lastMessage = GroupMessageModel(
        id: eventData['id'] as int,
        groupId: groupId,
        senderId: senderId,
        content: eventData['content'] as String?,
        type: _mapStringToMessageType(eventData['type'] as String?),
        mediaUrl: eventData['media_url'] as String?,
        metadata: eventData['metadata'] as Map<String, dynamic>?,
        createdAt: DateTime.parse(eventData['created_at'] as String),
        updatedAt: DateTime.now(),
      );

      // Mettre à jour le groupe avec les nouvelles données
      final updatedGroup = GroupModel(
        id: group.id,
        name: group.name,
        description: group.description,
        categoryId: group.categoryId,
        category: group.category,
        creatorId: group.creatorId,
        inviteCode: group.inviteCode,
        isPublic: group.isPublic,
        maxMembers: group.maxMembers,
        membersCount: group.membersCount,
        lastMessage: lastMessage,
        lastMessageAt: DateTime.now(),
        createdAt: group.createdAt,
        updatedAt: DateTime.now(),
        isCreator: group.isCreator,
        isAdmin: group.isAdmin,
        isMember: group.isMember,
        canJoin: group.canJoin,
        // Incrémenter le count seulement si ce n'est pas notre propre message
        unreadCount: isOwnMessage ? group.unreadCount : group.unreadCount + 1,
      );

      // Remplacer le groupe dans la liste
      myGroups[groupIndex] = updatedGroup;

      // Trier la liste pour mettre le groupe avec le nouveau message en haut
      myGroups.sort((a, b) {
        final aTime = a.lastMessageAt ?? a.createdAt;
        final bTime = b.lastMessageAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

      // Rafraîchir le count global dans le HomeController
      if (Get.isRegistered<HomeController>() && !isOwnMessage) {
        final homeController = Get.find<HomeController>();
        homeController.refreshNotificationCounts();
      }

      print('✅ [GroupeController] Group updated and moved to top');
    } catch (e) {
      print('❌ [GroupeController] Error handling group message: $e');
    }
  }

  /// Mapper le type de message string vers l'enum
  GroupMessageType _mapStringToMessageType(String? type) {
    switch (type) {
      case 'text':
        return GroupMessageType.text;
      case 'audio':
        return GroupMessageType.audio;
      case 'image':
        return GroupMessageType.image;
      case 'video':
        return GroupMessageType.video;
      case 'system':
        return GroupMessageType.system;
      case 'gift':
        return GroupMessageType.gift;
      default:
        return GroupMessageType.text;
    }
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();

    // Unsubscribe du WebSocket
    if (_realtimeService != null && _currentUserId != null) {
      _realtimeService!.unsubscribeFromChannel('private-user.$_currentUserId');
      print('🔌 [GroupeController] Unsubscribed from WebSocket');
    }

    super.onClose();
  }
}
