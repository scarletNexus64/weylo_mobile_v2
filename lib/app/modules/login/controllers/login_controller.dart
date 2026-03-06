import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/routes/app_pages.dart';
import 'package:weylo/app/data/services/auth_service.dart';
import 'package:weylo/app/data/core/api_service.dart';

class LoginController extends GetxController {
  final _authService = AuthService();
  // Text controllers
  final phoneController = TextEditingController();
  final pinController = TextEditingController();

  // Observable variables
  final isLoading = false.obs;
  final phoneNumber = ''.obs;
  final countryCode = 'CM'.obs;
  final countryDialCode = '+237'.obs;

  // Animation variables
  final logoOpacity = 0.0.obs;
  final titleOpacity = 0.0.obs;
  final formOpacity = 0.0.obs;
  final buttonOpacity = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    print('🔐 [LOGIN] Initialisation du LoginController');
    _startAnimations();
  }

  @override
  void onClose() {
    phoneController.dispose();
    pinController.dispose();
    super.onClose();
  }

  // Start animations
  void _startAnimations() async {
    // Animate logo
    await Future.delayed(const Duration(milliseconds: 100));
    logoOpacity.value = 1.0;

    // Animate title
    await Future.delayed(const Duration(milliseconds: 300));
    titleOpacity.value = 1.0;

    // Animate form
    await Future.delayed(const Duration(milliseconds: 300));
    formOpacity.value = 1.0;

    // Animate button
    await Future.delayed(const Duration(milliseconds: 300));
    buttonOpacity.value = 1.0;
  }

  // Update phone number
  void updatePhoneNumber(String phone, String code) {
    phoneNumber.value = phone;
    countryCode.value = code;
  }

  // Login method
  Future<void> login() async {
    print('🔐 [LOGIN] Tentative de connexion...');

    if (!_validateForm()) {
      print('❌ [LOGIN] Validation échouée');
      return;
    }

    try {
      isLoading.value = true;

      final fullPhone = phoneNumber.value;
      final pin = pinController.text;

      print('📱 [LOGIN] Numéro: $fullPhone');
      print('🔑 [LOGIN] PIN: ${pin.replaceAll(RegExp(r'.'), '*')}');

      // Call login API
      print('🌐 [LOGIN] Appel de l\'API login...');
      final response = await _authService.login(
        login: fullPhone,
        password: pin,
      );

      print('✅ [LOGIN] Connexion réussie!');
      print('👤 [LOGIN] Utilisateur: ${response.user.username} (${response.user.firstName})');
      print('🔑 [LOGIN] Token reçu: ${response.token.substring(0, 20)}...');

      Get.snackbar(
        'Succès',
        'Connexion réussie ! Bienvenue ${response.user.firstName}',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      // Navigate to home on success
      print('🏠 [LOGIN] Navigation vers HOME');
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed(Routes.HOME);

    } on ApiException catch (e) {
      print('💥 [LOGIN] Erreur API: ${e.message} (Code: ${e.statusCode})');
      Get.snackbar(
        'Erreur',
        e.message,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      print('💥 [LOGIN] Erreur inattendue: $e');
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue lors de la connexion',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      print('🔓 [LOGIN] Fin de la tentative de connexion');
    }
  }

  // Validate form
  bool _validateForm() {
    if (phoneNumber.value.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez entrer votre numéro de téléphone',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (phoneController.text.length < 9) {
      Get.snackbar(
        'Erreur',
        'Veuillez entrer un numéro de téléphone valide',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (pinController.text.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez entrer votre code PIN',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (pinController.text.length < 4) {
      Get.snackbar(
        'Erreur',
        'Le code PIN doit contenir 4 chiffres',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    return true;
  }

  // Navigate to register
  void navigateToRegister() {
    print('📝 [LOGIN] Navigation vers REGISTER');
    Get.toNamed(Routes.REGISTER);
  }

  // Navigate to forgot password
  void navigateToForgotPassword() {
    Get.snackbar(
      'Info',
      'Page de récupération de code PIN en cours de développement',
      backgroundColor: Colors.blue.withValues(alpha: 0.8),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
    // TODO: Navigate to forgot password page
    // Get.toNamed(Routes.FORGOTPASSWORD);
  }

  // Sign in with Google
  void signInWithGoogle() {
    Get.snackbar(
      'Info',
      'Connexion Google en cours de développement',
      backgroundColor: Colors.blue.withValues(alpha: 0.8),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
    // TODO: Implement Google sign in
  }

  // Sign in with Facebook
  void signInWithFacebook() {
    Get.snackbar(
      'Info',
      'Connexion Facebook en cours de développement',
      backgroundColor: Colors.blue.withValues(alpha: 0.8),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
    // TODO: Implement Facebook sign in
  }
}
