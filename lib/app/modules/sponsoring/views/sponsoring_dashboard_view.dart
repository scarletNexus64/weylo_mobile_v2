import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/sponsored_ad_model.dart';
import '../../../widgets/app_theme_system.dart';
import '../controllers/sponsoring_dashboard_controller.dart';
import 'sponsoring_view.dart';

class SponsoringDashboardView extends GetView<SponsoringDashboardController> {
  const SponsoringDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Dashboard sponsoring', style: context.h5),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: controller.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppThemeSystem.primaryColor,
        onPressed: () => Get.to(() => const SponsoringView()),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final error = controller.errorMessage.value;
          if (error != null) {
            return _errorState(context, isDark, error);
          }

          return RefreshIndicator(
            onRefresh: () => controller.load(refresh: true),
            child: ListView(
              padding: EdgeInsets.all(context.horizontalPadding),
              children: [
                _summaryCards(context, isDark),
                SizedBox(height: context.sectionSpacing),
                Text('Mes contenus', style: context.h5),
                SizedBox(height: context.elementSpacing),
                ...controller.sponsorships.map(
                  (s) => _sponsorshipTile(context, isDark, s),
                ),
                if (controller.sponsorships.isEmpty)
                  _emptyState(context, isDark),
                SizedBox(height: 120),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _summaryCards(BuildContext context, bool isDark) {
    Widget card({
      required String title,
      required String value,
      required IconData icon,
      required List<Color> gradient,
    }) {
      return Expanded(
        child: Container(
          padding: EdgeInsets.all(context.elementSpacing),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: context.borderRadius(BorderRadiusType.medium),
            border: Border.all(
              color: isDark
                  ? AppThemeSystem.grey800.withValues(alpha: 0.6)
                  : AppThemeSystem.grey200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white),
              SizedBox(height: context.elementSpacing),
              Text(
                value,
                style: context.h5.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: context.elementSpacing * 0.25),
              Text(
                title,
                style: context.caption.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Obx(() {
      return Row(
        children: [
          card(
            title: 'Audience touchée',
            value: controller.totalDelivered.value.toString(),
            icon: Icons.visibility_outlined,
            gradient: [
              AppThemeSystem.primaryColor.withValues(alpha: 0.92),
              AppThemeSystem.secondaryColor.withValues(alpha: 0.92),
            ],
          ),
          SizedBox(width: context.elementSpacing),
          card(
            title: 'Objectif total',
            value: controller.totalTarget.value.toString(),
            icon: Icons.flag_outlined,
            gradient: [
              const Color(0xFF4CAF50).withValues(alpha: 0.92),
              const Color(0xFF8BC34A).withValues(alpha: 0.92),
            ],
          ),
          SizedBox(width: context.elementSpacing),
          card(
            title: 'Campagnes actives',
            value: controller.activeCount.value.toString(),
            icon: Icons.campaign_outlined,
            gradient: [
              const Color(0xFF2196F3).withValues(alpha: 0.92),
              const Color(0xFF00BCD4).withValues(alpha: 0.92),
            ],
          ),
        ],
      );
    });
  }

  Widget _sponsorshipTile(
    BuildContext context,
    bool isDark,
    SponsoredAdModel s,
  ) {
    final endsAt = s.endsAt;
    final endsText = endsAt == null
        ? 'Sans expiration'
        : 'Expire: ${endsAt.toLocal().toString().split(' ').first}';

    final progress = s.targetReach == 0
        ? 0.0
        : (s.deliveredCount / s.targetReach).clamp(0.0, 1.0);

    final typeLabel = switch (s.mediaType) {
      'image' => 'Image',
      'video' => 'Vidéo',
      _ => 'Texte',
    };

    Widget preview() {
      if (s.mediaUrl != null && (s.mediaType == 'image')) {
        return ClipRRect(
          borderRadius: context.borderRadius(BorderRadiusType.small),
          child: Image.network(
            s.mediaUrl!,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _fallbackPreview(context, s),
          ),
        );
      }
      return _fallbackPreview(context, s);
    }

    return Container(
      margin: EdgeInsets.only(bottom: context.elementSpacing),
      padding: EdgeInsets.all(context.elementSpacing),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: context.borderRadius(BorderRadiusType.medium),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          preview(),
          SizedBox(width: context.elementSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: context.subtitle1.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: context.elementSpacing * 0.25),
                Text(
                  endsText,
                  style: context.caption.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
                SizedBox(height: context.elementSpacing * 0.5),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius:
                            context.borderRadius(BorderRadiusType.small),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: isDark
                              ? AppThemeSystem.grey800.withValues(alpha: 0.6)
                              : AppThemeSystem.grey200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppThemeSystem.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: context.elementSpacing),
                    Text(
                      '${s.deliveredCount}/${s.targetReach}',
                      style: context.caption.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: context.elementSpacing),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor(s.status)
                  .withValues(alpha: isDark ? 0.22 : 0.12),
              borderRadius: context.borderRadius(BorderRadiusType.small),
              border: Border.all(
                color: _statusColor(s.status)
                    .withValues(alpha: isDark ? 0.55 : 0.35),
              ),
            ),
            child: Text(
              _statusLabel(s.status),
              style: context.caption.copyWith(
                color: _statusColor(s.status),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackPreview(BuildContext context, SponsoredAdModel s) {
    final icon = switch (s.mediaType) {
      'image' => Icons.image_outlined,
      'video' => Icons.videocam_outlined,
      _ => Icons.text_fields,
    };
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppThemeSystem.primaryColor, AppThemeSystem.secondaryColor],
        ),
        borderRadius: context.borderRadius(BorderRadiusType.small),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }

  Color _statusColor(String? status) {
    return switch (status) {
      'active' => AppThemeSystem.successColor,
      'completed' => AppThemeSystem.infoColor,
      'paused' => AppThemeSystem.warningColor,
      'cancelled' => AppThemeSystem.errorColor,
      _ => AppThemeSystem.grey600,
    };
  }

  String _statusLabel(String? status) {
    return switch (status) {
      'active' => 'Actif',
      'completed' => 'Terminé',
      'paused' => 'Pause',
      'cancelled' => 'Annulé',
      _ => '—',
    };
  }

  Widget _emptyState(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(context.sectionSpacing),
      decoration: BoxDecoration(
        color: isDark ? AppThemeSystem.darkCardColor : AppThemeSystem.grey50,
        borderRadius: context.borderRadius(BorderRadiusType.medium),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: context.secondaryTextColor),
          SizedBox(width: context.elementSpacing),
          Expanded(
            child: Text(
              'Aucun sponsoring trouvé. Cliquez sur + pour en créer un.',
              style: context.body2.copyWith(color: context.secondaryTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(BuildContext context, bool isDark, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppThemeSystem.errorColor, size: 44),
            SizedBox(height: context.elementSpacing),
            Text('Erreur', style: context.h5),
            SizedBox(height: context.elementSpacing * 0.5),
            Text(
              message,
              style: context.body2.copyWith(color: context.secondaryTextColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.sectionSpacing),
            SizedBox(
              width: double.infinity,
              height: context.buttonHeight,
              child: ElevatedButton(
                onPressed: controller.load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeSystem.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: context.borderRadius(BorderRadiusType.medium),
                  ),
                ),
                child: Text(
                  'Réessayer',
                  style: context.button.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
