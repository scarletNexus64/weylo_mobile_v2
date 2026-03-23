import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:pinput/pinput.dart';
import 'package:lottie/lottie.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;

    // Détecter si le clavier est visible
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    // Tailles responsive pour SVG
    final svgHeight = deviceType == DeviceType.mobile
        ? 180.0
        : deviceType == DeviceType.tablet
            ? 220.0
            : 260.0;

    // Tailles responsive pour les boutons PIN
    final pinBoxSize = deviceType == DeviceType.mobile
        ? 56.0
        : deviceType == DeviceType.tablet
            ? 64.0
            : 72.0;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.only(
            left: context.horizontalPadding,
            right: context.horizontalPadding,
            top: isKeyboardVisible ? 8 : context.verticalPadding,
            bottom: isKeyboardVisible ? 8 : context.verticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Back button - Animation 0
              _AnimatedSlideIn(
                delay: 0,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),

              if (!isKeyboardVisible) ...[
                SizedBox(height: context.sectionSpacing * 0.3),

                // Logo/Titre avec étoile - Animation 1
                _AnimatedSlideIn(
                  delay: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Weylo',
                        style: context.h3.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppThemeSystem.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: context.sectionSpacing),

                // Animation Lottie - Animation 2
                _AnimatedFadeScale(
                  delay: 300,
                  child: Lottie.asset(
                    'assets/images/Wavey Birdie.json',
                    height: svgHeight,
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(height: context.sectionSpacing),
              ] else
                SizedBox(height: 8),

              // Titre "Connexion" - Animation 3
              _AnimatedSlideIn(
                delay: 500,
                child: Column(
                  children: [
                    Text(
                      'Connexion',
                      style: context.h1.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: context.elementSpacing * 0.3),
                    Text(
                      'Content de vous revoir!',
                      style: context.body2.copyWith(
                        color: context.secondaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: isKeyboardVisible ? 12 : context.elementSpacing * 0.5),

              // Lien d'inscription - Animation 4
              _AnimatedSlideIn(
                delay: 600,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Pas de compte? ",
                      style: context.body2.copyWith(
                        color: context.secondaryTextColor,
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
              ),

              SizedBox(height: isKeyboardVisible ? 16 : context.sectionSpacing),

              // Champ Numéro de téléphone - Animation 5
              _AnimatedSlideIn(
                delay: 700,
                child: IntlPhoneField(
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
                      borderRadius: context.borderRadius(BorderRadiusType.large),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppThemeSystem.grey700
                            : AppThemeSystem.grey300,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: context.borderRadius(BorderRadiusType.large),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppThemeSystem.grey700
                            : AppThemeSystem.grey300,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: context.borderRadius(BorderRadiusType.large),
                      borderSide: BorderSide(
                        color: AppThemeSystem.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: context.horizontalPadding,
                      vertical: context.elementSpacing,
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
              ),

              SizedBox(height: isKeyboardVisible ? 12 : context.elementSpacing),

              // Label PIN - Animation 6
              _AnimatedSlideIn(
                delay: 800,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: context.elementSpacing * 0.5,
                      bottom: context.elementSpacing * 0.5,
                    ),
                    child: Text(
                      'Code PIN',
                      style: context.body2.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ),
                ),
              ),

              // Champ PIN - Animation 7
              _AnimatedSlideIn(
                delay: 900,
                child: Pinput(
                  controller: controller.pinController,
                  length: 4,
                  obscureText: true,
                  obscuringCharacter: '●',
                  defaultPinTheme: PinTheme(
                    width: pinBoxSize,
                    height: pinBoxSize,
                    textStyle: context.h4.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppThemeSystem.grey800.withValues(alpha: 0.3)
                          : AppThemeSystem.grey100.withValues(alpha: 0.7),
                      borderRadius: context.borderRadius(BorderRadiusType.large),
                      border: Border.all(
                        color: isDark
                            ? AppThemeSystem.grey700
                            : AppThemeSystem.grey300,
                        width: 1,
                      ),
                    ),
                  ),
                  focusedPinTheme: PinTheme(
                    width: pinBoxSize,
                    height: pinBoxSize,
                    textStyle: context.h4.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppThemeSystem.primaryColor,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppThemeSystem.grey800.withValues(alpha: 0.5)
                          : AppThemeSystem.grey100,
                      borderRadius: context.borderRadius(BorderRadiusType.large),
                      border: Border.all(
                        color: AppThemeSystem.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  submittedPinTheme: PinTheme(
                    width: pinBoxSize,
                    height: pinBoxSize,
                    textStyle: context.h4.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppThemeSystem.grey800.withValues(alpha: 0.4)
                          : AppThemeSystem.grey100.withValues(alpha: 0.8),
                      borderRadius: context.borderRadius(BorderRadiusType.large),
                      border: Border.all(
                        color: isDark
                            ? AppThemeSystem.grey700
                            : AppThemeSystem.grey300,
                        width: 1,
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
              ),

              SizedBox(height: isKeyboardVisible ? 16 : context.sectionSpacing * 0.8),

              // Bouton Se connecter - Animation 8
              _AnimatedSlideIn(
                delay: 1000,
                child: Obx(() => Container(
                      width: double.infinity,
                      height: context.buttonHeight,
                      decoration: BoxDecoration(
                        borderRadius: context.borderRadius(BorderRadiusType.circular),
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
                            : controller.login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: context.borderRadius(BorderRadiusType.circular),
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
              ),

              SizedBox(height: isKeyboardVisible ? 8 : context.elementSpacing),

              // Lien "Code PIN oublié?" - Animation 9
              _AnimatedSlideIn(
                delay: 1100,
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

              SizedBox(height: isKeyboardVisible ? 16 : context.sectionSpacing),

              // // Séparateur - Animation 10
              // _AnimatedFadeScale(
              //   delay: 1200,
              //   child: Row(
              //     children: [
              //       Expanded(
              //         child: Container(
              //           height: 1,
              //           color: context.borderColor,
              //         ),
              //       ),
              //       Padding(
              //         padding: EdgeInsets.symmetric(
              //           horizontal: context.elementSpacing,
              //         ),
              //         child: Text(
              //           'Ou continuer avec',
              //           style: context.caption.copyWith(
              //             color: context.secondaryTextColor,
              //           ),
              //         ),
              //       ),
              //       Expanded(
              //         child: Container(
              //           height: 1,
              //           color: context.borderColor,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              // SizedBox(height: context.sectionSpacing * 0.8),

              // // Boutons sociaux - Animation 11
              // _AnimatedSlideIn(
              //   delay: 1300,
              //   child: _buildSocialButton(
              //     context: context,
              //     isDark: isDark,
              //     logoPath: 'assets/images/google.png',
              //     label: 'Google',
              //     onPressed: controller.signInWithGoogle,
              //   ),
              // ),

              SizedBox(height: context.sectionSpacing),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildSocialButton({
  //   required BuildContext context,
  //   required bool isDark,
  //   required String logoPath,
  //   required String label,
  //   required VoidCallback onPressed,
  // }) {
  //   return Obx(() => Container(
  //         width: double.infinity,
  //         height: context.buttonHeight * 0.9,
  //         decoration: BoxDecoration(
  //           color: context.surfaceColor,
  //           border: Border.all(
  //             color: context.borderColor,
  //             width: 1.5,
  //           ),
  //           borderRadius: context.borderRadius(BorderRadiusType.medium),
  //           boxShadow: [
  //             BoxShadow(
  //               color: isDark
  //                   ? Colors.black.withValues(alpha: 0.2)
  //                   : AppThemeSystem.grey400.withValues(alpha: 0.15),
  //               blurRadius: 8,
  //               offset: const Offset(0, 2),
  //             ),
  //           ],
  //         ),
  //         child: Material(
  //           color: Colors.transparent,
  //           child: InkWell(
  //             onTap: controller.isLoading.value ? null : onPressed,
  //             borderRadius: context.borderRadius(BorderRadiusType.medium),
  //             child: Row(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Image.asset(
  //                   logoPath,
  //                   height: 24,
  //                   width: 24,
  //                 ),
  //                 SizedBox(width: context.elementSpacing * 0.5),
  //                 Text(
  //                   label,
  //                   style: context.body2.copyWith(
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ));
  // }

}

/// Widget d'animation Slide In depuis le bas avec fade
class _AnimatedSlideIn extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedSlideIn({
    required this.child,
    this.delay = 0,
  });

  @override
  State<_AnimatedSlideIn> createState() => _AnimatedSlideInState();
}

class _AnimatedSlideInState extends State<_AnimatedSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Widget d'animation Fade avec Scale
class _AnimatedFadeScale extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedFadeScale({
    required this.child,
    this.delay = 0,
  });

  @override
  State<_AnimatedFadeScale> createState() => _AnimatedFadeScaleState();
}

class _AnimatedFadeScaleState extends State<_AnimatedFadeScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
