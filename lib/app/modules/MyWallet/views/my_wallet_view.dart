import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/my_wallet_controller.dart';
import '../../../widgets/app_theme_system.dart';
import '../../../data/models/sponsorship_checkout_args.dart';

class MyWalletView extends GetView<MyWalletController> {
  const MyWalletView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.initFromArgs(Get.arguments);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Mon Wallet', style: context.h5),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refresh,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            slivers: [
              // Sponsoring checkout intent (optional)
              SliverToBoxAdapter(
                child: Obx(() {
                  final intent = controller.pendingSponsorship.value;
                  if (intent == null) return const SizedBox.shrink();
                  return _buildSponsoringCheckoutCard(context, intent);
                }),
              ),

              // Balance Card
              SliverToBoxAdapter(
                child: _buildBalanceCard(context),
              ),

              // Quick Actions
              SliverToBoxAdapter(
                child: _buildQuickActions(context),
              ),

              // Pending Withdrawals (visible on wallet screen)
              SliverToBoxAdapter(
                child: Obx(() {
                  if (controller.withdrawals.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    margin: EdgeInsets.fromLTRB(
                      context.horizontalPadding,
                      context.elementSpacing,
                      context.horizontalPadding,
                      0,
                    ),
                    padding: EdgeInsets.all(context.sectionSpacing),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: context.borderRadius(BorderRadiusType.large),
                      border: Border.all(
                        color: AppThemeSystem.warningColor.withOpacity(0.25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Retraits en attente', style: context.h6),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 20),
                                  onPressed: () =>
                                      controller.loadWithdrawals(status: 'pending'),
                                  tooltip: 'Rafraîchir',
                                ),
                                TextButton(
                                  onPressed: () => Get.toNamed('/my-wallet/withdraw'),
                                  child: Text('Voir', style: context.body2),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: context.elementSpacing * 0.5),
                        Text(
                          'Mise à jour automatique pendant le traitement.',
                          style: context.caption
                              .copyWith(color: context.secondaryTextColor),
                        ),
                        SizedBox(height: context.elementSpacing),
                        ...controller.withdrawals.take(3).map((w) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: context.elementSpacing * 0.5,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin: EdgeInsets.only(
                                    top: context.elementSpacing * 0.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppThemeSystem.warningColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: context.elementSpacing),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            w.formattedAmount,
                                            style: context.body1.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: context.elementSpacing,
                                              vertical:
                                                  context.elementSpacing * 0.25,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppThemeSystem.warningColor
                                                  .withOpacity(0.1),
                                              borderRadius: context.borderRadius(
                                                  BorderRadiusType.medium),
                                            ),
                                            child: Text(
                                              w.statusLabel,
                                              style: context.caption.copyWith(
                                                color:
                                                    AppThemeSystem.warningColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: context.elementSpacing * 0.25),
                                      Text(
                                        '${w.providerIcon} ${w.providerName}  ${w.phoneNumber}',
                                        style: context.body2.copyWith(
                                          color: context.secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (controller.withdrawals.length > 3)
                          Text(
                            '+${controller.withdrawals.length - 3} autre(s)…',
                            style: context.caption
                                .copyWith(color: context.secondaryTextColor),
                          ),
                      ],
                    ),
                  );
                }),
              ),

              // Stats Cards
              SliverToBoxAdapter(
                child: _buildStatsCards(context),
              ),

              // Transaction History Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(context.horizontalPadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Historique des transactions', style: context.h5),
                      TextButton(
                        onPressed: () => controller.filterByType(null),
                        child: Text('Tout voir', style: context.body2),
                      ),
                    ],
                  ),
                ),
              ),

              // Filter Chips
              SliverToBoxAdapter(
                child: _buildFilterChips(context),
              ),

              // Transaction List
              Obx(() {
                if (controller.isLoadingTransactions.value &&
                    controller.transactions.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (controller.transactions.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long,
                              size: 64, color: context.secondaryTextColor),
                          SizedBox(height: context.elementSpacing),
                          Text(
                            'Aucune transaction',
                            style: context.body1
                                .copyWith(color: context.secondaryTextColor),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == controller.transactions.length) {
                        // Load more indicator
                        if (controller.currentPage.value <
                            controller.lastPage.value) {
                          return Padding(
                            padding: EdgeInsets.all(context.horizontalPadding),
                            child: Center(
                              child: ElevatedButton(
                                onPressed: () =>
                                    controller.loadTransactions(loadMore: true),
                                child: controller.isLoadingMore.value
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : Text('Charger plus', style: context.button),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }

                      final transaction = controller.transactions[index];
                      return _buildTransactionItem(context, transaction);
                    },
                    childCount: controller.transactions.length + 1,
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(context.horizontalPadding),
      padding: EdgeInsets.all(context.sectionSpacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemeSystem.primaryColor,
            AppThemeSystem.secondaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: context.borderRadius(BorderRadiusType.large),
        boxShadow: [
          BoxShadow(
            color: AppThemeSystem.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solde disponible',
            style: context.body2.copyWith(
              color: AppThemeSystem.whiteColor.withOpacity(0.9),
            ),
          ),
          SizedBox(height: context.elementSpacing * 0.5),
          Obx(() => Text(
                controller.formattedBalance,
                style: context.h2.copyWith(
                  color: AppThemeSystem.whiteColor,
                ),
              )),
          SizedBox(height: context.elementSpacing),
          Row(
            children: [
              Icon(Icons.account_balance_wallet,
                  color: AppThemeSystem.whiteColor.withOpacity(0.8),
                  size: context.deviceType == DeviceType.mobile ? 16 : 20),
              SizedBox(width: context.elementSpacing * 0.5),
              Obx(() => Text(
                    controller.wallet.value?.currency ?? 'XAF',
                    style: context.caption.copyWith(
                      color: AppThemeSystem.whiteColor.withOpacity(0.8),
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSponsoringCheckoutCard(
    BuildContext context,
    SponsorshipCheckoutArgs intent,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String mediaLabel;
    switch (intent.mediaType) {
      case SponsoredMediaType.text:
        mediaLabel = 'Texte';
        break;
      case SponsoredMediaType.image:
        mediaLabel = 'Image';
        break;
      case SponsoredMediaType.video:
        mediaLabel = 'Vidéo';
        break;
    }

    return Container(
      margin: EdgeInsets.fromLTRB(
        context.horizontalPadding,
        context.horizontalPadding,
        context.horizontalPadding,
        0,
      ),
      padding: EdgeInsets.all(context.sectionSpacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemeSystem.secondaryColor.withValues(alpha: 0.16),
            AppThemeSystem.primaryColor.withValues(alpha: 0.12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign, color: AppThemeSystem.primaryColor),
              SizedBox(width: context.elementSpacing * 0.5),
              Expanded(
                child: Text('Paiement Sponsoring', style: context.h6),
              ),
              IconButton(
                onPressed: controller.clearPendingSponsorship,
                icon: Icon(Icons.close, color: context.secondaryTextColor),
              ),
            ],
          ),
          SizedBox(height: context.elementSpacing * 0.5),
          Text(
            intent.packageName,
            style: context.subtitle1.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: context.elementSpacing * 0.25),
          Text(
            'Audience: ${intent.reachLabel} users | Média: $mediaLabel',
            style: context.body2.copyWith(color: context.secondaryTextColor),
          ),
          SizedBox(height: context.elementSpacing * 0.25),
          Text(
            'Période: ${intent.durationDays} jours',
            style: context.body2.copyWith(color: context.secondaryTextColor),
          ),
          SizedBox(height: context.elementSpacing),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${intent.price} FCFA',
                  style: context.h5.copyWith(
                    color: AppThemeSystem.primaryColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Obx(() {
                final loading = controller.isProcessingPayment.value;
                final buttonWidth =
                    context.deviceType == DeviceType.mobile ? 120.0 : 140.0;
                final buttonHeight =
                    context.deviceType == DeviceType.mobile ? 44.0 : 48.0;

                return SizedBox(
                  width: buttonWidth,
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: loading ? null : controller.payPendingSponsorship,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeSystem.primaryColor,
                      minimumSize: Size(0, buttonHeight),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            context.borderRadius(BorderRadiusType.medium),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Payer',
                            style: context.button.copyWith(
                              color: AppThemeSystem.whiteColor,
                            ),
                          ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              context,
              icon: Icons.add_circle_outline,
              label: 'Dépôt',
              color: AppThemeSystem.successColor,
              onTap: () => Get.toNamed('/my-wallet/deposit'),
            ),
          ),
          SizedBox(width: context.elementSpacing),
          Expanded(
            child: _buildActionButton(
              context,
              icon: Icons.remove_circle_outline,
              label: 'Retrait',
              color: AppThemeSystem.warningColor,
              onTap: () => Get.toNamed('/my-wallet/withdraw'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: context.borderRadius(BorderRadiusType.medium),
      child: Container(
        padding: EdgeInsets.all(context.horizontalPadding),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: context.borderRadius(BorderRadiusType.medium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            SizedBox(width: context.elementSpacing * 0.5),
            Text(
              label,
              style: context.body1.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    return Obx(() {
      final stats = controller.wallet.value?.stats;
      if (stats == null) return const SizedBox.shrink();

      return Padding(
        padding: EdgeInsets.all(context.horizontalPadding),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.arrow_downward,
                label: 'Revenus totaux',
                value: '${stats.totalEarnings.toStringAsFixed(0)} FCFA',
                color: AppThemeSystem.successColor,
              ),
            ),
            SizedBox(width: context.elementSpacing),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.arrow_upward,
                label: 'Retraits totaux',
                value: '${stats.totalWithdrawals.toStringAsFixed(0)} FCFA',
                color: AppThemeSystem.warningColor,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(context.horizontalPadding),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: context.borderRadius(BorderRadiusType.medium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: context.elementSpacing * 0.5),
          Text(label, style: context.caption),
          SizedBox(height: context.elementSpacing * 0.25),
          Text(
            value,
            style: context.body2.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return Obx(() => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
          child: Row(
            children: [
              _buildFilterChip(context, 'Tout', null),
              _buildFilterChip(context, 'Dépôt', 'deposit'),
              _buildFilterChip(context, 'Retrait', 'withdrawal'),
            ],
          ),
        ));
  }

  Widget _buildFilterChip(BuildContext context, String label, String? type) {
    final isSelected = controller.selectedType.value == type;

    return Padding(
      padding: EdgeInsets.only(right: context.elementSpacing * 0.5),
      child: FilterChip(
        label: Text(label, style: context.body2),
        selected: isSelected,
        onSelected: (_) => controller.filterByType(type),
        selectedColor: AppThemeSystem.primaryColor.withOpacity(0.2),
        checkmarkColor: AppThemeSystem.primaryColor,
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, transaction) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.horizontalPadding,
        vertical: context.elementSpacing * 0.25,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: context.borderRadius(BorderRadiusType.medium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(context.elementSpacing * 0.5),
          decoration: BoxDecoration(
            color: transaction.isCredit
                ? AppThemeSystem.successColor.withOpacity(0.1)
                : AppThemeSystem.errorColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            transaction.typeIcon,
            style: TextStyle(
                fontSize: context.deviceType == DeviceType.mobile ? 20 : 24),
          ),
        ),
        title: Text(
          transaction.typeLabel,
          style: context.body1.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(transaction.description, style: context.body2),
            SizedBox(height: context.elementSpacing * 0.25),
            Text(
              transaction.formattedDate,
              style: context.caption,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              transaction.formattedAmount,
              style: context.body1.copyWith(
                fontWeight: FontWeight.bold,
                color: transaction.isCredit
                    ? AppThemeSystem.successColor
                    : AppThemeSystem.errorColor,
              ),
            ),
            SizedBox(height: context.elementSpacing * 0.25),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.elementSpacing * 0.5,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor(transaction.status).withOpacity(0.1),
                borderRadius: context.borderRadius(BorderRadiusType.small),
              ),
              child: Text(
                transaction.statusLabel,
                style: context.caption.copyWith(
                  color: _getStatusColor(transaction.status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppThemeSystem.successColor;
      case 'pending':
        return AppThemeSystem.warningColor;
      case 'processing':
        return AppThemeSystem.infoColor;
      case 'failed':
      case 'cancelled':
        return AppThemeSystem.errorColor;
      default:
        return AppThemeSystem.grey500;
    }
  }
}
