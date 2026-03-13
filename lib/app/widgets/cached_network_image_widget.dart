import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:weylo/app/utils/image_cache_manager.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

/// Widget d'image optimisé avec cache et gestion d'erreurs
class CachedNetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const CachedNetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cacheManager = ImageCacheManager();

    // Valider l'URL
    if (imageUrl.isEmpty || !_isValidUrl(imageUrl)) {
      print('⚠️ [IMAGE] URL invalide: $imageUrl');
      return _buildErrorWidget(isDark);
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image(
        image: cacheManager.getImage(imageUrl),
        width: width,
        height: height,
        fit: fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) {
            return child;
          }

          // Afficher le placeholder pendant le chargement
          if (frame == null) {
            return placeholder ?? _buildPlaceholder(isDark);
          }

          // Animation de fondu quand l'image est chargée
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ [IMAGE] Erreur de chargement: $imageUrl');
          print('   Type: ${error.runtimeType}');
          print('   Message: $error');

          return errorWidget ?? _buildErrorWidget(isDark);
        },
      ),
    );
  }

  /// Vérifier si l'URL est valide
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Construire le placeholder (shimmer)
  Widget _buildPlaceholder(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
      highlightColor: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey100,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 320,
        color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
      ),
    );
  }

  /// Construire le widget d'erreur
  Widget _buildErrorWidget(bool isDark) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 320,
      color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
      child: Center(
        child: Icon(
          Icons.broken_image_rounded,
          size: 60,
          color: isDark ? AppThemeSystem.grey600 : AppThemeSystem.grey400,
        ),
      ),
    );
  }
}

/// Widget d'avatar optimisé
class CachedAvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String initial;
  final double radius;
  final bool isAnonymous;

  const CachedAvatarWidget({
    super.key,
    this.avatarUrl,
    required this.initial,
    this.radius = 22,
    this.isAnonymous = false,
  });

  @override
  Widget build(BuildContext context) {
    final cacheManager = ImageCacheManager();

    if (isAnonymous) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppThemeSystem.grey700,
        child: Icon(
          Icons.lock_rounded,
          color: Colors.white,
          size: radius,
        ),
      );
    }

    // Si pas d'URL ou URL invalide, afficher l'initiale
    if (avatarUrl == null || avatarUrl!.isEmpty || !_isValidUrl(avatarUrl!)) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppThemeSystem.primaryColor,
        child: Text(
          initial.isNotEmpty ? initial.toUpperCase() : 'U',
          style: TextStyle(
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppThemeSystem.primaryColor,
      child: ClipOval(
        child: Image(
          image: cacheManager.getImage(_addTimestamp(avatarUrl!)),
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('❌ [AVATAR] Erreur: $avatarUrl - $error');

            // Afficher l'initiale en cas d'erreur
            return Container(
              width: radius * 2,
              height: radius * 2,
              color: AppThemeSystem.primaryColor,
              child: Center(
                child: Text(
                  initial.isNotEmpty ? initial.toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: radius * 0.8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  String _addTimestamp(String url) {
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}t=${DateTime.now().millisecondsSinceEpoch}';
  }
}
