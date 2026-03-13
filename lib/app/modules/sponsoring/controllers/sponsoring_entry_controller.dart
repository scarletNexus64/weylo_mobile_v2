import 'package:get/get.dart';

import '../../../data/core/api_service.dart';
import '../../../data/services/sponsorship_service.dart';
import '../views/sponsoring_dashboard_view.dart';
import '../views/sponsoring_view.dart';

class SponsoringEntryController extends GetxController {
  final _service = SponsorshipService();

  final isLoading = true.obs;
  final errorMessage = RxnString();
  final hasSponsorships = false.obs;

  Future<void> check() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final mine = await _service.getMySponsorships(limit: 1);
      hasSponsorships.value = mine.isNotEmpty;
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Impossible de vérifier vos contenus sponsoring';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> bootstrap() async {
    await check();
    if (errorMessage.value != null) return;

    if (hasSponsorships.value) {
      Get.off(() => const SponsoringDashboardView());
    } else {
      Get.off(() => const SponsoringView());
    }
  }

  @override
  void onReady() {
    super.onReady();
    bootstrap();
  }
}
