import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import '../widgets/app_theme_system.dart';

/// Page pour éditer une image avant de créer une story
class ImageEditorPage extends StatefulWidget {
  final String imagePath;
  final bool showEditOptions;

  const ImageEditorPage({
    super.key,
    required this.imagePath,
    this.showEditOptions = true,
  });

  @override
  State<ImageEditorPage> createState() => _ImageEditorPageState();
}

class _ImageEditorPageState extends State<ImageEditorPage> {
  Uint8List? imageData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImageFromPath();
  }

  Future<void> _loadImageFromPath() async {
    try {
      final file = File(widget.imagePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        setState(() {
          imageData = bytes;
          isLoading = false;
        });

        // Si showEditOptions est false, aller directement à l'éditeur
        if (!widget.showEditOptions) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _openImageEditor();
          });
        }
      } else {
        throw Exception('Fichier image non trouvé');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement de l\'image: $e');
      Get.back(result: null);
      Get.snackbar(
        'Erreur',
        'Impossible de charger l\'image: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _openImageEditor() async {
    if (imageData == null) return;

    try {
      final editedImage = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageEditor(
            image: imageData,
          ),
        ),
      );

      if (editedImage != null) {
        // Sauvegarder l'image éditée dans un fichier temporaire
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final editedFile = File('${tempDir.path}/edited_story_$timestamp.jpg');
        await editedFile.writeAsBytes(editedImage);

        // Retourner le fichier édité
        Get.back(result: editedFile);
      } else {
        // L'utilisateur a annulé l'édition
        Get.back(result: null);
      }
    } catch (e) {
      print('❌ Erreur lors de l\'édition de l\'image: $e');
      Get.snackbar(
        'Erreur',
        'Impossible d\'éditer l\'image: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      Get.back(result: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Get.back(result: null);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppThemeSystem.darkCardColor : Colors.white,
        appBar: AppBar(
          backgroundColor: isDark ? AppThemeSystem.darkCardColor : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.close,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => Get.back(result: null),
          ),
          title: Text(
            'Éditer l\'image',
            style: context.textStyle(FontSizeType.h6).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (!isLoading)
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: AppThemeSystem.primaryColor,
                ),
                onPressed: _openImageEditor,
              ),
          ],
        ),
        body: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppThemeSystem.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chargement de l\'image...',
                      style: context.textStyle(FontSizeType.body1).copyWith(
                        color: isDark
                            ? AppThemeSystem.grey400
                            : AppThemeSystem.grey600,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: imageData != null
                          ? Image.memory(
                              imageData!,
                              fit: BoxFit.contain,
                            )
                          : Center(
                              child: Text(
                                'Impossible de charger l\'image',
                                style: context
                                    .textStyle(FontSizeType.body1)
                                    .copyWith(
                                      color: isDark
                                          ? AppThemeSystem.grey400
                                          : AppThemeSystem.grey600,
                                    ),
                              ),
                            ),
                    ),
                  ),
                  // Options d'édition
                  if (widget.showEditOptions)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Appuyez sur le bouton d\'édition pour commencer',
                            style: context.textStyle(FontSizeType.body2).copyWith(
                              color: isDark
                                  ? AppThemeSystem.grey500
                                  : AppThemeSystem.grey600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: imageData != null ? _openImageEditor : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppThemeSystem.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(27),
                                ),
                              ),
                              icon: const Icon(Icons.edit),
                              label: Text(
                                'Commencer l\'édition',
                                style: context.textStyle(FontSizeType.button).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () {
                                // Retourner l'image originale sans édition
                                Get.back(result: File(widget.imagePath));
                              },
                              child: Text(
                                'Utiliser sans édition',
                                style: context.textStyle(FontSizeType.body2).copyWith(
                                  color: isDark
                                      ? AppThemeSystem.grey500
                                      : AppThemeSystem.grey600,
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
}
