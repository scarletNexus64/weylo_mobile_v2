import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../widgets/app_theme_system.dart';
import '../controllers/splashscreen_controller.dart';

class SplashscreenView extends GetView<SplashscreenController> {
  const SplashscreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background avec gradient animé
          _AnimatedGradientBackground(isDark: isDark),

          // Particules flottantes pour effet de mystère
          ..._buildFloatingParticles(),

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

                  // Logo avec effet 3D et glow pulsant
                  _AnimatedLogo(isDark: isDark),

                  SizedBox(height: context.sectionSpacing * 1.5),

                  // Nom de l'app avec effet de reveal
                  _AnimatedAppName(),

                  SizedBox(height: context.elementSpacing * 2),

                  // Slogan avec effet de typing
                  _AnimatedSlogan(),

                  const Spacer(flex: 2),

                  // Loading moderne avec flutter_spinkit
                  SpinKitWaveSpinner(
                    color: AppThemeSystem.primaryColor,
                    waveColor: AppThemeSystem.secondaryColor,
                    trackColor: AppThemeSystem.tertiaryColor,
                    size: 80,
                  ),

                  SizedBox(height: context.elementSpacing * 3),

                  // Tags défilants avec effet élégant
                  _AnimatedTags(),

                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Génère des particules flottantes pour l'effet mystérieux
  List<Widget> _buildFloatingParticles() {
    return List.generate(15, (index) {
      return _FloatingParticle(
        index: index,
        duration: Duration(milliseconds: 3000 + (index * 200)),
      );
    });
  }
}

// ================================
// ANIMATED GRADIENT BACKGROUND
// ================================
class _AnimatedGradientBackground extends StatefulWidget {
  final bool isDark;

  const _AnimatedGradientBackground({required this.isDark});

  @override
  State<_AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<_AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isDark
                  ? [
                      AppThemeSystem.darkBackgroundColor,
                      AppThemeSystem.neutralColor,
                      AppThemeSystem.darkBackgroundColor,
                    ]
                  : [
                      AppThemeSystem.backgroundColor,
                      AppThemeSystem.primaryColor.withValues(alpha: 0.1),
                      AppThemeSystem.secondaryColor.withValues(alpha: 0.05),
                      AppThemeSystem.backgroundColor,
                    ],
              stops: widget.isDark
                  ? [
                      0.0,
                      0.5 + (_controller.value * 0.2),
                      1.0,
                    ]
                  : [
                      0.0,
                      0.3 + (_controller.value * 0.1),
                      0.7 + (_controller.value * 0.1),
                      1.0,
                    ],
            ),
          ),
        );
      },
    );
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
    size = 2 + random.nextDouble() * 6;

    final colors = [
      AppThemeSystem.primaryColor,
      AppThemeSystem.secondaryColor,
      AppThemeSystem.tertiaryColor,
    ];
    color = colors[random.nextInt(colors.length)].withValues(alpha: 0.3);

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
            opacity: (math.sin(_controller.value * math.pi) * 0.5 + 0.5),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color,
                    blurRadius: size * 2,
                    spreadRadius: size * 0.5,
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
// ANIMATED LOGO WITH 3D EFFECT
// ================================
class _AnimatedLogo extends StatefulWidget {
  final bool isDark;

  const _AnimatedLogo({required this.isDark});

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Hero(
        tag: 'app_logo',
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
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
        child: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              AppThemeSystem.primaryColor,
              AppThemeSystem.secondaryColor,
              AppThemeSystem.tertiaryColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'Weylo',
            style: context.h1.copyWith(
              fontSize: context.deviceType == DeviceType.mobile ? 48 : 64,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 3,
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppThemeSystem.tertiaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
          gradient: LinearGradient(
            colors: [
              AppThemeSystem.tertiaryColor.withValues(alpha: 0.1),
              AppThemeSystem.primaryColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Text(
          'Parle librement, reste anonyme',
          style: context.subtitle2.copyWith(
            color: context.secondaryTextColor,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ================================
// ANIMATED TAGS
// ================================
class _AnimatedTags extends GetView<SplashscreenController> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Obx(() {
        final currentTag = controller.tagsList[controller.currentTagIndex.value];
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.8),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          child: Container(
            key: ValueKey<String>(currentTag),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                colors: [
                  AppThemeSystem.primaryColor.withValues(alpha: 0.15),
                  AppThemeSystem.tertiaryColor.withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(
                color: AppThemeSystem.primaryColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Text(
              currentTag,
              style: context.subtitle1.copyWith(
                color: AppThemeSystem.primaryColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }),
    );
  }
}
