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
  bool _isLoadingMore = false;
  int _currentPage = 0;
  int _pageSize = 30;
  bool _hasMoreMedia = true;
  AssetPathEntity? _currentAlbum;

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      // Récupérer les albums avec tri par date décroissante
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.common, // Photos et vidéos
        onlyAll: true,
        filterOption: FilterOptionGroup(
          orders: [
            const OrderOption(
              type: OrderOptionType.createDate,
              asc: false, // false = décroissant (plus récent en premier)
            ),
          ],
        ),
      );

      if (albums.isNotEmpty) {
        _currentAlbum = albums[0];

        // Récupérer les médias de la première page (les plus récents en premier)
        final List<AssetEntity> media = await _currentAlbum!.getAssetListRange(
          start: 0,
          end: _pageSize,
        );

        // Vérifier s'il y a plus de médias
        final totalCount = await _currentAlbum!.assetCountAsync;

        setState(() {
          _mediaList = media;
          _hasMoreMedia = media.length < totalCount;
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

  Future<void> _loadMoreMedia() async {
    if (_isLoadingMore || !_hasMoreMedia || _currentAlbum == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    final int start = _currentPage * _pageSize;
    final int end = start + _pageSize;

    final List<AssetEntity> moreMedia = await _currentAlbum!.getAssetListRange(
      start: start,
      end: end,
    );

    final totalCount = await _currentAlbum!.assetCountAsync;

    setState(() {
      _mediaList.addAll(moreMedia); // PhotoManager retourne déjà les plus récents en premier
      _hasMoreMedia = _mediaList.length < totalCount;
      _isLoadingMore = false;
    });
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
                      itemCount: 2 + _mediaList.length + (_hasMoreMedia ? 1 : 0), // 2 cards (caméra + galerie) + médias + bouton "Voir plus"
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // Première card : Caméra
                          return _CameraCard(
                            controller: controller,
                            isDark: isDark,
                            deviceType: deviceType,
                          );
                        }

                        if (index == 1) {
                          // Deuxième card : Galerie système
                          return _GalleryPickerCard(
                            isDark: isDark,
                            deviceType: deviceType,
                          );
                        }

                        // Dernière card : Bouton "Voir plus"
                        if (_hasMoreMedia && index == 2 + _mediaList.length) {
                          return _LoadMoreCard(
                            onTap: _loadMoreMedia,
                            isLoading: _isLoadingMore,
                            isDark: isDark,
                          );
                        }

                        // Autres cards : Galerie réelle
                        final media = _mediaList[index - 2];
                        return _GalleryMediaCard(
                          media: media,
                          isDark: isDark,
                        );
                      },
                    ),
            ),

            // Espacement adaptatif pour la barre de navigation système
            SizedBox(
              height: MediaQuery.of(context).padding.bottom > 0
                  ? MediaQuery.of(context).padding.bottom
                  : 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card pour ouvrir le sélecteur de galerie système
class _GalleryPickerCard extends StatelessWidget {
  final bool isDark;
  final DeviceType deviceType;

  const _GalleryPickerCard({
    required this.isDark,
    required this.deviceType,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openGalleryPicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppThemeSystem.secondaryColor,
              AppThemeSystem.primaryColor,
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
              Icons.photo_library,
              color: Colors.white,
              size: deviceType == DeviceType.mobile ? 32 : 40,
            ),
            SizedBox(height: context.elementSpacing * 0.25),
            Text(
              'Galerie',
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

  Future<void> _openGalleryPicker(BuildContext context) async {
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
                Icons.photo,
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
          source: ImageSource.gallery,
          imageQuality: 85,
        );
      } else {
        media = await picker.pickVideo(
          source: ImageSource.gallery,
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
              mediaType: 'video',
            ),
            fullscreenDialog: true,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'accéder à la galerie',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
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

/// Card pour charger plus de médias
class _LoadMoreCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;
  final bool isDark;

  const _LoadMoreCard({
    required this.onTap,
    required this.isLoading,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppThemeSystem.primaryColor,
                ),
              )
            else
              Icon(
                Icons.add_circle_outline,
                color: AppThemeSystem.primaryColor,
                size: 32,
              ),
            SizedBox(height: context.elementSpacing * 0.25),
            Text(
              isLoading ? 'Chargement...' : 'Voir plus',
              style: context.textStyle(FontSizeType.caption).copyWith(
                color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
