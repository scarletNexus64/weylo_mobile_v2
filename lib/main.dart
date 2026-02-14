import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'app/routes/app_pages.dart';
import 'app/widgets/app_theme_system.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

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
