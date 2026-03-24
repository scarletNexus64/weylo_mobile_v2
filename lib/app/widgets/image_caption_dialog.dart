import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_theme_system.dart';

/// Dialog to add a caption to an image before sending
class ImageCaptionDialog extends StatefulWidget {
  final File imageFile;
  final Function(String caption) onSend;

  const ImageCaptionDialog({
    Key? key,
    required this.imageFile,
    required this.onSend,
  }) : super(key: key);

  @override
  State<ImageCaptionDialog> createState() => _ImageCaptionDialogState();
}

class _ImageCaptionDialogState extends State<ImageCaptionDialog> {
  final TextEditingController _captionController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _captionController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(context.horizontalPadding),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.85, // Limit dialog height
        ),
        decoration: BoxDecoration(
          color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(context.elementSpacing),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ajouter une légende',
                    style: context.textStyle(FontSizeType.h6).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
            ),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image preview
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: screenHeight * 0.35,
                      ),
                      margin: EdgeInsets.all(context.elementSpacing),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          widget.imageFile,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // Caption input
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.elementSpacing),
                      child: TextField(
                        controller: _captionController,
                        focusNode: _focusNode,
                        maxLines: 3,
                        minLines: 1,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText: 'Ajouter une légende (optionnel)...',
                          hintStyle: context.textStyle(FontSizeType.body2).copyWith(
                            color: AppThemeSystem.grey600,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppThemeSystem.grey800.withValues(alpha: 0.4)
                              : AppThemeSystem.grey100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: context.elementSpacing,
                            vertical: context.elementSpacing * 0.7,
                          ),
                        ),
                        style: context.textStyle(FontSizeType.body2),
                      ),
                    ),

                    SizedBox(height: context.elementSpacing),
                  ],
                ),
              ),
            ),

            // Action buttons (fixed at bottom)
            Padding(
              padding: EdgeInsets.all(context.elementSpacing),
              child: Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark
                              ? AppThemeSystem.grey700
                              : AppThemeSystem.grey300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: context.elementSpacing * 0.8,
                        ),
                      ),
                      child: Text(
                        'Annuler',
                        style: context.textStyle(FontSizeType.body2).copyWith(
                          color: isDark ? Colors.white : AppThemeSystem.blackColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: context.elementSpacing),

                  // Send button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        final caption = _captionController.text.trim();
                        Get.back();
                        widget.onSend(caption);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemeSystem.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: context.elementSpacing * 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Envoyer',
                            style: context.textStyle(FontSizeType.body2).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
