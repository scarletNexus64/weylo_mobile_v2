import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/routes/app_pages.dart';
import 'package:weylo/app/data/services/auth_service.dart';
import 'package:weylo/app/data/services/legal_service.dart';
import 'package:weylo/app/data/core/api_service.dart';
import 'package:weylo/app/data/models/legal_page_model.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import '../views/legal_page_detail_view.dart';

class RegisterController extends GetxController {
  final _authService = AuthService();
  final _legalService = LegalService();

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

  // Legal pages
  final legalPages = <LegalPageModel>[].obs;
  final isLoadingLegalPages = true.obs;
  final acceptedTerms = false.obs;

  // Animation variables for each step
  final step1Opacity = 0.0.obs;
  final step2Opacity = 0.0.obs;
  final step3Opacity = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    print('📝 [REGISTER] Initialisation du RegisterController');
    _loadLegalPages();
    _animateCurrentStep();
  }

  // Load legal pages
  Future<void> _loadLegalPages() async {
    print('📄 [REGISTER] Chargement des pages légales...');
    try {
      isLoadingLegalPages.value = true;
      final pages = await _legalService.getLegalPages();
      legalPages.value = pages;
      print('✅ [REGISTER] ${pages.length} pages légales chargées');
    } catch (e) {
      print('💥 [REGISTER] Erreur lors du chargement des pages légales: $e');
      Get.snackbar(
        'Attention',
        'Impossible de charger les conditions d\'utilisation. Veuillez réessayer.',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingLegalPages.value = false;
    }
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

    // Vérifier l'acceptation des CGU
    if (!acceptedTerms.value) {
      Get.snackbar(
        'Erreur',
        'Veuillez accepter les conditions d\'utilisation pour continuer',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    return true;
  }

  // Toggle terms acceptance
  void toggleTermsAcceptance(bool? value) {
    acceptedTerms.value = value ?? false;
    print('📄 [REGISTER] CGU acceptées: ${acceptedTerms.value}');
  }

  // Show legal pages bottom sheet
  void showLegalPagesBottomSheet() {
    print('📄 [REGISTER] Ouverture du bottom sheet des pages légales');

    Get.bottomSheet(
      Container(
        height: Get.height * 0.75,
        decoration: BoxDecoration(
          color: Get.isDarkMode ? AppThemeSystem.grey900 : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Get.isDarkMode
                    ? AppThemeSystem.grey700
                    : AppThemeSystem.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.article_outlined,
                    color: AppThemeSystem.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Documents légaux',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Get.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(
                      Icons.close,
                      color: Get.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // List of legal pages
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: legalPages.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  indent: 72,
                ),
                itemBuilder: (context, index) {
                  final page = legalPages[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppThemeSystem.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: AppThemeSystem.primaryColor,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      page.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Get.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Get.isDarkMode
                          ? AppThemeSystem.grey500
                          : AppThemeSystem.grey600,
                    ),
                    onTap: () => _openLegalPageDetail(page),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
    );
  }

  // Open legal page detail
  Future<void> _openLegalPageDetail(LegalPageModel page) async {
    print('📄 [REGISTER] Ouverture de la page: ${page.title}');

    // Show loading dialog
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: false,
    );

    try {
      // Load full page content
      final fullPage = await _legalService.getLegalPage(page.slug);

      // Close loading dialog
      Get.back();

      // Show content page
      Get.to(
        () => LegalPageDetailView(page: fullPage),
        transition: Transition.rightToLeft,
      );
    } catch (e) {
      // Close loading dialog
      Get.back();

      // Show error
      Get.snackbar(
        'Erreur',
        'Impossible de charger la page. Veuillez réessayer.',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      print('💥 [REGISTER] Erreur lors du chargement de la page: $e');
    }
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
