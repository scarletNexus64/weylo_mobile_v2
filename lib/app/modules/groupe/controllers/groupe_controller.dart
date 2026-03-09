import 'package:get/get.dart';
import 'package:weylo/app/data/services/group_service.dart';
import 'package:weylo/app/data/models/group_model.dart';

enum GroupTab { myGroups, discover }

class GroupeController extends GetxController {
  final GroupService _groupService = GroupService();

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

  @override
  void onInit() {
    super.onInit();
    loadMyGroups();
  }

  void setTab(GroupTab tab) {
    selectedTab.value = tab;

    // Charger les groupes découverte si pas encore chargés
    if (tab == GroupTab.discover && discoverGroups.isEmpty) {
      loadDiscoverGroups();
    }
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
        perPage: 20,
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
}
