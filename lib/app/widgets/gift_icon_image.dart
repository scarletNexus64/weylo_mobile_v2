import 'package:flutter/material.dart';

/// Widget pour afficher l'icône d'un cadeau (image Twemoji ou emoji fallback)
class GiftIconImage extends StatelessWidget {
  final String? imageUrl;
  final String emojiIcon;
  final double size;
  final BoxFit fit;

  const GiftIconImage({
    Key? key,
    this.imageUrl,
    required this.emojiIcon,
    this.size = 32,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Si on a une URL d'image, afficher l'image
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // En cas d'erreur, afficher l'emoji en fallback
          return Text(
            emojiIcon,
            style: TextStyle(fontSize: size),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          // Pendant le chargement, afficher l'emoji
          return Text(
            emojiIcon,
            style: TextStyle(fontSize: size),
          );
        },
      );
    }

    // Pas d'URL d'image, afficher l'emoji directement
    return Text(
      emojiIcon,
      style: TextStyle(fontSize: size),
    );
  }
}
