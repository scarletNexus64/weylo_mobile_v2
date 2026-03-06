import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/app_theme_system.dart';
import '../controllers/splashscreen_controller.dart';

class SplashscreenView extends GetView<SplashscreenController> {
  const SplashscreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppThemeSystem.darkBackgroundColor : Colors.white,
      body: Stack(
        children: [
          // Wallpaper pattern avec icônes (comme chat/groupe)
          _buildWallpaperPattern(context, isDark),

          // Contenu principal
          SafeArea(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: context.horizontalPadding,
                vertical: context.verticalPadding,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // Nom de l'app avec effet de blur
                  _AnimatedAppName(),

                  SizedBox(height: context.elementSpacing * 2),

                  // Loading minimaliste
                  _MinimalLoading(),

                  const Spacer(flex: 3),

                  // Slogan en footer (bas de page)
                  _AnimatedSlogan(),

                  SizedBox(height: context.verticalPadding),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Wallpaper pattern avec icônes Material (inspiré chat/groupe)
  Widget _buildWallpaperPattern(BuildContext context, bool isDark) {
    final screenSize = MediaQuery.of(context).size;
    final random = math.Random(42);

    // Icônes Material élégantes
    final icons = [
      Icons.chat_bubble_outline_rounded,
      Icons.favorite_border_rounded,
      Icons.star_border_rounded,
      Icons.lock_outline_rounded,
      Icons.shield_outlined,
      Icons.masks_rounded,
      Icons.psychology_outlined,
      Icons.auto_awesome_rounded,
      Icons.celebration_outlined,
      Icons.emoji_emotions_outlined,
    ];

    final iconWidgets = <Widget>[];

    for (var i = 0; i < 40; i++) {
      final icon = icons[i % icons.length];
      final x = random.nextDouble() * screenSize.width;
      final y = random.nextDouble() * screenSize.height;
      final size = 18.0 + (random.nextDouble() * 24);
      final rotation = random.nextDouble() * 6.28;
      final opacity = 0.08 + (random.nextDouble() * 0.12);

      iconWidgets.add(
        Positioned(
          left: x - size / 2,
          top: y - size / 2,
          child: Transform.rotate(
            angle: rotation,
            child: Icon(
              icon,
              size: size,
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: opacity),
            ),
          ),
        ),
      );
    }

    return IgnorePointer(
      child: Stack(
        children: iconWidgets,
      ),
    );
  }
}

// ================================
// ANIMATED APP NAME WITH REVEAL EFFECT
// ================================
class _AnimatedAppName extends StatefulWidget {
  @override
  State<_AnimatedAppName> createState() => _AnimatedAppNameState();
}

class _AnimatedAppNameState extends State<_AnimatedAppName>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _controller.forward();
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
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
          child: Text(
            'Weylo',
            style: context.h1.copyWith(
              fontSize: context.deviceType == DeviceType.mobile ? 56 : 72,
              fontWeight: FontWeight.w800,
              color: AppThemeSystem.primaryColor.withValues(alpha: 0.9),
              letterSpacing: 4,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ================================
// ANIMATED SLOGAN
// ================================
class _AnimatedSlogan extends StatefulWidget {
  @override
  State<_AnimatedSlogan> createState() => _AnimatedSloganState();
}

class _AnimatedSloganState extends State<_AnimatedSlogan>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Slogan commenté par l'utilisateur
    return const SizedBox.shrink();
  }


}

// ================================
// MINIMAL LOADING
// ================================
class _MinimalLoading extends StatefulWidget {
  @override
  State<_MinimalLoading> createState() => _MinimalLoadingState();
}

class _MinimalLoadingState extends State<_MinimalLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animValue = (_controller.value - delay).clamp(0.0, 1.0);
            final scale = 0.5 + (math.sin(animValue * math.pi) * 0.5);

            return Transform.scale(
              scale: scale,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? Colors.white : AppThemeSystem.primaryColor)
                      .withValues(alpha: 0.3 + (scale * 0.4)),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
