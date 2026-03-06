import 'dart:io';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

/// Helper pour générer des thumbnails de vidéos
class VideoThumbnailGenerator {
  /// Génère un thumbnail à partir d'une vidéo
  ///
  /// [videoPath] : Chemin de la vidéo
  /// [timeMs] : Position en millisecondes pour capturer le thumbnail (par défaut: début de la vidéo)
  ///
  /// Retourne le chemin du fichier thumbnail généré, ou null en cas d'erreur
  static Future<String?> generateThumbnail(
    String videoPath, {
    int timeMs = 0,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final thumbnailPath = '${tempDir.path}/video_thumbnail_$timestamp.jpg';

      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbnailPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 720, // Hauteur maximale en pixels
        maxWidth: 720, // Largeur maximale en pixels
        timeMs: timeMs, // Position dans la vidéo
        quality: 85, // Qualité JPEG (0-100)
      );

      if (thumbnail != null && await File(thumbnail).exists()) {
        print('✅ Thumbnail vidéo généré: $thumbnail');
        return thumbnail;
      }

      print('❌ Échec de génération du thumbnail');
      return null;
    } catch (e) {
      print('❌ Erreur lors de la génération du thumbnail: $e');
      return null;
    }
  }

  /// Génère un thumbnail sous forme de bytes (pour l'upload direct)
  static Future<List<int>?> generateThumbnailBytes(
    String videoPath, {
    int timeMs = 0,
  }) async {
    try {
      final thumbnailData = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 720,
        maxWidth: 720,
        timeMs: timeMs,
        quality: 85,
      );

      if (thumbnailData != null) {
        print('✅ Thumbnail vidéo généré (bytes): ${thumbnailData.length} bytes');
        return thumbnailData;
      }

      print('❌ Échec de génération du thumbnail');
      return null;
    } catch (e) {
      print('❌ Erreur lors de la génération du thumbnail: $e');
      return null;
    }
  }
}
