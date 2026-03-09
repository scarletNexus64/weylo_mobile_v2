import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:weylo/app/widgets/app_theme_system.dart';

class AnimatedShareButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;

  const AnimatedShareButton({
    super.key,
    required this.onPressed,
    this.text = 'Partager mon lien',
  });

  @override
  State<AnimatedShareButton> createState() => _AnimatedShareButtonState();
}

class _AnimatedShareButtonState extends State<AnimatedShareButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Pulse animation (battement continu - réduit)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Scale animation (effet de tap)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseAnimation,
        _scaleAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * _pulseAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: widget.onPressed,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppThemeSystem.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: _isPressed ? 0 : 1,
                    offset: Offset(0, _isPressed ? 2 : 4),
                  ),
                  BoxShadow(
                    color: AppThemeSystem.secondaryColor.withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: _isPressed ? 0 : 0.5,
                    offset: Offset(0, _isPressed ? 1 : 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppThemeSystem.primaryColor,
                          AppThemeSystem.secondaryColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  // Content
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated icon
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.rotate(
                              angle: value * math.pi * 0.1,
                              child: Transform.scale(
                                scale: 0.9 + (value * 0.1),
                                child: Icon(
                                  Icons.share_rounded,
                                  size: 24,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(width: 12),

                        // Text simple sans effet de brillance
                        Text(
                          widget.text,
                          style: context.textStyle(FontSizeType.button).copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ripple effect on press
                  if (_isPressed)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
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
