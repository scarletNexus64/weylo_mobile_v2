import 'package:get/get.dart';
import 'package:weylo/app/modules/anonymepage/controllers/anonymepage_controller.dart';
import 'package:weylo/app/modules/chat/controllers/chat_controller.dart';
import 'package:weylo/app/modules/groupe/controllers/groupe_controller.dart';
import 'package:weylo/app/modules/feeds/controllers/feeds_controller.dart';
import 'package:weylo/app/modules/profile/controllers/profile_controller.dart';

import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(
      () => HomeController(),
    );

    // Initialize all tab controllers
    Get.lazyPut<AnonymepageController>(
      () => AnonymepageController(),
    );
    Get.lazyPut<ChatController>(
      () => ChatController(),
    );
    Get.lazyPut<GroupeController>(
      () => GroupeController(),
    );
    Get.lazyPut<ConfessionsController>(
      () => ConfessionsController(),
    );
    Get.lazyPut<ProfileController>(
      () => ProfileController(),
    );
  }
}
