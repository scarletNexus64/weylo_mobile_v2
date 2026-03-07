import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import 'package:weylo/app/data/services/confession_service.dart';
import 'package:weylo/app/data/models/confession_model.dart';
import 'package:weylo/app/modules/feeds/controllers/feeds_controller.dart';
import 'package:weylo/app/modules/feeds/views/widgets/create_confession_media_bottom_sheet.dart';

class EditConfessionView extends StatefulWidget {
  const EditConfessionView({super.key});

  @override
  State<EditConfessionView> createState() => _EditConfessionViewState();
}

class _EditConfessionViewState extends State<EditConfessionView> {
  late TextEditingController _textController;
  final _confessionService = ConfessionService();

  bool isUpdating = false;
  double uploadProgress = 0.0;

  // Original confession data
  late ConfessionModel confession;

  // Media selection (for new media)
  File? selectedMedia;
  String? selectedMediaType;
  VideoPlayerController? videoController;

  // Flag to indicate if user wants to remove existing media
  bool removeExistingMedia = false;

  @override
  void initState() {
    super.initState();

    // Get confession from arguments
    confession = Get.arguments as ConfessionModel;

    // Initialize text controller with existing content
    _textController = TextEditingController(text: confession.content);
  }

  @override
  void dispose() {
    _textController.dispose();
    videoController?.dispose();
    super.dispose();
  }

  Future<void> _openMediaSelector() async {
    await Get.bottomSheet(
      CreateConfessionMediaBottomSheet(
        onMediaSelected: (File file, String mediaType) async {
          // Si c'est une vidéo, initialiser le lecteur
          if (mediaType == 'video') {
            final controller = VideoPlayerController.file(file);
            await controller.initialize();

            setState(() {
              selectedMedia = file;
              selectedMediaType = mediaType;
              videoController?.dispose();
              videoController = controller;
              // Reset the remove flag since we're selecting new media
              removeExistingMedia = false;
            });
          } else {
            setState(() {
              selectedMedia = file;
              selectedMediaType = mediaType;
              // Reset the remove flag since we're selecting new media
              removeExistingMedia = false;
            });
          }
        },
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
    );
  }

  void _removeMedia() {
    setState(() {
      selectedMedia = null;
      selectedMediaType = null;
      videoController?.dispose();
      videoController = null;
    });
  }

  Future<void> _updateConfession() async {
    final content = _textController.text.trim();

    // Vérifier qu'il y a du contenu ou un média (existant ou nouveau) après la mise à jour
    final willHaveMedia = selectedMedia != null || (confession.mediaUrl != null && !removeExistingMedia);
    if (content.isEmpty && !willHaveMedia) {
      Get.snackbar(
        'Erreur',
        'Veuillez écrire quelque chose ou ajouter une image/vidéo',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.errorColor,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      isUpdating = true;
      uploadProgress = 0.0;
    });

    try {
      await _confessionService.updateConfession(
        confessionId: confession.id,
        content: content,
        mediaPath: selectedMedia?.path,
        mediaType: selectedMediaType,
        removeMedia: removeExistingMedia,
        onUploadProgress: (sent, total) {
          setState(() {
            uploadProgress = sent / total;
          });
        },
      );

      // Refresh the feed
      try {
        final controller = Get.find<ConfessionsController>();
        await controller.loadConfessions(refresh: true);
      } catch (e) {
        print('Controller not found: $e');
      }

      Get.back(); // Return to previous page

      Get.snackbar(
        'Confession modifiée',
        'Votre confession a été modifiée avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.successColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de modifier la confession',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.errorColor,
        colorText: Colors.white,
      );
      print('Error updating confession: $e');
    } finally {
      setState(() {
        isUpdating = false;
        uploadProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;

    return Scaffold(
      backgroundColor: isDark ? AppThemeSystem.darkBackgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppThemeSystem.darkCardColor : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            size: deviceType == DeviceType.mobile ? 24 : 28,
          ),
          onPressed: () => Get.back(),
          color: isDark ? Colors.white : AppThemeSystem.blackColor,
        ),
        title: Text(
          'Modifier la confession',
          style: context.textStyle(FontSizeType.h6).copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppThemeSystem.blackColor,
          ),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: context.horizontalPadding,
                  vertical: context.elementSpacing * 1.5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text Input
                    TextField(
                      controller: _textController,
                      maxLines: null,
                      minLines: 8,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Modifiez votre confession...',
                        hintStyle: context.textStyle(FontSizeType.body1).copyWith(
                          color: isDark ? AppThemeSystem.grey500 : AppThemeSystem.grey600,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: context.elementSpacing * 0.5,
                        ),
                      ),
                      style: context.textStyle(FontSizeType.body1).copyWith(
                        color: isDark ? Colors.white : AppThemeSystem.blackColor,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: context.elementSpacing * 1.5),

                    // Current Media Preview (if exists and not marked for removal)
                    if (confession.mediaUrl != null && selectedMedia == null && !removeExistingMedia)
                      _buildCurrentMediaPreview(context, isDark),

                    // New Media Preview
                    if (selectedMedia != null)
                      _buildNewMediaPreview(context, isDark),
                  ],
                ),
              ),
            ),

            // Bottom Actions
            Container(
              padding: EdgeInsets.only(
                left: context.horizontalPadding,
                right: context.horizontalPadding,
                top: context.elementSpacing,
                bottom: context.elementSpacing,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Media button
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.perm_media_outlined,
                          color: AppThemeSystem.primaryColor,
                        ),
                        onPressed: _openMediaSelector,
                      ),
                      if ((confession.mediaUrl != null && !removeExistingMedia) || selectedMedia != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedMedia = null;
                              selectedMediaType = null;
                              videoController?.dispose();
                              videoController = null;
                              // Mark that we want to remove the existing media from server
                              removeExistingMedia = true;
                            });
                          },
                          child: Text(
                            'Supprimer le média',
                            style: TextStyle(color: AppThemeSystem.errorColor),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: context.elementSpacing * 0.5),

                  // Update Button
                  SizedBox(
                    width: double.infinity,
                    height: context.buttonHeight,
                    child: ElevatedButton(
                      onPressed: isUpdating ? null : _updateConfession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemeSystem.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: context.borderRadius(BorderRadiusType.small),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: AppThemeSystem.primaryColor.withValues(alpha: 0.5),
                      ),
                      child: isUpdating
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Mettre à jour',
                              style: context.textStyle(FontSizeType.body1).copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentMediaPreview(BuildContext context, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: context.elementSpacing),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: context.borderRadius(BorderRadiusType.medium),
            child: confession.mediaType == 'image'
                ? Image.network(
                    confession.mediaUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.black,
                    child: Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Text(
                'Média actuel',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewMediaPreview(BuildContext context, bool isDark) {
    return Container(
      height: 200,
      margin: EdgeInsets.only(bottom: context.elementSpacing),
      decoration: BoxDecoration(
        color: isDark
            ? AppThemeSystem.grey800.withValues(alpha: 0.3)
            : AppThemeSystem.grey100,
        borderRadius: context.borderRadius(BorderRadiusType.medium),
        border: Border.all(
          color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: context.borderRadius(BorderRadiusType.medium),
            child: SizedBox(
              width: double.infinity,
              height: 200,
              child: selectedMediaType == 'video' && videoController != null
                  ? AspectRatio(
                      aspectRatio: videoController!.value.aspectRatio,
                      child: VideoPlayer(videoController!),
                    )
                  : Image.file(
                      selectedMedia!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: _removeMedia,
            ),
          ),
        ],
      ),
    );
  }
}
