import 'package:get/get.dart';

import '../modules/anonymepage/bindings/anonymepage_binding.dart';
import '../modules/anonymepage/views/anonymepage_view.dart';
import '../modules/chat/bindings/chat_binding.dart';
import '../modules/chat/views/chat_view.dart';
import '../modules/entrypage/bindings/entrypage_binding.dart';
import '../modules/entrypage/views/entrypage_view.dart';
import '../modules/feeds/bindings/feeds_binding.dart';
import '../modules/feeds/views/feeds_view.dart';
import '../modules/feeds/views/create_confession_view.dart';
import '../modules/forgotpassword/bindings/forgotpassword_binding.dart';
import '../modules/forgotpassword/views/forgotpassword_view.dart';
import '../modules/groupe/bindings/groupe_binding.dart';
import '../modules/groupe/views/groupe_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/notification/bindings/notification_binding.dart';
import '../modules/notification/views/notification_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/postannoncement/bindings/postannoncement_binding.dart';
import '../modules/postannoncement/views/postannoncement_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/profile/views/edit_profile_view.dart';
import '../modules/register/bindings/register_binding.dart';
import '../modules/register/views/register_view.dart';
import '../modules/resetpassword/bindings/resetpassword_binding.dart';
import '../modules/resetpassword/views/resetpassword_view.dart';
import '../modules/seeting/bindings/seeting_binding.dart';
import '../modules/seeting/views/seeting_view.dart';
import '../modules/splashscreen/bindings/splashscreen_binding.dart';
import '../modules/splashscreen/views/splashscreen_view.dart';
import '../modules/welcomer/bindings/welcomer_binding.dart';
import '../modules/welcomer/views/welcomer_view.dart';
import '../modules/sendmessage/bindings/sendmessage_binding.dart';
import '../modules/sendmessage/views/sendmessage_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASHSCREEN;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
      children: [
        GetPage(
          name: _Paths.LOGIN,
          page: () => const LoginView(),
          binding: LoginBinding(),
        ),
      ],
    ),
    GetPage(
      name: _Paths.REGISTER,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: _Paths.WELCOMER,
      page: () => const WelcomerView(),
      binding: WelcomerBinding(),
    ),
    GetPage(
      name: _Paths.ONBOARDING,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: _Paths.CHAT,
      page: () => const ChatView(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.EDITPROFILE,
      page: () => const EditProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.SEETING,
      page: () => const SeetingView(),
      binding: SeetingBinding(),
    ),
    GetPage(
      name: _Paths.NOTIFICATION,
      page: () => const NotificationView(),
      binding: NotificationBinding(),
    ),
    GetPage(
      name: _Paths.FEEDS,
      page: () => const ConfessionsView(),
      binding: ConfessionsBinding(),
    ),
    GetPage(
      name: _Paths.ANONYMEPAGE,
      page: () => const AnonymepageView(),
      binding: AnonymepageBinding(),
    ),
    GetPage(
      name: _Paths.FORGOTPASSWORD,
      page: () => const ForgotpasswordView(),
      binding: ForgotpasswordBinding(),
    ),
    GetPage(
      name: _Paths.RESETPASSWORD,
      page: () => const ResetpasswordView(),
      binding: ResetpasswordBinding(),
    ),
    GetPage(
      name: _Paths.POSTANNONCEMENT,
      page: () => const PostannoncementView(),
      binding: PostannoncementBinding(),
    ),
    GetPage(
      name: _Paths.ENTRYPAGE,
      page: () => const EntrypageView(),
      binding: EntrypageBinding(),
    ),
    GetPage(
      name: _Paths.SPLASHSCREEN,
      page: () => const SplashscreenView(),
      binding: SplashscreenBinding(),
    ),
    GetPage(
      name: _Paths.GROUPE,
      page: () => const GroupeView(),
      binding: GroupeBinding(),
    ),
    GetPage(
      name: _Paths.SENDMESSAGE,
      page: () => const SendmessageView(),
      binding: SendmessageBinding(),
    ),
    GetPage(
      name: _Paths.CREATE_CONFESSION,
      page: () => const CreateConfessionView(),
      binding: ConfessionsBinding(),
    ),
  ];
}
