import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../controllers/story_controller.dart';
import '../create_story_view.dart';
import '../story_preview_edit_view.dart';
import '../../../../widgets/app_theme_system.dart';
import '../../../../utils/image_editor_page.dart';
import '../../../../utils/video_trimmer_page.dart';

/// Bottomsheet pour créer une story
class CreateStoryBottomSheet extends StatefulWidget {
  const CreateStoryBottomSheet({Key? key}) : super(key: key);

  @override
  State<CreateStoryBottomSheet> createState() => _CreateStoryBottomSheetState();
}

class _CreateStoryBottomSheetState extends State<CreateStoryBottomSheet> {
  final controller = Get.find<StoryController>();
  List<AssetEntity> _mediaList = [];
  bool _isLoadingMedia = true;

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      // Récupérer les albums
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.common, // Photos et vidéos
        onlyAll: true,
      );

      if (albums.isNotEmpty) {
        // Récupérer les médias du premier album (récents)
        final List<AssetEntity> media = await albums[0].getAssetListRange(
          start: 0,
          end: 30, // Les 30 derniers médias
        );

        setState(() {
          _mediaList = media;
          _isLoadingMedia = false;
        });
      } else {
        setState(() {
          _isLoadingMedia = false;
        });
      }
    } else {
      setState(() {
        _isLoadingMedia = false;
      });

      Get.snackbar(
        'Permission refusée',
        'Veuillez autoriser l\'accès à la galerie dans les paramètres',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Créer une story',
                    style: context.textStyle(FontSizeType.h5).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
            ),

            // Story texte option
            ListTile(
              leading: Container(
                width: deviceType == DeviceType.mobile ? 48 : 56,
                height: deviceType == DeviceType.mobile ? 48 : 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppThemeSystem.primaryColor,
                      AppThemeSystem.secondaryColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.text_fields,
                  color: Colors.white,
                  size: deviceType == DeviceType.mobile ? 24 : 28,
                ),
              ),
              title: Text(
                'Story texte',
                style: context.textStyle(FontSizeType.body1).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Créer une story avec du texte',
                style: context.textStyle(FontSizeType.caption).copyWith(
                  color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: isDark ? AppThemeSystem.grey500 : AppThemeSystem.grey600,
              ),
              onTap: () {
                Get.back();
                Get.to(() => const CreateStoryView());
              },
            ),

            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.horizontalPadding,
                vertical: context.elementSpacing * 0.5,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Photos et vidéos',
                  style: context.textStyle(FontSizeType.subtitle1).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Camera & Gallery grid
            Container(
              height: 300,
              padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
              child: _isLoadingMedia
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppThemeSystem.primaryColor,
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: deviceType == DeviceType.mobile ? 3 : 4,
                        crossAxisSpacing: context.elementSpacing * 0.5,
                        mainAxisSpacing: context.elementSpacing * 0.5,
                      ),
                      itemCount: 1 + _mediaList.length, // 1 pour caméra + galerie
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // Première card : Caméra
                          return _CameraCard(
                            controller: controller,
                            isDark: isDark,
                            deviceType: deviceType,
                          );
                        }

                        // Autres cards : Galerie réelle
                        final media = _mediaList[index - 1];
                        return _GalleryMediaCard(
                          media: media,
                          isDark: isDark,
                        );
                      },
                    ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Card pour ouvrir la caméra
class _CameraCard extends StatelessWidget {
  final StoryController controller;
  final bool isDark;
  final DeviceType deviceType;

  const _CameraCard({
    required this.controller,
    required this.isDark,
    required this.deviceType,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openCamera(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppThemeSystem.primaryColor,
              AppThemeSystem.secondaryColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: deviceType == DeviceType.mobile ? 32 : 40,
            ),
            SizedBox(height: context.elementSpacing * 0.25),
            Text(
              'Caméra',
              style: context.textStyle(FontSizeType.caption).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCamera(BuildContext context) async {
    final picker = ImagePicker();

    // Demander quel type de média
    final mediaType = await Get.dialog<String>(
      AlertDialog(
        backgroundColor: isDark ? AppThemeSystem.darkCardColor : Colors.white,
        title: Text(
          'Choisir le type',
          style: context.textStyle(FontSizeType.h6).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.photo_camera,
                color: AppThemeSystem.primaryColor,
              ),
              title: Text(
                'Photo',
                style: context.textStyle(FontSizeType.body1),
              ),
              onTap: () => Get.back(result: 'photo'),
            ),
            ListTile(
              leading: Icon(
                Icons.videocam,
                color: AppThemeSystem.primaryColor,
              ),
              title: Text(
                'Vidéo',
                style: context.textStyle(FontSizeType.body1),
              ),
              onTap: () => Get.back(result: 'video'),
            ),
          ],
        ),
      ),
    );

    if (mediaType == null) return;

    try {
      final XFile? media;

      if (mediaType == 'photo') {
        media = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
      } else {
        media = await picker.pickVideo(
          source: ImageSource.camera,
          // Pas de limite de durée - l'utilisateur peut rogner après
        );
      }

      if (media != null) {
        Get.back(); // Fermer le bottomsheet

        // Si c'est une photo, ouvrir l'éditeur d'image d'abord
        if (mediaType == 'photo') {
          final editedImage = await Get.to<File?>(
            () => ImageEditorPage(
              imagePath: media!.path,
              showEditOptions: true,
            ),
            fullscreenDialog: true,
          );

          // Si l'utilisateur a annulé l'édition, ne rien faire
          if (editedImage == null) return;

          // Ouvrir la vue d'aperçu avec l'image éditée
          Get.to(
            () => StoryPreviewEditView(
              mediaPath: editedImage.path,
              mediaType: 'photo',
            ),
            fullscreenDialog: true,
          );
        } else {
          // Pour les vidéos, ouvrir le trimmer d'abord
          final trimmedVideo = await Get.to<File?>(
            () => VideoTrimmerPage(videoPath: media!.path),
            fullscreenDialog: true,
          );

          // Si l'utilisateur a annulé le trim, ne rien faire
          if (trimmedVideo == null) return;

          // Ouvrir la vue d'aperçu avec la vidéo rognée
          Get.to(
            () => StoryPreviewEditView(
              mediaPath: trimmedVideo.path,
              mediaType: mediaType,
            ),
            fullscreenDialog: true,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'accéder à la caméra',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

/// Card pour afficher un média de la galerie
class _GalleryMediaCard extends StatelessWidget {
  final AssetEntity media;
  final bool isDark;

  const _GalleryMediaCard({
    required this.media,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _selectMedia(context),
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image preview
            FutureBuilder<Uint8List?>(
              future: media.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                  );
                }
                return Container(
                  color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey300,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppThemeSystem.primaryColor,
                    ),
                  ),
                );
              },
            ),
            // Icône vidéo si c'est une vidéo
            if (media.type == AssetType.video)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectMedia(BuildContext context) async {
    try {
      // Convertir AssetEntity en fichier
      final file = await media.file;
      if (file != null) {
        Get.back(); // Fermer le bottomsheet

        final isVideo = media.type == AssetType.video;

        // Si c'est une image, ouvrir l'éditeur d'abord
        if (!isVideo) {
          final editedImage = await Get.to<File?>(
            () => ImageEditorPage(
              imagePath: file.path,
              showEditOptions: true,
            ),
            fullscreenDialog: true,
          );

          // Si l'utilisateur a annulé l'édition, ne rien faire
          if (editedImage == null) return;

          // Ouvrir la vue d'aperçu avec l'image éditée
          Get.to(
            () => StoryPreviewEditView(
              mediaPath: editedImage.path,
              mediaType: 'photo',
            ),
            fullscreenDialog: true,
          );
        } else {
          // Pour les vidéos, ouvrir le trimmer d'abord
          final trimmedVideo = await Get.to<File?>(
            () => VideoTrimmerPage(videoPath: file.path),
            fullscreenDialog: true,
          );

          // Si l'utilisateur a annulé le trim, ne rien faire
          if (trimmedVideo == null) return;

          // Ouvrir la vue d'aperçu avec la vidéo rognée
          Get.to(
            () => StoryPreviewEditView(
              mediaPath: trimmedVideo.path,
              mediaType: 'video',
            ),
            fullscreenDialog: true,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger le média',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
