import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'app/routes/app_pages.dart';
import 'app/widgets/app_theme_system.dart';
import 'app/data/services/storage_service.dart';
import 'app/data/core/api_service.dart';
import 'app/data/services/deeplink_service.dart';
import 'app/data/services/conversation_state_service.dart';
import 'app/data/services/auth_service.dart';

void main() async {
  print('🚀 [MAIN] Démarrage de l\'application Weylo');
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service
  print('💾 [MAIN] Initialisation du StorageService...');
  await StorageService.init();
  print('✅ [MAIN] StorageService initialisé');

  // Initialize API service
  print('🌐 [MAIN] Initialisation de l\'ApiService...');
  ApiService().init();
  print('✅ [MAIN] ApiService initialisé');

  // Initialize Deeplink service
  print('🔗 [MAIN] Initialisation du DeeplinkService...');
  await DeeplinkService().init();
  print('✅ [MAIN] DeeplinkService initialisé');

  // Initialize ConversationStateService (global) si l'utilisateur est connecté
  print('💬 [MAIN] Vérification de l\'authentification...');
  final authService = AuthService();
  final currentUser = authService.getCurrentUser();

  if (currentUser != null) {
    print('✅ [MAIN] Utilisateur connecté: ${currentUser.username}');
    print('💬 [MAIN] Initialisation du ConversationStateService...');

    // Initialiser le service global de manière asynchrone
    await Get.putAsync(() async {
      final service = ConversationStateService();
      await service.onInit();
      return service;
    }, permanent: true);

    print('✅ [MAIN] ConversationStateService initialisé');
  } else {
    print('⚠️ [MAIN] Utilisateur non connecté, ConversationStateService non initialisé');
  }

  // Configuration de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  print('🎨 [MAIN] Lancement de l\'interface...');
  runApp(const WeyloApp());
}

class WeyloApp extends StatelessWidget {
  const WeyloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "Weylo",
      debugShowCheckedModeBanner: false,

      // Configuration des thèmes avec AppThemeSystem
      theme: AppThemeSystem.getLightTheme(),
      darkTheme: AppThemeSystem.getDarkTheme(),
      themeMode: ThemeMode.system, // Suit le mode système

      // Configuration de la navigation
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,

      // Transitions par défaut
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
