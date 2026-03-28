import 'package:flutter/material.dart';
import '../data/models/group_model.dart';
import 'app_theme_system.dart';

/// Widget réutilisable pour afficher l'avatar d'un groupe
/// Affiche l'image si disponible, sinon affiche les initiales
class GroupAvatar extends StatelessWidget {
  final GroupModel group;
  final double radius;
  final Color? backgroundColor;
  final TextStyle? initialsStyle;

  const GroupAvatar({
    super.key,
    required this.group,
    this.radius = 28,
    this.backgroundColor,
    this.initialsStyle,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppThemeSystem.tertiaryColor,
      backgroundImage: group.avatarUrl != null && group.avatarUrl!.isNotEmpty
          ? NetworkImage(group.avatarUrl!)
          : null,
      child: group.avatarUrl == null || group.avatarUrl!.isEmpty
          ? Text(
              group.initials,
              style: initialsStyle ??
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: radius * 0.6, // Proportionnel au radius
                  ),
            )
          : null,
    );
  }
}

/// Variante avec nom de groupe et initiales calculées à partir du nom
class GroupAvatarFromName extends StatelessWidget {
  final String groupName;
  final String? avatarUrl;
  final double radius;
  final Color? backgroundColor;
  final TextStyle? initialsStyle;

  const GroupAvatarFromName({
    super.key,
    required this.groupName,
    this.avatarUrl,
    this.radius = 28,
    this.backgroundColor,
    this.initialsStyle,
  });

  /// Calcule les initiales à partir du nom
  String get _initials {
    final words = groupName.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return 'G';
    if (words.length == 1) {
      final word = words[0];
      return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppThemeSystem.tertiaryColor,
      backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
          ? NetworkImage(avatarUrl!)
          : null,
      child: avatarUrl == null || avatarUrl!.isEmpty
          ? Text(
              _initials,
              style: initialsStyle ??
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: radius * 0.6,
                  ),
            )
          : null,
    );
  }
}
