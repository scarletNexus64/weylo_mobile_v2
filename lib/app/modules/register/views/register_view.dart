import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:pinput/pinput.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import '../controllers/register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppThemeSystem.darkBackgroundColor : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and progress
            _buildHeader(context, isDark),

            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.horizontalPadding * 1.5,
                  vertical: context.verticalPadding,
                ),
                child: Column(
                  children: [
                    // Step indicator
                    _buildStepIndicator(context, isDark),

                    const SizedBox(height: 32),

                    // Title and subtitle
                    Obx(() => Column(
                      children: [
                        Text(
                          controller.getStepTitle(),
                          style: context.h2.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller.getStepSubtitle(),
                          style: context.body2.copyWith(
                            color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )),

                    const SizedBox(height: 40),

                    // Step content
                    Expanded(
                      child: Obx(() {
                        switch (controller.currentStep.value) {
                          case 0:
                            return _buildStep1(context, isDark);
                          case 1:
                            return _buildStep2(context, isDark);
                          case 2:
                            return _buildStep3(context, isDark);
                          default:
                            return Container();
                        }
                      }),
                    ),

                    // Navigation buttons
                    _buildNavigationButtons(context, isDark),

                    const SizedBox(height: 16),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Déjà inscrit? ",
                          style: context.body2.copyWith(
                            color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                          ),
                        ),
                        GestureDetector(
                          onTap: controller.navigateToLogin,
                          child: Text(
                            "Se connecter",
                            style: context.body2.copyWith(
                              color: AppThemeSystem.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.all(context.horizontalPadding),
      child: Row(
        children: [
          // Back button
          Obx(() => controller.currentStep.value > 0
              ? IconButton(
                  onPressed: controller.previousStep,
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                )
              : IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                )),
          const Spacer(),
          // Logo
          Text(
            'Weylo',
            style: context.h5.copyWith(
              color: AppThemeSystem.primaryColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance for back button
        ],
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context, bool isDark) {
    return Obx(() => Row(
      children: List.generate(3, (index) {
        final isActive = index == controller.currentStep.value;
        final isCompleted = index < controller.currentStep.value;

        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: isActive || isCompleted
                  ? LinearGradient(
                      colors: [
                        AppThemeSystem.primaryColor,
                        AppThemeSystem.secondaryColor,
                      ],
                    )
                  : null,
              color: isActive || isCompleted
                  ? null
                  : isDark
                      ? AppThemeSystem.grey800
                      : AppThemeSystem.grey200,
            ),
          ),
        );
      }),
    ));
  }

  // Step 1: Username
  Widget _buildStep1(BuildContext context, bool isDark) {
    return Obx(() => AnimatedOpacity(
      opacity: controller.step1Opacity.value,
      duration: const Duration(milliseconds: 300),
      child: Column(
        children: [
          // Username icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppThemeSystem.primaryColor.withValues(alpha: 0.2),
                  AppThemeSystem.secondaryColor.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: Icon(
              Icons.person_outline,
              size: 40,
              color: AppThemeSystem.primaryColor,
            ),
          ),

          const SizedBox(height: 32),

          // Username input
          TextField(
            controller: controller.usernameController,
            style: context.body1,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Entrez votre nom d\'utilisateur',
              hintStyle: context.body1.copyWith(
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
                horizontal: 20,
                vertical: 18,
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
            ],
          ),

          const SizedBox(height: 12),

          // Helper text
          Text(
            'Lettres, chiffres et underscores uniquement',
            style: context.caption.copyWith(
              color: isDark ? AppThemeSystem.grey500 : AppThemeSystem.grey500,
            ),
          ),

          const Spacer(),
        ],
      ),
    ));
  }

  // Step 2: Phone number
  Widget _buildStep2(BuildContext context, bool isDark) {
    return Obx(() => AnimatedOpacity(
      opacity: controller.step2Opacity.value,
      duration: const Duration(milliseconds: 300),
      child: Column(
        children: [
          // Phone icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppThemeSystem.primaryColor.withValues(alpha: 0.2),
                  AppThemeSystem.secondaryColor.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: Icon(
              Icons.phone_outlined,
              size: 40,
              color: AppThemeSystem.primaryColor,
            ),
          ),

          const SizedBox(height: 32),

          // Phone input
          IntlPhoneField(
            controller: controller.phoneController,
            initialCountryCode: 'CM',
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

          const Spacer(),
        ],
      ),
    ));
  }

  // Step 3: PIN
  Widget _buildStep3(BuildContext context, bool isDark) {
    return Obx(() => AnimatedOpacity(
      opacity: controller.step3Opacity.value,
      duration: const Duration(milliseconds: 300),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Lock icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppThemeSystem.primaryColor.withValues(alpha: 0.2),
                    AppThemeSystem.secondaryColor.withValues(alpha: 0.2),
                  ],
                ),
              ),
              child: Icon(
                Icons.lock_outline,
                size: 40,
                color: AppThemeSystem.primaryColor,
              ),
            ),

            const SizedBox(height: 32),

            // PIN label
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

            // PIN input
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
                  border: Border.all(color: Colors.transparent),
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

            // Confirm PIN label
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Confirmer le code PIN',
                  style: context.body2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppThemeSystem.grey300 : AppThemeSystem.grey700,
                  ),
                ),
              ),
            ),

            // Confirm PIN input
            Pinput(
              controller: controller.confirmPinController,
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
                  border: Border.all(color: Colors.transparent),
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

            const SizedBox(height: 12),

            // Helper text
            Text(
              'Le code PIN doit contenir 4 chiffres',
              style: context.caption.copyWith(
                color: isDark ? AppThemeSystem.grey500 : AppThemeSystem.grey500,
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildNavigationButtons(BuildContext context, bool isDark) {
    return Obx(() => Container(
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
        onPressed: controller.isLoading.value ? null : controller.nextStep,
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
                controller.currentStep.value < 2 ? 'Continuer' : 'Créer mon compte',
                style: context.button.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    ));
  }
}
