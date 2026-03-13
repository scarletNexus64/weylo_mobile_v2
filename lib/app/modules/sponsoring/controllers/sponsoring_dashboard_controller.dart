import 'package:get/get.dart';

import '../../../data/core/api_service.dart';
import '../../../data/models/sponsored_ad_model.dart';
import '../../../data/services/sponsorship_service.dart';

class SponsoringDashboardController extends GetxController {
  final _service = SponsorshipService();

  final isLoading = false.obs;
  final errorMessage = RxnString();

  final sponsorships = <SponsoredAdModel>[].obs;

  // Summary (computed)
  final totalDelivered = 0.obs;
  final totalTarget = 0.obs;
  final activeCount = 0.obs;
  final completedCount = 0.obs;

  Future<void> load({bool refresh = false}) async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      // Try dashboard stats first (if API exists)
      Map<String, dynamic>? stats;
      try {
        stats = await _service.getDashboardStats();
      } catch (e) {
        // Optional endpoint: ignore and compute from list.
        stats = null;
      }

      final items = await _service.getMySponsorships(limit: 100);
      sponsorships.value = items;

      if (stats != null && stats.isNotEmpty) {
        totalDelivered.value = (stats['total_delivered'] ?? 0) as int;
        totalTarget.value = (stats['total_target'] ?? 0) as int;
        activeCount.value = (stats['active_count'] ?? 0) as int;
        completedCount.value = (stats['completed_count'] ?? 0) as int;
      } else {
        _computeFrom(items);
      }
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Impossible de charger le dashboard sponsoring';
    } finally {
      isLoading.value = false;
    }
  }

  void _computeFrom(List<SponsoredAdModel> items) {
    totalDelivered.value = items.fold<int>(0, (sum, a) => sum + a.deliveredCount);
    totalTarget.value = items.fold<int>(0, (sum, a) => sum + a.targetReach);
    activeCount.value =
        items.where((a) => (a.status ?? 'active') == 'active').length;
    completedCount.value =
        items.where((a) => (a.status ?? '') == 'completed').length;
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  bool get hasAnySponsorship => sponsorships.isNotEmpty;
}

