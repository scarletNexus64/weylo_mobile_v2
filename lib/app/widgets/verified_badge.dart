import 'package:flutter/material.dart';

/// Badge de vérification bleu pour les utilisateurs certifiés/premium
/// Affiche une icône de vérification bleue avec un fond blanc
class VerifiedBadge extends StatelessWidget {
  final double size;
  final bool showBackground;

  const VerifiedBadge({
    Key? key,
    this.size = 16,
    this.showBackground = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: showBackground
          ? BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            )
          : null,
      child: Icon(
        Icons.verified,
        size: size,
        color: const Color(0xFF1DA1F2), // Twitter blue color
      ),
    );
  }
}
