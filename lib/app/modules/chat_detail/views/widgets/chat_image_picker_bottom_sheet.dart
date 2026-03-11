import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../controllers/chat_detail_controller.dart';
import '../../../../widgets/app_theme_system.dart';

/// Bottomsheet pour sélectionner une image/vidéo dans le chat
class ChatImagePickerBottomSheet extends StatefulWidget {
  const ChatImagePickerBottomSheet({Key? key}) : super(key: key);

  @override
  State<ChatImagePickerBottomSheet> createState() => _ChatImagePickerBottomSheetState();
}

class _ChatImagePickerBottomSheetState extends State<ChatImagePickerBottomSheet> {
  final controller = Get.find<ChatDetailController>();
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
        type: RequestType.image, // Photos seulement
        onlyAll: true,
      );

      if (albums.isNotEmpty) {
        // Récupérer les médias du premier album (récents)
        final List<AssetEntity> media = await albums[0].getAssetListRange(
          start: 0,
          end: 30, // Les 30 dernières photos
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
                    'Envoyer une image',
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

            // Camera & Gallery grid
            Container(
              height: 350,
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
                          controller: controller,
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
  final ChatDetailController controller;
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

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        Get.back(); // Fermer le bottomsheet

        // Envoyer l'image
        await controller.sendMessage(
          type: 'image',
          imageFile: File(image.path),
        );
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
  final ChatDetailController controller;
  final bool isDark;

  const _GalleryMediaCard({
    required this.media,
    required this.controller,
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

        // Envoyer l'image
        await controller.sendMessage(
          type: 'image',
          imageFile: file,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger l\'image',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
