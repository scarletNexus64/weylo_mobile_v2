import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/routes/app_pages.dart';
import 'package:weylo/app/data/services/auth_service.dart';
import 'package:weylo/app/data/core/api_service.dart';

class WelcomerController extends GetxController {
  final _authService = AuthService();
  // Form controllers
  final phoneController = TextEditingController();
  final pinController = TextEditingController();

  // Animation reactive variables
  final logoScale = 0.0.obs;
  final illustrationOpacity = 0.0.obs;
  final titleOpacity = 0.0.obs;
  final formOpacity = 0.0.obs;
  final socialOpacity = 0.0.obs;

  // Form state variables
  final phoneNumber = ''.obs;
  final countryCode = ''.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    print('👋 [WELCOMER] Initialisation du WelcomerController');
    _initAnimations();
  }

  @override
  void onReady() {
    super.onReady();
    print('✨ [WELCOMER] Controller prêt - Lancement des animations');
    _startAnimations();
  }

  @override
  void onClose() {
    phoneController.dispose();
    pinController.dispose();
    super.onClose();
  }

  // Initialize animation values
  void _initAnimations() {
    logoScale.value = 0.0;
    illustrationOpacity.value = 0.0;
    titleOpacity.value = 0.0;
    formOpacity.value = 0.0;
    socialOpacity.value = 0.0;
  }

  // Start sequential animations
  void _startAnimations() async {
    // Animate logo first (quick)
    await Future.delayed(const Duration(milliseconds: 50));
    logoScale.value = 1.0;

    // Then animate illustration (simultaneous with logo)
    await Future.delayed(const Duration(milliseconds: 100));
    illustrationOpacity.value = 1.0;

    // Then animate title (quick)
    await Future.delayed(const Duration(milliseconds: 150));
    titleOpacity.value = 1.0;

    // Then animate form and social together (faster UX)
    await Future.delayed(const Duration(milliseconds: 150));
    formOpacity.value = 1.0;
    socialOpacity.value = 1.0;
  }

  // Update phone number
  void updatePhoneNumber(String phone, String code) {
    phoneNumber.value = phone;
    countryCode.value = code;
  }

  // Sign in with phone and PIN
  Future<void> signInWithPhonePin() async {
    print('🔐 [WELCOMER] Tentative de connexion...');

    if (!_validateForm()) {
      print('❌ [WELCOMER] Validation échouée');
      return;
    }

    try {
      isLoading.value = true;

      final fullPhone = phoneNumber.value;
      final pin = pinController.text;

      print('📱 [WELCOMER] Numéro: $fullPhone');
      print('🔑 [WELCOMER] PIN: ${pin.replaceAll(RegExp(r'.'), '*')}');

      // Call login API
      print('🌐 [WELCOMER] Appel de l\'API login...');
      final response = await _authService.login(
        login: fullPhone,
        password: pin,
      );

      print('✅ [WELCOMER] Connexion réussie!');
      print('👤 [WELCOMER] Utilisateur: ${response.user.username} (${response.user.firstName})');
      print('🔑 [WELCOMER] Token reçu: ${response.token.substring(0, 20)}...');

      Get.snackbar(
        'Succès',
        'Connexion réussie ! Bienvenue ${response.user.firstName}',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      // Navigate to home on success
      print('🏠 [WELCOMER] Navigation vers HOME');
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed(Routes.HOME);

    } on ApiException catch (e) {
      print('💥 [WELCOMER] Erreur API: ${e.message} (Code: ${e.statusCode})');
      Get.snackbar(
        'Erreur',
        e.message,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      print('💥 [WELCOMER] Erreur inattendue: $e');
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue lors de la connexion',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      print('🔓 [WELCOMER] Fin de la tentative de connexion');
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    isLoading.value = true;

    try {
      // TODO: Implement Google Sign In logic here
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      Get.snackbar(
        'Succès',
        'Connexion avec Google réussie!',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Échec de la connexion Google: ${e.toString()}',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Sign in with Facebook
  Future<void> signInWithFacebook() async {
    isLoading.value = true;

    try {
      // TODO: Implement Facebook Sign In logic here
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      Get.snackbar(
        'Succès',
        'Connexion avec Facebook réussie!',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Échec de la connexion Facebook: ${e.toString()}',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Navigate to forgot password
  void navigateToForgotPassword() {
    Get.snackbar(
      'Info',
      'Page de récupération de mot de passe en cours de développement',
      backgroundColor: Colors.blue.withValues(alpha: 0.8),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
    // TODO: Navigate to forgot password page
    // Get.toNamed(Routes.FORGOT_PASSWORD);
  }

  // Navigate to register
  void navigateToRegister() {
    print('📝 [WELCOMER] Navigation vers REGISTER');
    Get.toNamed(Routes.REGISTER);
  }

  // Form validation
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

    if (phoneNumber.value.length < 9) {
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
        'Le code PIN doit contenir au moins 4 chiffres',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    return true;
  }
}
