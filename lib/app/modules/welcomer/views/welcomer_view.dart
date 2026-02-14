import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:pinput/pinput.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import '../controllers/welcomer_controller.dart';

class WelcomerView extends GetView<WelcomerController> {
  const WelcomerView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppThemeSystem.darkBackgroundColor : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.horizontalPadding * 1.5,
            vertical: context.verticalPadding * 0.8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo Weylo en haut
              Obx(() => AnimatedOpacity(
                opacity: controller.logoScale.value,
                duration: const Duration(milliseconds: 500),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Weylo',
                      style: context.h5.copyWith(
                        color: AppThemeSystem.primaryColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              )),

              const Spacer(flex: 1),

              // Illustration SVG
              Obx(() => AnimatedOpacity(
                opacity: controller.illustrationOpacity.value,
                duration: const Duration(milliseconds: 500),
                child: SvgPicture.asset(
                  'assets/images/undraw_quick-chat_3gj8.svg',
                  height: MediaQuery.of(context).size.height * 0.18,
                  fit: BoxFit.contain,
                ),
              )),

              const Spacer(flex: 1),

              // Titre "Bon retour"
              Obx(() => AnimatedOpacity(
                opacity: controller.titleOpacity.value,
                duration: const Duration(milliseconds: 500),
                child: Column(
                  children: [
                    Text(
                      'Bon retour',
                      style: context.h2.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Lien d'inscription
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Pas de compte? ",
                          style: context.body2.copyWith(
                            color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                          ),
                        ),
                        GestureDetector(
                          onTap: controller.navigateToRegister,
                          child: Text(
                            "S'inscrire",
                            style: context.body2.copyWith(
                              color: AppThemeSystem.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),

              const Spacer(flex: 1),

              // Formulaire de connexion
              Obx(() => AnimatedOpacity(
                opacity: controller.formOpacity.value,
                duration: const Duration(milliseconds: 500),
                child: Column(
                  children: [
                    // Champ Numéro de téléphone avec country picker
                    IntlPhoneField(
                      controller: controller.phoneController,
                      initialCountryCode: 'CM', // Cameroun par défaut
                      decoration: InputDecoration(
                        hintText: 'Numéro de téléphone',
                        hintStyle: context.body2.copyWith(
                          color: isDark ? AppThemeSystem.grey500 : AppThemeSystem.grey400,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppThemeSystem.grey800.withValues(alpha: 0.3)
                            : AppThemeSystem.grey100.withValues(alpha: 0.7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppThemeSystem.primaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      style: context.body2,
                      dropdownTextStyle: context.body2,
                      onChanged: (phone) {
                        controller.updatePhoneNumber(
                          phone.completeNumber,
                          phone.countryCode,
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Label PIN
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Code PIN',
                          style: context.body2.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppThemeSystem.grey300 : AppThemeSystem.grey700,
                          ),
                        ),
                      ),
                    ),

                    // Champ PIN avec Pinput
                    Pinput(
                      controller: controller.pinController,
                      length: 4,
                      obscureText: true,
                      obscuringCharacter: '●',
                      defaultPinTheme: PinTheme(
                        width: 56,
                        height: 56,
                        textStyle: context.h4.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppThemeSystem.grey800.withValues(alpha: 0.3)
                              : AppThemeSystem.grey100.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                      focusedPinTheme: PinTheme(
                        width: 56,
                        height: 56,
                        textStyle: context.h4.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppThemeSystem.primaryColor,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppThemeSystem.grey800.withValues(alpha: 0.5)
                              : AppThemeSystem.grey100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppThemeSystem.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      submittedPinTheme: PinTheme(
                        width: 56,
                        height: 56,
                        textStyle: context.h4.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppThemeSystem.grey800.withValues(alpha: 0.4)
                              : AppThemeSystem.grey100.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppThemeSystem.primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                      showCursor: true,
                      cursor: Container(
                        width: 2,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppThemeSystem.primaryColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Bouton Se connecter avec effet de dégradé subtil
                    Obx(() => Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: LinearGradient(
                          colors: [
                            AppThemeSystem.primaryColor,
                            AppThemeSystem.secondaryColor,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppThemeSystem.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.signInWithPhonePin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: controller.isLoading.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Se connecter',
                                style: context.button.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    )),

                    const SizedBox(height: 12),

                    // Lien "Mot de passe oublié?"
                    GestureDetector(
                      onTap: controller.navigateToForgotPassword,
                      child: Text(
                        'Code PIN oublié?',
                        style: context.caption.copyWith(
                          color: AppThemeSystem.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )),

              const Spacer(flex: 1),

              // Séparateur "Ou se connecter avec"
              Obx(() => AnimatedOpacity(
                opacity: controller.socialOpacity.value,
                duration: const Duration(milliseconds: 500),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Ou continuer avec',
                            style: context.caption.copyWith(
                              color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Boutons Google et Facebook en cercles
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Bouton Google
                        _buildCircularSocialButton(
                          context: context,
                          isDark: isDark,
                          logoPath: 'assets/images/google.png',
                          onPressed: controller.signInWithGoogle,
                        ),
                        const SizedBox(width: 24),
                        // Bouton Facebook
                        _buildCircularSocialButton(
                          context: context,
                          isDark: isDark,
                          logoPath: 'assets/images/facebook.png',
                          onPressed: controller.signInWithFacebook,
                        ),
                      ],
                    ),
                  ],
                ),
              )),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularSocialButton({
    required BuildContext context,
    required bool isDark,
    required String logoPath,
    required VoidCallback onPressed,
  }) {
    return Obx(() => Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? AppThemeSystem.grey800.withValues(alpha: 0.3) : Colors.white,
        border: Border.all(
          color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : AppThemeSystem.grey400.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: controller.isLoading.value ? null : onPressed,
          borderRadius: BorderRadius.circular(32),
          child: Center(
            child: Image.asset(
              logoPath,
              height: 28,
              width: 28,
            ),
          ),
        ),
      ),
    ));
  }
}
