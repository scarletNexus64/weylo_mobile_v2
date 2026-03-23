import 'package:flutter/material.dart';
import 'app_theme_system.dart';

/// Widget that wraps a profile picture with a story status border
/// - Green gradient border for unviewed stories
/// - Grey border for viewed stories
/// - Default border for no stories
class StoryStatusBorder extends StatelessWidget {
  final Widget child;
  final bool hasStories;
  final bool hasUnviewedStories;
  final VoidCallback? onTap;
  final double size;
  final double borderWidth;

  const StoryStatusBorder({
    super.key,
    required this.child,
    this.hasStories = false,
    this.hasUnviewedStories = false,
    this.onTap,
    this.size = 56.0, // Default size for CircleAvatar radius 25 + padding
    this.borderWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    // Determine border decoration based on story status
    Decoration borderDecoration;

    if (hasStories && hasUnviewedStories) {
      // Green gradient border for unviewed stories (WhatsApp style)
      borderDecoration = BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppThemeSystem.successColor,
            AppThemeSystem.successColor.withValues(alpha: 0.7),
            AppThemeSystem.successColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else if (hasStories && !hasUnviewedStories) {
      // Grey border for viewed stories
      borderDecoration = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppThemeSystem.grey600.withValues(alpha: 0.5),
          width: borderWidth,
        ),
      );
    } else {
      // Default border for no stories
      borderDecoration = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppThemeSystem.grey600.withValues(alpha: 0.3),
          width: borderWidth,
        ),
      );
    }

    Widget content = Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: borderDecoration,
      child: child,
    );

    // Make it tappable only if there are stories
    if (hasStories && onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
