import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget d'icône de flamme animée avec particules
class BurningFlameIcon extends StatefulWidget {
  final double size;
  final Color color;

  const BurningFlameIcon({
    super.key,
    this.size = 32,
    this.color = const Color(0xFFFF6B35),
  });

  @override
  State<BurningFlameIcon> createState() => _BurningFlameIconState();
}

class _BurningFlameIconState extends State<BurningFlameIcon>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particlesController;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    // Animation principale
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    // Animation des particules
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Créer les particules
    _initParticles();
  }

  void _initParticles() {
    final random = math.Random();
    for (int i = 0; i < 8; i++) {
      _particles.add(Particle(
        startDelay: random.nextDouble(),
        xOffset: -0.3 + (random.nextDouble() * 0.6),
        speed: 0.5 + (random.nextDouble() * 0.5),
      ));
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 1.8,
      height: widget.size * 1.8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Particules en arrière-plan
          AnimatedBuilder(
            animation: _particlesController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size * 1.8, widget.size * 1.8),
                painter: ParticlesPainter(
                  particles: _particles,
                  progress: _particlesController.value,
                  baseSize: widget.size,
                ),
              );
            },
          ),

          // Flamme principale animée
          AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) {
              final scale = 1.0 + (math.sin(_mainController.value * 2 * math.pi) * 0.1);
              final rotation = math.sin(_mainController.value * 4 * math.pi) * 0.08;

              return Transform.scale(
                scale: scale,
                child: Transform.rotate(
                  angle: rotation,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFB703).withValues(alpha: 0.25),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFFFD54F),
                            Color(0xFFFFB703),
                            Color(0xFFFF8A00),
                            Color(0xFFFF6B35),
                            Color(0xFFE63946),
                          ],
                          stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                        ).createShader(bounds);
                      },
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        size: widget.size,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Classe représentant une particule
class Particle {
  final double startDelay;
  final double xOffset;
  final double speed;

  Particle({
    required this.startDelay,
    required this.xOffset,
    required this.speed,
  });
}

/// Painter pour dessiner les particules
class ParticlesPainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final double baseSize;

  ParticlesPainter({
    required this.particles,
    required this.progress,
    required this.baseSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (final particle in particles) {
      // Calculer la position avec le délai
      final particleProgress = ((progress + particle.startDelay) % 1.0);

      // Position Y : monte de bas en haut
      final y = centerY + (baseSize * 0.3) - (particleProgress * baseSize * 1.2);

      // Position X : oscille légèrement
      final xOscillation = math.sin(particleProgress * math.pi * 4) * 4;
      final x = centerX + (particle.xOffset * baseSize * 0.4) + xOscillation;

      // Taille : commence petit, grandit, puis rétrécit
      final sizeProgress = math.sin(particleProgress * math.pi);
      final particleSize = 2.5 + (sizeProgress * 2.5);

      // Opacité : fade out en montant
      final opacity = (1.0 - particleProgress) * 0.9;

      // Couleur qui change du jaune au rouge
      final colorProgress = particleProgress;
      final particleColor = Color.lerp(
        const Color(0xFFFFD54F),
        const Color(0xFFFF6B35),
        colorProgress,
      )!.withValues(alpha: opacity);

      final paint = Paint()
        ..color = particleColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) => true;
}

