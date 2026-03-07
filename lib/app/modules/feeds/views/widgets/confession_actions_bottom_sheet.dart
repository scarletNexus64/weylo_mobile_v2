import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import 'package:weylo/app/data/models/confession_model.dart';
import 'package:weylo/app/data/services/confession_service.dart';
import 'package:weylo/app/data/services/storage_service.dart';

class ConfessionActionsBottomSheet extends StatelessWidget {
  final ConfessionModel confession;
  final VoidCallback? onDeleted;
  final VoidCallback? onEdited;
  final VoidCallback? onFavoriteToggled;
  final VoidCallback? onIdentityRevealed;

  const ConfessionActionsBottomSheet({
    super.key,
    required this.confession,
    this.onDeleted,
    this.onEdited,
    this.onFavoriteToggled,
    this.onIdentityRevealed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;
    final storageService = StorageService();
    final currentUser = storageService.getUser();

    // Check if this confession belongs to the current user
    final isMyPost = confession.author != null &&
                     currentUser != null &&
                     confession.author!.id == currentUser.id;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.elementSpacing * 1.5,
                vertical: context.elementSpacing,
              ),
              child: Text(
                'Actions',
                style: context.textStyle(FontSizeType.h6).copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppThemeSystem.blackColor,
                ),
              ),
            ),

            const Divider(height: 1),

            // Actions
            if (isMyPost) ..._buildMyPostActions(context, isDark, deviceType)
            else ..._buildOthersPostActions(context, isDark, deviceType),

            SizedBox(height: context.elementSpacing),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMyPostActions(BuildContext context, bool isDark, DeviceType deviceType) {
    return [
      _buildActionTile(
        context: context,
        icon: Icons.edit_outlined,
        label: 'Modifier',
        isDark: isDark,
        deviceType: deviceType,
        onTap: () {
          Get.back();
          _handleEdit(context);
        },
      ),
      _buildActionTile(
        context: context,
        icon: Icons.share_outlined,
        label: 'Partager',
        isDark: isDark,
        deviceType: deviceType,
        onTap: () {
          Get.back();
          _handleShare(context);
        },
      ),
      _buildActionTile(
        context: context,
        icon: Icons.delete_outline_rounded,
        label: 'Supprimer',
        isDark: isDark,
        deviceType: deviceType,
        color: AppThemeSystem.errorColor,
        onTap: () {
          Get.back();
          _handleDelete(context);
        },
      ),
    ];
  }

  List<Widget> _buildOthersPostActions(BuildContext context, bool isDark, DeviceType deviceType) {
    final actions = <Widget>[
      _buildActionTile(
        context: context,
        icon: Icons.bookmark_outline_rounded,
        label: 'Enregistrer',
        isDark: isDark,
        deviceType: deviceType,
        onTap: () {
          Get.back();
          _handleToggleFavorite(context);
        },
      ),
      _buildActionTile(
        context: context,
        icon: Icons.share_outlined,
        label: 'Partager',
        isDark: isDark,
        deviceType: deviceType,
        onTap: () {
          Get.back();
          _handleShare(context);
        },
      ),
    ];

    // Add reveal identity option only for anonymous posts
    if (!confession.isIdentityRevealed && confession.author != null) {
      actions.insert(
        1,
        _buildActionTile(
          context: context,
          icon: Icons.visibility_outlined,
          label: 'Dévoiler l\'auteur',
          isDark: isDark,
          deviceType: deviceType,
          onTap: () {
            Get.back();
            _handleRevealIdentity(context);
          },
        ),
      );
    }

    return actions;
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isDark,
    required DeviceType deviceType,
    required VoidCallback onTap,
    Color? color,
  }) {
    final actionColor = color ?? (isDark ? AppThemeSystem.grey300 : AppThemeSystem.grey800);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.elementSpacing * 1.5,
          vertical: context.elementSpacing * 1.2,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: deviceType == DeviceType.mobile ? 24 : 28,
              color: actionColor,
            ),
            SizedBox(width: context.elementSpacing * 1.5),
            Expanded(
              child: Text(
                label,
                style: context.textStyle(FontSizeType.body1).copyWith(
                  color: actionColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Action handlers
  void _handleEdit(BuildContext context) {
    // Navigate to edit page
    Get.toNamed('/edit-confession', arguments: confession);
    onEdited?.call();
  }

  void _handleShare(BuildContext context) {
    final shareText = confession.content.isNotEmpty
        ? confession.content
        : 'Découvrez cette confession sur Weylo';

    Share.share(shareText);
  }

  void _handleDelete(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Supprimer la confession'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette confession ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppThemeSystem.grey600),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // Close dialog

              try {
                final confessionService = ConfessionService();
                await confessionService.deleteConfession(confession.id);

                Get.snackbar(
                  'Supprimée',
                  'La confession a été supprimée avec succès',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppThemeSystem.successColor,
                  colorText: Colors.white,
                );

                onDeleted?.call();
              } catch (e) {
                Get.snackbar(
                  'Erreur',
                  'Impossible de supprimer la confession',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppThemeSystem.errorColor,
                  colorText: Colors.white,
                );
              }
            },
            child: Text(
              'Supprimer',
              style: TextStyle(color: AppThemeSystem.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  void _handleToggleFavorite(BuildContext context) async {
    try {
      final confessionService = ConfessionService();
      await confessionService.toggleFavorite(confession.id);

      Get.snackbar(
        'Enregistrée',
        'La confession a été ajoutée à vos favoris',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.successColor,
        colorText: Colors.white,
      );

      onFavoriteToggled?.call();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'enregistrer la confession',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.errorColor,
        colorText: Colors.white,
      );
    }
  }

  void _handleRevealIdentity(BuildContext context) async {
    try {
      final confessionService = ConfessionService();
      final authorInfo = await confessionService.revealIdentity(confession.id);

      Get.dialog(
        AlertDialog(
          title: const Text('Auteur dévoilé'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nom: ${authorInfo['name']}'),
              const SizedBox(height: 8),
              Text('Username: @${authorInfo['username']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );

      onIdentityRevealed?.call();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de dévoiler l\'identité',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.errorColor,
        colorText: Colors.white,
      );
    }
  }
}
