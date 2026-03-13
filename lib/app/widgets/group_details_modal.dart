import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/models/group_model.dart';
import '../modules/groupe/controllers/groupe_controller.dart';
import 'app_theme_system.dart';

/// Cache pour éviter les fuites mémoire
class _GroupDetailsCache {
  static const avatarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppThemeSystem.tertiaryColor,
      AppThemeSystem.primaryColor,
    ],
  );

  static const buttonGradient = LinearGradient(
    colors: [
      AppThemeSystem.tertiaryColor,
      AppThemeSystem.primaryColor,
    ],
  );

  static const dialogButtonGradient = LinearGradient(
    colors: [
      AppThemeSystem.tertiaryColor,
      AppThemeSystem.secondaryColor,
    ],
  );

  // Couleurs avec alpha en cache
  static final grey800Alpha04 = AppThemeSystem.grey800.withValues(alpha: 0.4);
  static final grey800Alpha03 = AppThemeSystem.grey800.withValues(alpha: 0.3);
  static final grey700Alpha05 = AppThemeSystem.grey700.withValues(alpha: 0.5);
  static final grey700Alpha03 = AppThemeSystem.grey700.withValues(alpha: 0.3);
  static final tertiaryAlpha03 = AppThemeSystem.tertiaryColor.withValues(alpha: 0.3);
  static final tertiaryAlpha01 = AppThemeSystem.tertiaryColor.withValues(alpha: 0.1);
  static final successAlpha01 = AppThemeSystem.successColor.withValues(alpha: 0.1);
  static final successAlpha03 = AppThemeSystem.successColor.withValues(alpha: 0.3);
  static final warningAlpha01 = AppThemeSystem.warningColor.withValues(alpha: 0.1);
  static final warningAlpha03 = AppThemeSystem.warningColor.withValues(alpha: 0.3);
  static final errorAlpha01 = AppThemeSystem.errorColor.withValues(alpha: 0.1);
  static final errorAlpha03 = AppThemeSystem.errorColor.withValues(alpha: 0.3);
}

/// Modal Discord-style pour afficher les détails d'un groupe
class GroupDetailsModal extends StatelessWidget {
  final GroupModel group;
  final GroupeController controller;

  const GroupDetailsModal({
    super.key,
    required this.group,
    required this.controller,
  });

  /// Affiche le modal avec animation slide-up
  static void show(BuildContext context, GroupModel group, GroupeController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GroupDetailsModal(
        group: group,
        controller: controller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomInsets = MediaQuery.of(context).viewInsets.bottom;

    // Hauteur adaptative selon le device
    final modalHeight = deviceType == DeviceType.mobile
        ? screenHeight * 0.75
        : deviceType == DeviceType.tablet
            ? screenHeight * 0.65
            : screenHeight * 0.6;

    return Container(
      height: modalHeight,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(
            AppThemeSystem.getBorderRadius(context, BorderRadiusType.large),
          ),
          topRight: Radius.circular(
            AppThemeSystem.getBorderRadius(context, BorderRadiusType.large),
          ),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          _buildHandleBar(context),

          // Contenu scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: context.horizontalPadding * 2,
                right: context.horizontalPadding * 2,
                top: context.verticalPadding,
                bottom: context.verticalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar et nom du groupe
                  _buildGroupHeader(context, isDark),

                  SizedBox(height: deviceType == DeviceType.mobile ? 12 : context.elementSpacing),

                  // Badges (Public/Privé, Catégorie)
                  _buildBadges(context, isDark),

                  SizedBox(height: deviceType == DeviceType.mobile ? 16 : context.sectionSpacing),

                  // Description
                  if (group.description != null && group.description!.isNotEmpty) ...[
                    _buildDescription(context, isDark),
                    SizedBox(height: deviceType == DeviceType.mobile ? 16 : context.sectionSpacing),
                  ],

                  // Stats
                  _buildStats(context, isDark),

                  SizedBox(height: deviceType == DeviceType.mobile ? 20 : context.sectionSpacing * 1.5),

                  // Bouton d'action
                  _buildActionButton(context, isDark),

                  // Espace pour la barre de navigation système (triangle, cercle, carré)
                  SizedBox(
                    height: bottomPadding > 0
                      ? bottomPadding + 16
                      : bottomInsets > 0
                        ? bottomInsets + 16
                        : 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle bar en haut du modal
  Widget _buildHandleBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// En-tête avec avatar et nom du groupe
  Widget _buildGroupHeader(BuildContext context, bool isDark) {
    final deviceType = context.deviceType;
    final avatarSize = deviceType == DeviceType.mobile ? 64.0 : 80.0;

    return Row(
      children: [
        // Avatar du groupe
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            gradient: _GroupDetailsCache.avatarGradient,
            borderRadius: BorderRadius.circular(
              AppThemeSystem.getBorderRadius(context, BorderRadiusType.large),
            ),
            boxShadow: [
              BoxShadow(
                color: _GroupDetailsCache.tertiaryAlpha03,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              group.name.length < 2
                  ? group.name.toUpperCase()
                  : group.name.substring(0, 2).toUpperCase(),
              style: context.textStyle(
                deviceType == DeviceType.mobile ? FontSizeType.h4 : FontSizeType.h3
              ).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Nom du groupe
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.name,
                style: context.textStyle(
                  deviceType == DeviceType.mobile ? FontSizeType.h5 : FontSizeType.h4
                ).copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.primaryTextColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Créé le ${_formatDate(group.createdAt)}',
                style: context.textStyle(FontSizeType.caption).copyWith(
                  color: context.secondaryTextColor,
                  fontSize: deviceType == DeviceType.mobile ? 11 : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Badges (Public/Privé, Catégorie)
  Widget _buildBadges(BuildContext context, bool isDark) {
    final deviceType = context.deviceType;
    final badgePadding = deviceType == DeviceType.mobile
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    final iconSize = deviceType == DeviceType.mobile ? 12.0 : 14.0;
    final spacing = deviceType == DeviceType.mobile ? 4.0 : 6.0;

    return Wrap(
      spacing: deviceType == DeviceType.mobile ? 6 : 8,
      runSpacing: deviceType == DeviceType.mobile ? 6 : 8,
      children: [
        // Badge Public/Privé
        Container(
          padding: badgePadding,
          decoration: BoxDecoration(
            color: group.isPublic
                ? _GroupDetailsCache.successAlpha01
                : _GroupDetailsCache.warningAlpha01,
            borderRadius: BorderRadius.circular(
              AppThemeSystem.getBorderRadius(context, BorderRadiusType.medium),
            ),
            border: Border.all(
              color: group.isPublic
                  ? _GroupDetailsCache.successAlpha03
                  : _GroupDetailsCache.warningAlpha03,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                group.isPublic ? Icons.public : Icons.lock_rounded,
                size: iconSize,
                color: group.isPublic
                    ? AppThemeSystem.successColor
                    : AppThemeSystem.warningColor,
              ),
              SizedBox(width: spacing),
              Text(
                group.isPublic ? 'Public' : 'Privé',
                style: context.textStyle(FontSizeType.caption).copyWith(
                  color: group.isPublic
                      ? AppThemeSystem.successColor
                      : AppThemeSystem.warningColor,
                  fontWeight: FontWeight.w600,
                  fontSize: deviceType == DeviceType.mobile ? 11 : null,
                ),
              ),
            ],
          ),
        ),

        // Badge Catégorie (si disponible)
        if (group.category != null)
          Container(
            padding: badgePadding,
            decoration: BoxDecoration(
              color: _parseColor(group.category!.color ?? '#9E9E9E').withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(
                AppThemeSystem.getBorderRadius(context, BorderRadiusType.medium),
              ),
              border: Border.all(
                color: _parseColor(group.category!.color ?? '#9E9E9E').withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (group.category!.iconData != null)
                  Icon(
                    group.category!.iconData,
                    size: deviceType == DeviceType.mobile ? 12 : 14,
                    color: _parseColor(group.category!.color ?? '#9E9E9E'),
                  )
                else
                  Text(
                    group.category!.emojiIcon,
                    style: TextStyle(fontSize: deviceType == DeviceType.mobile ? 10 : 12),
                  ),
                SizedBox(width: spacing),
                Text(
                  group.category!.name,
                  style: context.textStyle(FontSizeType.caption).copyWith(
                    color: _parseColor(group.category!.color ?? '#9E9E9E'),
                    fontWeight: FontWeight.w600,
                    fontSize: deviceType == DeviceType.mobile ? 11 : null,
                  ),
                ),
              ],
            ),
          ),

        // Badge "Complet" si le groupe est plein
        if (group.isFull)
          Container(
            padding: badgePadding,
            decoration: BoxDecoration(
              color: _GroupDetailsCache.errorAlpha01,
              borderRadius: BorderRadius.circular(
                AppThemeSystem.getBorderRadius(context, BorderRadiusType.medium),
              ),
              border: Border.all(
                color: _GroupDetailsCache.errorAlpha03,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_rounded,
                  size: iconSize,
                  color: AppThemeSystem.errorColor,
                ),
                SizedBox(width: spacing),
                Text(
                  'Complet',
                  style: context.textStyle(FontSizeType.caption).copyWith(
                    color: AppThemeSystem.errorColor,
                    fontWeight: FontWeight.w600,
                    fontSize: deviceType == DeviceType.mobile ? 11 : null,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Section description
  Widget _buildDescription(BuildContext context, bool isDark) {
    final deviceType = context.deviceType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'À propos',
          style: context.textStyle(FontSizeType.h6).copyWith(
            fontWeight: FontWeight.bold,
            color: context.primaryTextColor,
          ),
        ),
        SizedBox(height: deviceType == DeviceType.mobile ? 6 : 8),
        Container(
          padding: deviceType == DeviceType.mobile
              ? const EdgeInsets.all(12)
              : const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? _GroupDetailsCache.grey800Alpha03
                : AppThemeSystem.grey100,
            borderRadius: BorderRadius.circular(
              AppThemeSystem.getBorderRadius(context, BorderRadiusType.medium),
            ),
            border: Border.all(
              color: isDark
                  ? _GroupDetailsCache.grey700Alpha03
                  : AppThemeSystem.grey200,
              width: 1,
            ),
          ),
          child: Text(
            group.description!,
            style: context.textStyle(FontSizeType.body2).copyWith(
              color: context.primaryTextColor,
              height: 1.4,
              fontSize: deviceType == DeviceType.mobile ? 13 : null,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Section statistiques
  Widget _buildStats(BuildContext context, bool isDark) {
    final deviceType = context.deviceType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiques',
          style: context.textStyle(FontSizeType.h6).copyWith(
            fontWeight: FontWeight.bold,
            color: context.primaryTextColor,
          ),
        ),
        SizedBox(height: deviceType == DeviceType.mobile ? 8 : 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context: context,
                isDark: isDark,
                icon: Icons.people_rounded,
                label: 'Membres',
                value: '${group.membersCount}',
                color: AppThemeSystem.infoColor,
              ),
            ),
            SizedBox(width: deviceType == DeviceType.mobile ? 8 : 12),
            Expanded(
              child: _buildStatCard(
                context: context,
                isDark: isDark,
                icon: Icons.groups_rounded,
                label: 'Capacité',
                value: '${group.maxMembers}',
                color: AppThemeSystem.tertiaryColor,
              ),
            ),
          ],
        ),

        // Barre de progression
        SizedBox(height: deviceType == DeviceType.mobile ? 12 : 16),
        _buildProgressBar(context, isDark),
      ],
    );
  }

  /// Carte de stat individuelle
  Widget _buildStatCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final deviceType = context.deviceType;

    return Container(
      padding: deviceType == DeviceType.mobile
          ? const EdgeInsets.all(12)
          : const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? _GroupDetailsCache.grey800Alpha03
            : AppThemeSystem.grey100,
        borderRadius: BorderRadius.circular(
          AppThemeSystem.getBorderRadius(context, BorderRadiusType.medium),
        ),
        border: Border.all(
          color: isDark
              ? _GroupDetailsCache.grey700Alpha03
              : AppThemeSystem.grey200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: deviceType == DeviceType.mobile ? 24 : 28,
          ),
          SizedBox(height: deviceType == DeviceType.mobile ? 6 : 8),
          Text(
            value,
            style: context.textStyle(FontSizeType.h5).copyWith(
              fontWeight: FontWeight.bold,
              color: context.primaryTextColor,
            ),
          ),
          SizedBox(height: deviceType == DeviceType.mobile ? 2 : 4),
          Text(
            label,
            style: context.textStyle(FontSizeType.caption).copyWith(
              color: context.secondaryTextColor,
              fontSize: deviceType == DeviceType.mobile ? 11 : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Barre de progression des membres
  Widget _buildProgressBar(BuildContext context, bool isDark) {
    final deviceType = context.deviceType;

    // Éviter la division par zéro
    if (group.maxMembers == 0) {
      return const SizedBox.shrink();
    }

    final progress = group.membersCount / group.maxMembers;
    final percentage = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Taux de remplissage',
              style: context.textStyle(FontSizeType.caption).copyWith(
                color: context.secondaryTextColor,
                fontSize: deviceType == DeviceType.mobile ? 11 : null,
              ),
            ),
            Text(
              '$percentage%',
              style: context.textStyle(FontSizeType.caption).copyWith(
                color: context.primaryTextColor,
                fontWeight: FontWeight.w600,
                fontSize: deviceType == DeviceType.mobile ? 11 : null,
              ),
            ),
          ],
        ),
        SizedBox(height: deviceType == DeviceType.mobile ? 6 : 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: deviceType == DeviceType.mobile ? 6 : 8,
            backgroundColor: isDark
                ? AppThemeSystem.grey700.withValues(alpha: 0.3)
                : AppThemeSystem.grey200,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 0.9
                  ? AppThemeSystem.errorColor
                  : progress >= 0.7
                      ? AppThemeSystem.warningColor
                      : AppThemeSystem.successColor,
            ),
          ),
        ),
      ],
    );
  }

  /// Bouton d'action principal
  Widget _buildActionButton(BuildContext context, bool isDark) {
    // Si l'utilisateur est déjà membre
    if (group.isMember == true) {
      return _buildOutlinedButton(
        context: context,
        isDark: isDark,
        label: 'Voir les messages',
        icon: Icons.forum_rounded,
        onPressed: () {
          Get.back();
          // Navigation vers la page de conversation du groupe
          // Get.toNamed(Routes.GROUP_CHAT, arguments: group.id);
        },
      );
    }

    // Si le groupe est complet
    if (group.isFull) {
      return _buildOutlinedButton(
        context: context,
        isDark: isDark,
        label: 'Groupe complet',
        icon: Icons.block_rounded,
        onPressed: null, // Désactivé
      );
    }

    // Si c'est un groupe privé
    if (!group.isPublic) {
      return _buildGradientButton(
        context: context,
        label: 'Rejoindre avec un code',
        icon: Icons.vpn_key_rounded,
        onPressed: () {
          Get.back();
          _showInviteCodeDialog(context);
        },
      );
    }

    // Si c'est un groupe public
    return _buildGradientButton(
      context: context,
      label: 'Rejoindre le groupe',
      icon: Icons.add_rounded,
      onPressed: () async {
        Get.back();
        await controller.joinGroupById(group.id);
      },
    );
  }

  /// Bouton avec gradient
  Widget _buildGradientButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: context.buttonHeight,
      decoration: BoxDecoration(
        gradient: _GroupDetailsCache.buttonGradient,
        borderRadius: BorderRadius.circular(
          AppThemeSystem.getBorderRadius(context, BorderRadiusType.medium),
        ),
        boxShadow: [
          BoxShadow(
            color: _GroupDetailsCache.tertiaryAlpha03,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(
            AppThemeSystem.getBorderRadius(context, BorderRadiusType.medium),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: context.textStyle(FontSizeType.button).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bouton outlined
  Widget _buildOutlinedButton({
    required BuildContext context,
    required bool isDark,
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final isDisabled = onPressed == null;

    return Container(
      width: double.infinity,
      height: context.buttonHeight,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(
          AppThemeSystem.getBorderRadius(context, BorderRadiusType.medium),
        ),
        border: Border.all(
          color: isDisabled
              ? (isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300)
              : AppThemeSystem.tertiaryColor,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(
            AppThemeSystem.getBorderRadius(context, BorderRadiusType.medium),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isDisabled
                      ? context.secondaryTextColor
                      : AppThemeSystem.tertiaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: context.textStyle(FontSizeType.button).copyWith(
                    color: isDisabled
                        ? context.secondaryTextColor
                        : AppThemeSystem.tertiaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Affiche un dialog pour saisir le code d'invitation
  void _showInviteCodeDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController codeController = TextEditingController();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(
              AppThemeSystem.getBorderRadius(context, BorderRadiusType.large),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              Text(
                'Code d\'invitation',
                style: context.textStyle(FontSizeType.h5).copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.primaryTextColor,
                ),
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                'Entrez le code d\'invitation pour rejoindre ce groupe privé.',
                style: context.textStyle(FontSizeType.body2).copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 20),
              // TextField
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  hintText: 'Code d\'invitation',
                  hintStyle: context.textStyle(FontSizeType.body2).copyWith(
                    color: AppThemeSystem.grey600,
                  ),
                  prefixIcon: const Icon(
                    Icons.pin_rounded,
                    color: AppThemeSystem.tertiaryColor,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? _GroupDetailsCache.grey800Alpha04
                      : AppThemeSystem.grey100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? _GroupDetailsCache.grey700Alpha05
                          : AppThemeSystem.grey200,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? _GroupDetailsCache.grey700Alpha05
                          : AppThemeSystem.grey200,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppThemeSystem.tertiaryColor,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: context.textStyle(FontSizeType.body2).copyWith(
                  color: isDark ? Colors.white : AppThemeSystem.blackColor,
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 8,
              ),
              const SizedBox(height: 24),
              // Boutons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Get.back();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppThemeSystem.grey700,
                        side: BorderSide(
                          color: isDark
                              ? AppThemeSystem.grey700
                              : AppThemeSystem.grey300,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Annuler',
                        style: context.textStyle(FontSizeType.button).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: _GroupDetailsCache.dialogButtonGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _GroupDetailsCache.tertiaryAlpha03,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final code = codeController.text.trim();
                            if (code.isNotEmpty) {
                              Get.back();
                              await controller.joinGroupByCode(code);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            alignment: Alignment.center,
                            child: Text(
                              'Rejoindre',
                              style: context.textStyle(FontSizeType.button).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      // S'assurer que le controller est toujours disposé, peu importe comment le dialog est fermé
      codeController.dispose();
    });
  }

  /// Formater la date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'Aujourd\'hui';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Il y a $years an${years > 1 ? 's' : ''}';
    }
  }

  /// Parser la couleur hexadécimale
  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppThemeSystem.grey500;
    }
  }
}
