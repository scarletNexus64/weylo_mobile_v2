import 'package:get/get.dart';
import 'package:weylo/app/modules/anonymepage/controllers/anonymepage_controller.dart';
import 'package:weylo/app/modules/chat/controllers/chat_controller.dart';
import 'package:weylo/app/modules/groupe/controllers/groupe_controller.dart';
import 'package:weylo/app/modules/feeds/controllers/feeds_controller.dart';
import 'package:weylo/app/modules/feeds/controllers/story_controller.dart';
import 'package:weylo/app/modules/profile/controllers/profile_controller.dart';

import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    print('🏠 [HomeBinding] Initializing all controllers...');

    // Utiliser put() au lieu de lazyPut() pour garantir que les controllers
    // sont toujours disponibles, même après retour de navigation
    Get.put<HomeController>(
      HomeController(),
      permanent: true,
    );
    print('✅ [HomeBinding] HomeController initialized');

    // Initialize all tab controllers avec put() pour éviter les problèmes de scroll
    Get.put<AnonymepageController>(
      AnonymepageController(),
      permanent: true,
    );
    print('✅ [HomeBinding] AnonymepageController initialized');

    print('🔄 [HomeBinding] Creating ChatController...');
    Get.put<ChatController>(
      ChatController(),
      permanent: true,
    );
    print('✅ [HomeBinding] ChatController initialized');
    Get.put<GroupeController>(
      GroupeController(),
      permanent: true,
    );
    Get.put<ConfessionsController>(
      ConfessionsController(),
      permanent: true,
    );
    // StoryController peut rester en lazyPut car moins critique
    Get.lazyPut<StoryController>(
      () => StoryController(),
    );
    Get.put<ProfileController>(
      ProfileController(),
      permanent: true,
    );
  }
}
