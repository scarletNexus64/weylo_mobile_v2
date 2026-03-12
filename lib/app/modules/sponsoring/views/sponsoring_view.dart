import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/sponsorship_checkout_args.dart';
import '../../../widgets/app_theme_system.dart';
import '../controllers/sponsoring_controller.dart';

class SponsoringView extends GetView<SponsoringController> {
  const SponsoringView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Sponsoring', style: context.h5),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: controller.loadPackages,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIntroCard(context, isDark),
              SizedBox(height: context.sectionSpacing),

              Text('1. Choisir le média', style: context.h5),
              SizedBox(height: context.elementSpacing),
              _buildMediaChoices(context, isDark),
              SizedBox(height: context.elementSpacing),
              _buildMediaEditor(context, isDark),

              SizedBox(height: context.sectionSpacing),

              Text('2. Choisir le package', style: context.h5),
              SizedBox(height: context.elementSpacing),
              _buildPackages(context, isDark),

              SizedBox(height: context.sectionSpacing),

              Obx(() {
                final enabled = controller.canContinueToPayment;
                return SizedBox(
                  width: double.infinity,
                  height: context.buttonHeight,
                  child: ElevatedButton(
                    onPressed: enabled ? controller.goToWalletPayment : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeSystem.primaryColor,
                      disabledBackgroundColor:
                          AppThemeSystem.grey400.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: context.borderRadius(
                          BorderRadiusType.medium,
                        ),
                      ),
                    ),
                    child: Text(
                      'Continuer vers le paiement',
                      style: context.button.copyWith(
                        color: AppThemeSystem.whiteColor,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(context.sectionSpacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemeSystem.primaryColor.withValues(alpha: 0.14),
            AppThemeSystem.secondaryColor.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: context.borderRadius(BorderRadiusType.large),
        border: Border.all(
          color: isDark
              ? AppThemeSystem.grey800.withValues(alpha: 0.6)
              : AppThemeSystem.grey200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppThemeSystem.primaryColor,
                  AppThemeSystem.secondaryColor,
                ],
              ),
              borderRadius: context.borderRadius(BorderRadiusType.medium),
            ),
            child: const Icon(
              Icons.campaign,
              color: Colors.white,
            ),
          ),
          SizedBox(width: context.elementSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Boostez votre visibilité', style: context.subtitle1),
                SizedBox(height: context.elementSpacing * 0.5),
                Text(
                  'Choisissez un média et un package. Le paiement se fait via votre Wallet.',
                  style: context.body2.copyWith(color: context.secondaryTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaChoices(BuildContext context, bool isDark) {
    Widget choice({
      required SponsoredMediaType type,
      required IconData icon,
      required String title,
      required String subtitle,
    }) {
      return Obx(() {
        final selected = controller.selectedMediaType.value == type;
        return Expanded(
          child: InkWell(
            onTap: () => controller.chooseMediaType(type),
            borderRadius: context.borderRadius(BorderRadiusType.medium),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: EdgeInsets.all(context.elementSpacing),
              decoration: BoxDecoration(
                color: selected
                    ? AppThemeSystem.primaryColor.withValues(alpha: 0.12)
                    : context.surfaceColor,
                borderRadius: context.borderRadius(BorderRadiusType.medium),
                border: Border.all(
                  color: selected
                      ? AppThemeSystem.primaryColor
                      : (isDark
                          ? AppThemeSystem.grey800.withValues(alpha: 0.6)
                          : AppThemeSystem.grey200),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: selected
                        ? AppThemeSystem.primaryColor
                        : context.secondaryTextColor,
                  ),
                  SizedBox(height: context.elementSpacing * 0.5),
                  Text(title, style: context.body1),
                  SizedBox(height: context.elementSpacing * 0.25),
                  Text(
                    subtitle,
                    style: context.caption,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      });
    }

    return Row(
      children: [
        choice(
          type: SponsoredMediaType.image,
          icon: Icons.image_outlined,
          title: 'Image',
          subtitle: 'Une photo',
        ),
        SizedBox(width: context.elementSpacing),
        choice(
          type: SponsoredMediaType.video,
          icon: Icons.videocam_outlined,
          title: 'Vidéo',
          subtitle: 'Un clip',
        ),
        SizedBox(width: context.elementSpacing),
        choice(
          type: SponsoredMediaType.text,
          icon: Icons.text_fields,
          title: 'Texte',
          subtitle: 'Un message',
        ),
      ],
    );
  }

  Widget _buildMediaEditor(BuildContext context, bool isDark) {
    return Obx(() {
      final type = controller.selectedMediaType.value;
      if (type == null) {
        return _hintBox(context, isDark, 'Sélectionnez un type de média pour continuer.');
      }

      if (type == SponsoredMediaType.text) {
        return Container(
          padding: EdgeInsets.all(context.elementSpacing),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: context.borderRadius(BorderRadiusType.medium),
            border: Border.all(color: context.borderColor),
          ),
          child: TextField(
            controller: controller.textController,
            maxLines: 5,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Écrivez votre texte à sponsoriser...',
            ),
          ),
        );
      }

      final file = controller.pickedMediaFile.value;
      if (file == null) {
        return _hintBox(
          context,
          isDark,
          type == SponsoredMediaType.image
              ? 'Choisissez une image depuis la galerie.'
              : 'Choisissez une vidéo depuis la galerie.',
        );
      }

      if (type == SponsoredMediaType.image) {
        return ClipRRect(
          borderRadius: context.borderRadius(BorderRadiusType.medium),
          child: Image.file(
            File(file.path),
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      }

      // Video preview (simple)
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.sectionSpacing),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: context.borderRadius(BorderRadiusType.medium),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppThemeSystem.grey200,
                borderRadius: context.borderRadius(BorderRadiusType.small),
              ),
              child: const Icon(Icons.play_arrow),
            ),
            SizedBox(width: context.elementSpacing),
            Expanded(
              child: Text(
                file.path.split('/').last,
                style: context.body1,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: controller.pickVideo,
              child: Text('Changer', style: context.body2),
            ),
          ],
        ),
      );
    });
  }

  Widget _hintBox(BuildContext context, bool isDark, String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.elementSpacing),
      decoration: BoxDecoration(
        color: isDark
            ? AppThemeSystem.darkCardColor
            : AppThemeSystem.grey50,
        borderRadius: context.borderRadius(BorderRadiusType.medium),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: context.secondaryTextColor),
          SizedBox(width: context.elementSpacing),
          Expanded(
            child: Text(
              text,
              style: context.body2.copyWith(color: context.secondaryTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackages(BuildContext context, bool isDark) {
    return Obx(() {
      if (controller.isLoadingPackages.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.packages.isEmpty) {
        return _hintBox(context, isDark, 'Aucun package disponible pour le moment.');
      }

      return Column(
        children: controller.packages.map((p) {
          return Obx(() {
            final selected = controller.selectedPackage.value?.id == p.id;
            return InkWell(
              onTap: () => controller.selectedPackage.value = p,
              borderRadius: context.borderRadius(BorderRadiusType.medium),
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: context.elementSpacing),
                padding: EdgeInsets.all(context.sectionSpacing),
                decoration: BoxDecoration(
                  color: selected
                      ? AppThemeSystem.secondaryColor.withValues(alpha: 0.10)
                      : context.surfaceColor,
                  borderRadius: context.borderRadius(BorderRadiusType.medium),
                  border: Border.all(
                    color: selected
                        ? AppThemeSystem.secondaryColor
                        : context.borderColor,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppThemeSystem.primaryColor,
                            AppThemeSystem.secondaryColor,
                          ],
                        ),
                        borderRadius: context.borderRadius(BorderRadiusType.medium),
                      ),
                      child: Icon(
                        selected ? Icons.check : Icons.local_fire_department_outlined,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: context.elementSpacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: context.subtitle1),
                          SizedBox(height: context.elementSpacing * 0.25),
                          Text(
                            '${p.reachLabel} users',
                            style: context.body2.copyWith(
                              color: context.secondaryTextColor,
                            ),
                          ),
                          SizedBox(height: context.elementSpacing * 0.25),
                          Text(
                            'Période: ${p.durationDays} jours',
                            style: context.body2.copyWith(
                              color: context.secondaryTextColor,
                            ),
                          ),
                          if (p.description != null && p.description!.trim().isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: context.elementSpacing * 0.5),
                              child: Text(
                                p.description!,
                                style: context.caption,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: context.elementSpacing),
                    Text(
                      p.formattedPrice,
                      style: context.h6.copyWith(
                        color: AppThemeSystem.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        }).toList(),
      );
    });
  }
}
