import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/routes/app_pages.dart';
import 'package:weylo/app/data/services/auth_service.dart';
import 'package:weylo/app/data/core/api_service.dart';

class RegisterController extends GetxController {
  final _authService = AuthService();
  // Current step
  final currentStep = 0.obs;

  // Text controllers
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();

  // Observable variables
  final isLoading = false.obs;
  final phoneNumber = ''.obs;
  final countryCode = 'CM'.obs;
  final countryDialCode = '+237'.obs;

  // Animation variables for each step
  final step1Opacity = 0.0.obs;
  final step2Opacity = 0.0.obs;
  final step3Opacity = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    print('📝 [REGISTER] Initialisation du RegisterController');
    _animateCurrentStep();
  }

  @override
  void onClose() {
    usernameController.dispose();
    phoneController.dispose();
    pinController.dispose();
    confirmPinController.dispose();
    super.onClose();
  }

  // Animate current step entrance
  void _animateCurrentStep() async {
    await Future.delayed(const Duration(milliseconds: 200));
    switch (currentStep.value) {
      case 0:
        step1Opacity.value = 1.0;
        break;
      case 1:
        step2Opacity.value = 1.0;
        break;
      case 2:
        step3Opacity.value = 1.0;
        break;
    }
  }

  // Go to next step
  void nextStep() async {
    print('➡️ [REGISTER] Passage à l\'étape suivante (actuelle: ${currentStep.value})');

    if (currentStep.value < 2) {
      if (_validateCurrentStep()) {
        print('✅ [REGISTER] Validation de l\'étape ${currentStep.value} réussie');
        // Fade out current step
        switch (currentStep.value) {
          case 0:
            step1Opacity.value = 0.0;
            print('👤 [REGISTER] Nom d\'utilisateur validé: ${usernameController.text}');
            break;
          case 1:
            step2Opacity.value = 0.0;
            print('📱 [REGISTER] Téléphone validé: ${phoneNumber.value}');
            break;
        }

        await Future.delayed(const Duration(milliseconds: 300));
        currentStep.value++;
        print('📍 [REGISTER] Nouvelle étape: ${currentStep.value}');
        _animateCurrentStep();
      } else {
        print('❌ [REGISTER] Validation de l\'étape ${currentStep.value} échouée');
      }
    } else {
      // Last step - register
      print('🎯 [REGISTER] Dernière étape - Lancement de l\'inscription');
      register();
    }
  }

  // Go to previous step
  void previousStep() async {
    if (currentStep.value > 0) {
      // Fade out current step
      switch (currentStep.value) {
        case 1:
          step2Opacity.value = 0.0;
          break;
        case 2:
          step3Opacity.value = 0.0;
          break;
      }

      await Future.delayed(const Duration(milliseconds: 300));
      currentStep.value--;
      _animateCurrentStep();
    }
  }

  // Validate current step
  bool _validateCurrentStep() {
    switch (currentStep.value) {
      case 0:
        return _validateUsername();
      case 1:
        return _validatePhone();
      case 2:
        return _validatePins();
      default:
        return false;
    }
  }

  // Validate username
  bool _validateUsername() {
    final username = usernameController.text.trim();

    if (username.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez entrer votre nom d\'utilisateur',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (username.length < 3) {
      Get.snackbar(
        'Erreur',
        'Le nom d\'utilisateur doit contenir au moins 3 caractères',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      Get.snackbar(
        'Erreur',
        'Le nom d\'utilisateur ne peut contenir que des lettres, chiffres et underscores',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    return true;
  }

  // Validate phone
  bool _validatePhone() {
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

    return true;
  }

  // Validate PINs
  bool _validatePins() {
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

    if (confirmPinController.text.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez confirmer votre code PIN',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (pinController.text != confirmPinController.text) {
      Get.snackbar(
        'Erreur',
        'Les codes PIN ne correspondent pas',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    return true;
  }

  // Update phone number
  void updatePhoneNumber(String phone, String code) {
    phoneNumber.value = phone;
    countryCode.value = code;
  }

  // Register method
  Future<void> register() async {
    print('📝 [REGISTER] Début de l\'inscription...');

    if (!_validatePins()) {
      print('❌ [REGISTER] Validation des PINs échouée');
      return;
    }

    try {
      isLoading.value = true;

      final firstName = usernameController.text.trim();
      final fullPhone = phoneNumber.value;
      final pin = pinController.text;

      print('👤 [REGISTER] Prénom: $firstName');
      print('📱 [REGISTER] Téléphone: $fullPhone');
      print('🔑 [REGISTER] PIN: ${pin.replaceAll(RegExp(r'.'), '*')}');

      // Call register API with saveToStorage = true for auto-login
      print('🌐 [REGISTER] Appel de l\'API register...');
      final response = await _authService.register(
        firstName: firstName,
        phone: fullPhone,
        password: pin,
        saveToStorage: true, // Auto-login: sauvegarder le token et l'utilisateur
      );

      print('✅ [REGISTER] Inscription réussie!');
      print('🆔 [REGISTER] ID utilisateur: ${response.user.id}');
      print('👤 [REGISTER] Username généré: ${response.user.username}');
      print('📧 [REGISTER] Email: ${response.user.email}');
      print('📱 [REGISTER] Téléphone: ${response.user.phone}');
      print('🔑 [REGISTER] Token reçu: ${response.token.substring(0, 20)}...');
      print('💾 [REGISTER] Données sauvegardées localement (auto-login)');

      Get.snackbar(
        'Succès',
        'Inscription réussie ! Bienvenue ${response.user.firstName}',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      // Navigate to HOME after success (user is now logged in)
      print('🏠 [REGISTER] Navigation vers HOME (utilisateur connecté)');
      await Future.delayed(const Duration(milliseconds: 800));
      Get.offAllNamed(Routes.HOME);

    } on ApiException catch (e) {
      print('💥 [REGISTER] Erreur API: ${e.message} (Code: ${e.statusCode})');
      Get.snackbar(
        'Erreur',
        e.message,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      print('💥 [REGISTER] Erreur inattendue: $e');
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue lors de l\'inscription',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      print('🔓 [REGISTER] Fin de la tentative d\'inscription');
    }
  }

  // Navigate to login
  void navigateToLogin() {
    print('🔐 [REGISTER] Navigation vers LOGIN');
    Get.back();
  }

  // Get step title
  String getStepTitle() {
    switch (currentStep.value) {
      case 0:
        return 'Nom d\'utilisateur';
      case 1:
        return 'Numéro de téléphone';
      case 2:
        return 'Code PIN';
      default:
        return '';
    }
  }

  // Get step subtitle
  String getStepSubtitle() {
    switch (currentStep.value) {
      case 0:
        return 'Choisissez votre identifiant unique';
      case 1:
        return 'Entrez votre numéro de téléphone';
      case 2:
        return 'Sécurisez votre compte';
      default:
        return '';
    }
  }
}
