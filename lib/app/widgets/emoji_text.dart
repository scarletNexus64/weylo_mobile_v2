import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

/// Widget spécial pour afficher des emojis colorés
/// Contourne le problème de la police SF-Pro qui ne supporte pas les emojis
///
/// STRATÉGIE TRIPLE:
/// 1. fontFamily: null explicite pour bloquer SF-Pro
/// 2. Theme isolé sans police personnalisée
/// 3. fontFamilyFallback avec polices emoji natives du système
class EmojiText extends StatelessWidget {
  final String emoji;
  final double size;

  const EmojiText({
    Key? key,
    required this.emoji,
    this.size = 32.0,
  }) : super(key: key);

  // Créer une key unique basée sur l'emoji pour forcer le rebuild
  static Key uniqueKey(String emoji, String? prefix) {
    return ValueKey('emoji_${prefix ?? ''}_$emoji');
  }

  @override
  Widget build(BuildContext context) {
    // 🔍 LOGS DÉTAILLÉS
    print('╔═══════════════════════════════════════════════════════════╗');
    print('║ 😀 EMOJI_TEXT WIDGET BUILD (RichText Approach)           ║');
    print('╠═══════════════════════════════════════════════════════════╣');
    print('║ Emoji reçu: "$emoji"');
    print('║ Widget Key: $key');
    print('║ Longueur string: ${emoji.length}');
    print('║ Runes (codes Unicode): ${emoji.runes.toList()}');
    print('║ Codes hex: ${emoji.runes.map((r) => r.toRadixString(16).toUpperCase().padLeft(4, '0')).toList()}');
    print('║ Taille demandée: $size px');
    print('╚═══════════════════════════════════════════════════════════╝');

    // Vérifier le thème actuel (pour comparaison)
    final currentTheme = Theme.of(context);
    print('🎨 [EmojiText] Thème parent fontFamily: ${currentTheme.textTheme.bodyMedium?.fontFamily}');
    print('🚀 [EmojiText] Utilisation de RichText pour bypass TOTAL du thème');

    // APPROCHE RADICALE: RichText ne passe PAS par le système de thème
    // RichText + TextSpan = Rendu direct sans héritage de thème
    return RichText(
      text: TextSpan(
        text: emoji,
        style: TextStyle(
          fontSize: size,
          // NE PAS spécifier de fontFamily du tout
          // Laisser le système utiliser sa police par défaut pour les emojis
          fontFamily: null,
          // Polices emoji natives du système en fallback
          fontFamilyFallback: const [
            'Noto Color Emoji',    // Android
            'Apple Color Emoji',   // iOS/macOS
            'Segoe UI Emoji',      // Windows
            'Segoe UI Symbol',     // Windows fallback
            'Noto Emoji',          // Linux
            'Android Emoji',       // Android fallback
          ],
          color: Colors.black,   // Couleur par défaut (invisible pour les emojis colorés)
          height: 1.0,
          decoration: TextDecoration.none,
          // CRUCIAL: Pas d'héritage!
          inherit: false,
        ),
      ),
      textScaleFactor: 1.0,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('emoji', emoji));
    properties.add(DoubleProperty('size', size));
    developer.log(
      '🔧 EmojiText debug properties',
      name: 'EmojiText',
      error: 'emoji: $emoji, size: $size, runes: ${emoji.runes.toList()}',
    );
  }
}
