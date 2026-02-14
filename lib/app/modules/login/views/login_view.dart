import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:pinput/pinput.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

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
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // Logo Weylo
              Obx(() => AnimatedOpacity(
                opacity: controller.logoOpacity.value,
                duration: const Duration(milliseconds: 500),
                child: Text(
                  'Weylo',
                  style: context.h3.copyWith(
                    color: AppThemeSystem.primaryColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              )),

              const Spacer(flex: 1),

              // Title
              Obx(() => AnimatedOpacity(
                opacity: controller.titleOpacity.value,
                duration: const Duration(milliseconds: 500),
                child: Column(
                  children: [
                    Text(
                      'Connexion',
                      style: context.h2.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Content de vous revoir!',
                      style: context.body2.copyWith(
                        color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )),

              const Spacer(flex: 1),

              // Form
              Obx(() => AnimatedOpacity(
                opacity: controller.formOpacity.value,
                duration: const Duration(milliseconds: 500),
                child: Column(
                  children: [
                    // Phone number field
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

                    const SizedBox(height: 16),

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

                    const SizedBox(height: 12),

                    // Forgot PIN link
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: controller.navigateToForgotPassword,
                        child: Text(
                          'Code PIN oublié?',
                          style: context.caption.copyWith(
                            color: AppThemeSystem.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )),

              const Spacer(flex: 2),

              // Login button
              Obx(() => AnimatedOpacity(
                opacity: controller.buttonOpacity.value,
                duration: const Duration(milliseconds: 500),
                child: Container(
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
                    onPressed: controller.isLoading.value ? null : controller.login,
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
                ),
              )),

              const SizedBox(height: 16),

              // Register link
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

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
