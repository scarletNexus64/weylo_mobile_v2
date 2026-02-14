import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Particules flottantes
          ..._buildFloatingParticles(),

          // Contenu principal
          SafeArea(
            child: Column(
              children: [
                // Header avec bouton Skip
                _buildHeader(context),

                // PageView avec les slides
                Expanded(
                  child: PageView.builder(
                    controller: controller.pageController,
                    onPageChanged: controller.onPageChanged,
                    itemCount: controller.pages.length,
                    itemBuilder: (context, index) {
                      return _OnboardingPage(
                        page: controller.pages[index],
                        index: index,
                        pageProgress: controller.pageProgress,
                      );
                    },
                  ),
                ),

                // Footer avec indicators et boutons
                _buildFooter(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.horizontalPadding,
        vertical: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Obx(() => controller.currentPage.value < controller.pages.length - 1
              ? TextButton(
                  onPressed: controller.skip,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    'Passer',
                    style: context.textStyle(FontSizeType.body1).copyWith(
                      color: AppThemeSystem.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: context.horizontalPadding,
        right: context.horizontalPadding,
        bottom: context.verticalPadding + 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator moderne
          Obx(() => _ModernProgressIndicator(
                currentPage: controller.currentPage.value,
                totalPages: controller.pages.length,
                pages: controller.pages,
              )),

          SizedBox(height: context.elementSpacing * 2),

          // Bouton de navigation
          Obx(() => controller.currentPage.value == controller.pages.length - 1
              ? _buildStartButton(context)
              : _buildNextButton(context)),
        ],
      ),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    return _AnimatedGradientButton(
      onPressed: controller.nextPage,
      text: 'Suivant',
      icon: Icons.arrow_forward_rounded,
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return _AnimatedGradientButton(
      onPressed: controller.finish,
      text: 'Commencer l\'aventure',
      icon: Icons.rocket_launch_rounded,
      isPrimary: true,
    );
  }

  List<Widget> _buildFloatingParticles() {
    return List.generate(12, (index) {
      return _FloatingParticle(
        index: index,
        duration: Duration(milliseconds: 4000 + (index * 300)),
      );
    });
  }
}

// ================================
// FLOATING PARTICLES
// ================================
class _FloatingParticle extends StatefulWidget {
  final int index;
  final Duration duration;

  const _FloatingParticle({
    required this.index,
    required this.duration,
  });

  @override
  State<_FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double left;
  late double size;
  late Color color;

  @override
  void initState() {
    super.initState();
    final random = math.Random(widget.index);
    left = random.nextDouble();
    size = 3 + random.nextDouble() * 8;

    final colors = [
      AppThemeSystem.primaryColor,
      AppThemeSystem.secondaryColor,
      AppThemeSystem.tertiaryColor,
    ];
    color = colors[random.nextInt(colors.length)].withValues(alpha: 0.2);

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: left * screenWidth,
          top: _controller.value * screenHeight,
          child: Opacity(
            opacity: (math.sin(_controller.value * math.pi) * 0.4 + 0.4),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: size * 1.5,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ================================
// ONBOARDING PAGE CONTENT
// ================================
class _OnboardingPage extends StatelessWidget {
  final OnboardingPageModel page;
  final int index;
  final RxDouble pageProgress;

  const _OnboardingPage({
    required this.page,
    required this.index,
    required this.pageProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),

          // Illustration visuelle moderne
          Obx(() {
            final progress = (pageProgress.value - index).clamp(-1.0, 1.0);
            final scale = 1.0 - (progress.abs() * 0.3);
            final opacity = 1.0 - (progress.abs() * 0.5);

            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: _ModernIllustration(page: page),
              ),
            );
          }),

          SizedBox(height: context.elementSpacing),

          // Title (grand titre)
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 700),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        page.primaryColor,
                        page.secondaryColor,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      page.title,
                      style: context.h1.copyWith(
                        fontSize: context.deviceType == DeviceType.mobile ? 32 : 42,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),

          SizedBox(height: context.elementSpacing * 1.5),

          // Description
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 900),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.deviceType == DeviceType.mobile ? 10 : 40,
                    ),
                    child: Text(
                      page.description,
                      style: context.body1.copyWith(
                        color: context.secondaryTextColor,
                        height: 1.7,
                        fontSize: context.deviceType == DeviceType.mobile ? 15 : 17,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),

          const Spacer(flex: 1),
        ],
      ),
    );
  }
}

// ================================
// MODERN ILLUSTRATION
// ================================
class _ModernIllustration extends StatelessWidget {
  final OnboardingPageModel page;

  const _ModernIllustration({required this.page});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: context.deviceType == DeviceType.mobile ? 280 : 340,
            height: context.deviceType == DeviceType.mobile ? 280 : 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  page.primaryColor.withValues(alpha: 0.2),
                  page.secondaryColor.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Cercles concentriques animés
                ..._buildConcentricCircles(page),

                // Icône centrale
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        page.primaryColor,
                        page.secondaryColor,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: page.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    page.icon,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildConcentricCircles(OnboardingPageModel page) {
    return [
      _AnimatedConcentricCircle(
        size: 200,
        color: page.primaryColor.withValues(alpha: 0.15),
        duration: const Duration(seconds: 3),
      ),
      _AnimatedConcentricCircle(
        size: 240,
        color: page.secondaryColor.withValues(alpha: 0.1),
        duration: const Duration(seconds: 4),
      ),
    ];
  }
}

// ================================
// ANIMATED CONCENTRIC CIRCLE
// ================================
class _AnimatedConcentricCircle extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const _AnimatedConcentricCircle({
    required this.size,
    required this.color,
    required this.duration,
  });

  @override
  State<_AnimatedConcentricCircle> createState() =>
      _AnimatedConcentricCircleState();
}

class _AnimatedConcentricCircleState extends State<_AnimatedConcentricCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size + (_controller.value * 20),
          height: widget.size + (_controller.value * 20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withValues(
                alpha: (1 - _controller.value) * 0.3,
              ),
              width: 2,
            ),
          ),
        );
      },
    );
  }
}

// ================================
// MODERN PROGRESS INDICATOR
// ================================
class _ModernProgressIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final List<OnboardingPageModel> pages;

  const _ModernProgressIndicator({
    required this.currentPage,
    required this.totalPages,
    required this.pages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isActive = currentPage == index;
        final page = pages[index];

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 40 : 12,
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      page.primaryColor,
                      page.secondaryColor,
                    ],
                  )
                : null,
            color: isActive ? null : AppThemeSystem.grey300.withValues(alpha: 0.4),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: page.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

// ================================
// ANIMATED GRADIENT BUTTON
// ================================
class _AnimatedGradientButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final IconData icon;
  final bool isPrimary;

  const _AnimatedGradientButton({
    required this.onPressed,
    required this.text,
    required this.icon,
    this.isPrimary = false,
  });

  @override
  State<_AnimatedGradientButton> createState() =>
      _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<_AnimatedGradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: context.buttonHeight,
              decoration: BoxDecoration(
                borderRadius: context.borderRadius(BorderRadiusType.medium),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isPrimary
                      ? [
                          AppThemeSystem.primaryColor,
                          AppThemeSystem.secondaryColor,
                          AppThemeSystem.tertiaryColor,
                        ]
                      : [
                          AppThemeSystem.primaryColor,
                          AppThemeSystem.secondaryColor,
                        ],
                  transform: GradientRotation(_controller.value * math.pi * 2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppThemeSystem.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.text,
                      style: context.button.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
