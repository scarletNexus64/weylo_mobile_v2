import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/story_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../../widgets/app_theme_system.dart';
import '../../../routes/app_pages.dart';

/// View to create a new story (text only)
class CreateStoryView extends StatefulWidget {
  const CreateStoryView({Key? key}) : super(key: key);

  @override
  State<CreateStoryView> createState() => _CreateStoryViewState();
}

class _CreateStoryViewState extends State<CreateStoryView> {
  final controller = Get.find<StoryController>();
  final _textController = TextEditingController();
  final _selectedBackgroundColor = const Color(0xFF6366f1).obs;
  final _focusNode = FocusNode();

  // Predefined background colors for text stories
  final List<Color> _backgroundColors = [
    const Color(0xFF6366f1), // Indigo
    const Color(0xFFec4899), // Pink
    const Color(0xFF8b5cf6), // Purple
    const Color(0xFF14b8a6), // Teal
    const Color(0xFFf59e0b), // Amber
    const Color(0xFFef4444), // Red
    const Color(0xFF10b981), // Emerald
    const Color(0xFF3b82f6), // Blue
  ];

  @override
  void initState() {
    super.initState();
    // Auto-focus sur le texte
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonTextSize = AppThemeSystem.getFontSize(context, FontSizeType.button);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Créer une story texte',
          style: context.textStyle(
            FontSizeType.h5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppThemeSystem.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Bouton Publier dans l'AppBar
          Obx(() => TextButton(
                onPressed: controller.isCreatingStory.value || _textController.text.trim().isEmpty
                    ? null
                    : _publishTextStory,
                child: controller.isCreatingStory.value
                    ? SizedBox(
                        height: buttonTextSize,
                        width: buttonTextSize,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Publier',
                        style: TextStyle(
                          color: _textController.text.trim().isEmpty
                              ? Colors.white.withValues(alpha: 0.4)
                              : Colors.white,
                          fontSize: buttonTextSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              )),
          SizedBox(width: context.elementSpacing),
        ],
      ),
      body: _buildTextStoryContent(isDark),
    );
  }

  Widget _buildTextStoryContent(bool isDark) {
    return Obx(() {
      final deviceType = context.deviceType;
      final storyFontSize = AppThemeSystem.getFontSize(context, FontSizeType.h3);
      final horizontalPadding = context.horizontalPadding;
      final verticalPadding = context.verticalPadding;
      final elementSpacing = context.elementSpacing;

      // Taille des cercles de couleur responsive
      double colorCircleSize;
      switch (deviceType) {
        case DeviceType.mobile:
          colorCircleSize = 50.0;
          break;
        case DeviceType.tablet:
          colorCircleSize = 56.0;
          break;
        case DeviceType.largeTablet:
          colorCircleSize = 64.0;
          break;
        case DeviceType.iPadPro13:
          colorCircleSize = 68.0;
          break;
        case DeviceType.desktop:
          colorCircleSize = 72.0;
          break;
      }

      // Récupérer le padding de la barre de navigation système en bas
      final bottomPadding = MediaQuery.of(context).padding.bottom;

      return Column(
        children: [
          // Zone de saisie directe sur le fond coloré
          Expanded(
            child: GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _selectedBackgroundColor.value,
                      _selectedBackgroundColor.value.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding * 1.5,
                      vertical: verticalPadding * 2,
                    ),
                    child: Center(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        maxLength: 500,
                        maxLines: null,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: storyFontSize,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        decoration: InputDecoration(
                          hintText: 'Votre texte ici...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: storyFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          filled: false,
                          fillColor: Colors.transparent,
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Color picker en bas
          Container(
            color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
            padding: EdgeInsets.only(
              left: horizontalPadding,
              right: horizontalPadding,
              top: elementSpacing,
              // Ajouter padding pour la barre de navigation système
              bottom: bottomPadding > 0 ? bottomPadding : elementSpacing,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Color picker
                Text(
                  'Couleur de fond',
                  style: context.textStyle(FontSizeType.subtitle2).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: elementSpacing),
                SizedBox(
                  height: colorCircleSize + 8,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _backgroundColors.length,
                    itemBuilder: (context, index) {
                      final color = _backgroundColors[index];
                      final isSelected = _selectedBackgroundColor.value == color;

                      return GestureDetector(
                        onTap: () => _selectedBackgroundColor.value = color,
                        child: Container(
                          width: colorCircleSize,
                          height: colorCircleSize,
                          margin: EdgeInsets.only(right: elementSpacing),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? Colors.white : Colors.black)
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: colorCircleSize * 0.5,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                // Petit espacement supplémentaire pour éviter que ce soit trop collé en bas
                SizedBox(height: elementSpacing * 0.5),
              ],
            ),
          ),
        ],
      );
    });
  }

  Future<void> _publishTextStory() async {
    final content = _textController.text.trim();
    if (content.isEmpty) return;

    final color = _selectedBackgroundColor.value;
    // Convert to #RRGGBB format (7 characters) without alpha channel
    final colorHex = '#${(color.r * 255).round().toRadixString(16).padLeft(2, '0')}'
        '${(color.g * 255).round().toRadixString(16).padLeft(2, '0')}'
        '${(color.b * 255).round().toRadixString(16).padLeft(2, '0')}';

    final success = await controller.createTextStory(
      content: content,
      backgroundColor: colorHex,
      duration: 5,
    );

    if (success) {
      if (!mounted) return;

      // Navigate back to Home page (until we find it or reach the first route)
      Get.until((route) => route.settings.name == Routes.HOME || route.isFirst);

      // Wait for navigation to complete
      await Future.delayed(const Duration(milliseconds: 150));

      // Change to Feeds/Confession tab (index 3) to show the new story
      try {
        final homeController = Get.find<HomeController>();
        homeController.changeTab(3);
      } catch (e) {
        print('⚠️ HomeController not found, navigating to Home: $e');
        // If HomeController not found, navigate to Home explicitly
        Get.offAllNamed(Routes.HOME);

        // Wait for Home to initialize
        await Future.delayed(const Duration(milliseconds: 200));

        // Try to change tab again
        try {
          final homeController = Get.find<HomeController>();
          homeController.changeTab(3);
        } catch (e) {
          print('⚠️ Unable to change tab after navigation: $e');
        }
      }
    }
  }
}
