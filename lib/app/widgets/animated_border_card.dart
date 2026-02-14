import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Un widget qui affiche un conteneur avec une bordure animée circulante
class AnimatedBorderCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final Color borderColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final Duration animationDuration;

  const AnimatedBorderCard({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.borderWidth = 2.0,
    this.borderColor = Colors.blue,
    this.backgroundColor,
    this.padding,
    this.animationDuration = const Duration(seconds: 3),
  });

  @override
  State<AnimatedBorderCard> createState() => _AnimatedBorderCardState();
}

class _AnimatedBorderCardState extends State<AnimatedBorderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat(); // Répète l'animation en boucle
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
        return CustomPaint(
          painter: _AnimatedBorderPainter(
            progress: _controller.value,
            borderRadius: widget.borderRadius,
            borderWidth: widget.borderWidth,
            borderColor: widget.borderColor,
          ),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _AnimatedBorderPainter extends CustomPainter {
  final double progress;
  final double borderRadius;
  final double borderWidth;
  final Color borderColor;

  _AnimatedBorderPainter({
    required this.progress,
    required this.borderRadius,
    required this.borderWidth,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    // Calculer le périmètre total
    final perimeter = 2 * (size.width + size.height) +
        2 * math.pi * borderRadius -
        8 * borderRadius;

    // Longueur du trait animé (30% du périmètre)
    final dashLength = perimeter * 0.3;

    // Position actuelle basée sur le progress
    final startPosition = perimeter * progress;
    final endPosition = startPosition + dashLength;

    // Créer un shader gradient pour l'effet de lumière
    final gradient = LinearGradient(
      colors: [
        borderColor.withValues(alpha: 0.0),
        borderColor,
        borderColor,
        borderColor.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    // Dessiner la bordure avec effet de lumière
    final path = Path()..addRRect(rrect);

    // Utiliser PathMetrics pour dessiner le segment animé
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      final length = metric.length;

      // Normaliser les positions
      final normalizedStart = startPosition % length;
      final normalizedEnd = endPosition % length;

      if (normalizedEnd > normalizedStart) {
        // Cas normal: le trait ne traverse pas la fin du chemin
        final extractedPath = metric.extractPath(normalizedStart, normalizedEnd);

        paint.shader = gradient.createShader(
          Rect.fromLTWH(
            normalizedStart,
            0,
            dashLength,
            borderWidth,
          ),
        );

        canvas.drawPath(extractedPath, paint);
      } else {
        // Cas où le trait traverse la fin du chemin
        final path1 = metric.extractPath(normalizedStart, length);
        final path2 = metric.extractPath(0, normalizedEnd);

        paint.shader = gradient.createShader(
          Rect.fromLTWH(
            normalizedStart,
            0,
            dashLength,
            borderWidth,
          ),
        );

        canvas.drawPath(path1, paint);
        canvas.drawPath(path2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_AnimatedBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
