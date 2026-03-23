import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/app_theme_system.dart';
import '../../../widgets/verified_badge.dart';
import '../controllers/certification_controller.dart';

class CertificationView extends GetView<CertificationController> {
  const CertificationView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Certification Premium',
          style: context.textStyle(
            FontSizeType.h6,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: context.surfaceColor,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoadingInfo.value || controller.isLoadingStatus.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Si déjà premium, afficher le statut
        if (controller.hasActivePremium.value) {
          return _buildPremiumActiveView(context, isDark, deviceType);
        }

        // Sinon, afficher la page d'achat
        return _buildPurchaseView(context, isDark, deviceType);
      }),
    );
  }

  /// Vue pour les utilisateurs déjà premium
  Widget _buildPremiumActiveView(BuildContext context, bool isDark, DeviceType deviceType) {
    return RefreshIndicator(
      onRefresh: controller.refreshAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(context.horizontalPadding),
        child: Column(
          children: [
            SizedBox(height: context.sectionSpacing),

            // Badge premium
            Container(
              width: deviceType == DeviceType.mobile ? 120 : 150,
              height: deviceType == DeviceType.mobile ? 120 : 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFf35453),
                    Color(0xFFeb316f),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFf35453).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.verified,
                size: deviceType == DeviceType.mobile ? 60 : 75,
                color: Colors.white,
              ),
            ),

            SizedBox(height: context.sectionSpacing),

            // Titre
            Text(
              'Compte Certifié Premium',
              style: context.textStyle(
                FontSizeType.h4,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: context.elementSpacing),

            // Statut
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.horizontalPadding,
                vertical: context.elementSpacing,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: context.borderRadius(BorderRadiusType.medium),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                  SizedBox(width: context.elementSpacing * 0.5),
                  Text(
                    'Actif',
                    style: context.textStyle(
                      FontSizeType.body1,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: context.sectionSpacing),

            // Informations
            Card(
              elevation: context.elevation(ElevationType.low),
              shape: RoundedRectangleBorder(
                borderRadius: context.borderRadius(BorderRadiusType.medium),
              ),
              child: Padding(
                padding: EdgeInsets.all(context.horizontalPadding),
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      'Expire le',
                      _formatDate(controller.premiumExpiresAt.value),
                      Icons.calendar_today,
                    ),
                    Divider(height: context.elementSpacing * 2),
                    _buildInfoRow(
                      context,
                      'Jours restants',
                      '${controller.daysRemaining.value} jours',
                      Icons.hourglass_empty,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: context.sectionSpacing),

            // Bouton Renouveler
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: context.buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: controller.isRenewing.value
                        ? null
                        : () => controller.renewPremium(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeSystem.primaryColor,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: context.borderRadius(BorderRadiusType.medium),
                      ),
                    ),
                    icon: controller.isRenewing.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.refresh, color: Colors.white),
                    label: Text(
                      controller.isRenewing.value ? 'Renouvellement...' : 'Renouveler ma Certification',
                      style: context.textStyle(
                        FontSizeType.button,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )),

            SizedBox(height: context.sectionSpacing),

            // Wallet balance
            Card(
              elevation: context.elevation(ElevationType.low),
              shape: RoundedRectangleBorder(
                borderRadius: context.borderRadius(BorderRadiusType.medium),
              ),
              child: Padding(
                padding: EdgeInsets.all(context.horizontalPadding),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppThemeSystem.primaryColor.withValues(alpha: 0.1),
                        borderRadius: context.borderRadius(BorderRadiusType.small),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: AppThemeSystem.primaryColor,
                      ),
                    ),
                    SizedBox(width: context.elementSpacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Votre solde',
                            style: context.textStyle(
                              FontSizeType.caption,
                              color: context.secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Obx(() => Text(
                                controller.formattedBalance.value,
                                style: context.textStyle(
                                  FontSizeType.h6,
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: context.sectionSpacing),

            // Auto-renew
            Card(
              elevation: context.elevation(ElevationType.low),
              shape: RoundedRectangleBorder(
                borderRadius: context.borderRadius(BorderRadiusType.medium),
              ),
              child: Obx(() => SwitchListTile(
                    title: Text(
                      'Renouvellement automatique',
                      style: context.textStyle(
                        FontSizeType.body1,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Renouveler automatiquement chaque mois',
                      style: context.textStyle(
                        FontSizeType.caption,
                        color: context.secondaryTextColor,
                      ),
                    ),
                    value: controller.autoRenewEnabled.value,
                    onChanged: controller.isTogglingAutoRenew.value
                        ? null
                        : (value) => controller.toggleAutoRenew(value),
                    activeTrackColor: AppThemeSystem.primaryColor.withValues(alpha: 0.5),
                    activeThumbColor: AppThemeSystem.primaryColor,
                  )),
            ),

            SizedBox(height: context.sectionSpacing),

            // Avantages
            _buildFeaturesSection(context, isDark, deviceType),
          ],
        ),
      ),
    );
  }

  /// Vue pour acheter le passe premium
  Widget _buildPurchaseView(BuildContext context, bool isDark, DeviceType deviceType) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.horizontalPadding),
      child: Column(
        children: [
          SizedBox(height: context.sectionSpacing),

          // Header avec dégradé
          Container(
            padding: EdgeInsets.all(context.horizontalPadding * 1.5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFf35453),
                  Color(0xFFeb316f),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: context.borderRadius(BorderRadiusType.large),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFf35453).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const VerifiedBadge(size: 60, showBackground: true),
                SizedBox(height: context.elementSpacing),
                Text(
                  'Devenez Certifié',
                  style: context.textStyle(
                    FontSizeType.h3,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: context.elementSpacing * 0.5),
                Obx(() => Text(
                      controller.formattedPrice.value,
                      style: context.textStyle(
                        FontSizeType.h2,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )),
                SizedBox(height: context.elementSpacing * 0.3),
                Text(
                  'Par mois',
                  style: context.textStyle(
                    FontSizeType.body2,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: context.sectionSpacing),

          // Wallet balance
          Card(
            elevation: context.elevation(ElevationType.low),
            shape: RoundedRectangleBorder(
              borderRadius: context.borderRadius(BorderRadiusType.medium),
            ),
            child: Padding(
              padding: EdgeInsets.all(context.horizontalPadding),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppThemeSystem.primaryColor.withValues(alpha: 0.1),
                      borderRadius: context.borderRadius(BorderRadiusType.small),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: AppThemeSystem.primaryColor,
                    ),
                  ),
                  SizedBox(width: context.elementSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Votre solde',
                          style: context.textStyle(
                            FontSizeType.caption,
                            color: context.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Obx(() => Text(
                              controller.formattedBalance.value,
                              style: context.textStyle(
                                FontSizeType.h6,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: context.sectionSpacing),

          // Avantages
          _buildFeaturesSection(context, isDark, deviceType),

          SizedBox(height: context.sectionSpacing),

          // Bouton d'achat
          Obx(() => SizedBox(
                width: double.infinity,
                height: context.buttonHeight,
                child: ElevatedButton(
                  onPressed: controller.isPurchasing.value
                      ? null
                      : () => controller.purchasePremium(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeSystem.primaryColor,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: context.borderRadius(BorderRadiusType.medium),
                    ),
                  ),
                  child: controller.isPurchasing.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Acheter le Passe Premium',
                          style: context.textStyle(
                            FontSizeType.button,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              )),

          SizedBox(height: context.elementSpacing),

          // Note
          Text(
            'Le paiement sera prélevé de votre wallet. Vous pouvez annuler à tout moment.',
            style: context.textStyle(
              FontSizeType.caption,
              color: context.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: context.sectionSpacing),
        ],
      ),
    );
  }

  /// Section des avantages
  Widget _buildFeaturesSection(BuildContext context, bool isDark, DeviceType deviceType) {
    final features = [
      {
        'icon': Icons.verified,
        'title': 'Badge Bleu Vérifié',
        'description': 'Montrez votre statut premium partout',
      },
      {
        'icon': Icons.visibility,
        'title': 'Voir Toutes les Identités',
        'description': 'Découvrez qui sont vos contacts anonymes',
      },
      {
        'icon': Icons.person_search,
        'title': 'Profils Complets',
        'description': 'Accédez aux noms, photos et infos complètes',
      },
      {
        'icon': Icons.chat_bubble,
        'title': 'Conversations Dévoilées',
        'description': 'Conversations sans mystère',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Avantages Premium',
          style: context.textStyle(
            FontSizeType.h6,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: context.elementSpacing),
        ...features.map((feature) => _buildFeatureItem(
              context,
              feature['icon'] as IconData,
              feature['title'] as String,
              feature['description'] as String,
            )),
      ],
    );
  }

  /// Item d'avantage
  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.elementSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppThemeSystem.primaryColor.withValues(alpha: 0.1),
              borderRadius: context.borderRadius(BorderRadiusType.small),
            ),
            child: Icon(
              icon,
              color: AppThemeSystem.primaryColor,
              size: 24,
            ),
          ),
          SizedBox(width: context.elementSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textStyle(
                    FontSizeType.body1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: context.textStyle(
                    FontSizeType.caption,
                    color: context.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Row d'information
  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.secondaryTextColor),
        SizedBox(width: context.elementSpacing * 0.5),
        Expanded(
          child: Text(
            label,
            style: context.textStyle(
              FontSizeType.body2,
              color: context.secondaryTextColor,
            ),
          ),
        ),
        Text(
          value,
          style: context.textStyle(
            FontSizeType.body1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Formater la date
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;

    return '$day/$month/$year';
  }
}
