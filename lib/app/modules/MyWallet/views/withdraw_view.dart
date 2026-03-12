import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/my_wallet_controller.dart';
import '../../../widgets/app_theme_system.dart';

class WithdrawView extends StatefulWidget {
  const WithdrawView({super.key});

  @override
  State<WithdrawView> createState() => _WithdrawViewState();
}

class _WithdrawViewState extends State<WithdrawView> {
  final controller = Get.find<MyWalletController>();
  late final TextEditingController amountController;
  late final TextEditingController phoneController;
  final selectedProvider = 'mtn_momo'.obs;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
    phoneController = TextEditingController();
    // Ensure pending withdrawals are visible immediately on this screen.
    controller.loadWithdrawals(status: 'pending');
  }

  @override
  void dispose() {
    amountController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Retrait', style: context.h5),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Balance Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.sectionSpacing),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppThemeSystem.warningColor, Color(0xFFFB8C00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: context.borderRadius(BorderRadiusType.large),
                boxShadow: [
                  BoxShadow(
                    color: AppThemeSystem.warningColor.withOpacity(0.3),
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
                        style: context.h3.copyWith(
                          color: AppThemeSystem.whiteColor,
                        ),
                      )),
                  SizedBox(height: context.elementSpacing * 0.5),
                  Obx(() {
                    final methods = controller.withdrawalMethods.value;
                    if (methods != null) {
                      return Text(
                        'Minimum: ${methods.minimumAmount.toStringAsFixed(0)} FCFA',
                        style: context.caption.copyWith(
                          color: AppThemeSystem.whiteColor.withOpacity(0.8),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),

            SizedBox(height: context.sectionSpacing),

            // Payment Provider Selection
            Text('Choisissez votre opérateur', style: context.h6),
            SizedBox(height: context.elementSpacing),

            Obx(() => Row(
                  children: [
                    Expanded(
                      child: _buildProviderCard(
                        context,
                        provider: 'mtn_momo',
                        label: 'MTN MoMo',
                        color: const Color(0xFFFFD700),
                        isSelected: selectedProvider.value == 'mtn_momo',
                        onTap: () => selectedProvider.value = 'mtn_momo',
                      ),
                    ),
                    SizedBox(width: context.elementSpacing),
                    Expanded(
                      child: _buildProviderCard(
                        context,
                        provider: 'orange_money',
                        label: 'Orange Money',
                        color: const Color(0xFFFF6F00),
                        isSelected: selectedProvider.value == 'orange_money',
                        onTap: () => selectedProvider.value = 'orange_money',
                      ),
                    ),
                  ],
                )),

            SizedBox(height: context.sectionSpacing),

            // Amount Input
            Text('Montant à retirer', style: context.h6),
            SizedBox(height: context.elementSpacing),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: context.body1,
              decoration: InputDecoration(
                hintText: 'Entrez le montant',
                suffixText: 'FCFA',
                prefixIcon: const Icon(Icons.money_off),
              ),
            ),

            SizedBox(height: context.elementSpacing),

            // Quick Amount Buttons
            Obx(() {
              final balance = controller.balance;
              final suggestions = <int>[];

              if (balance >= 1000) suggestions.add(1000);
              if (balance >= 2000) suggestions.add(2000);
              if (balance >= 5000) suggestions.add(5000);
              if (balance >= 10000) suggestions.add(10000);
              if (balance >= 20000) suggestions.add(20000);

              if (suggestions.isEmpty) {
                return const SizedBox.shrink();
              }

              return Wrap(
                spacing: context.elementSpacing * 0.5,
                runSpacing: context.elementSpacing * 0.5,
                children: suggestions.map((amount) {
                  return InkWell(
                    onTap: () => setState(() {
                      amountController.text = amount.toString();
                    }),
                    borderRadius:
                        context.borderRadius(BorderRadiusType.circular),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.horizontalPadding,
                        vertical: context.elementSpacing * 0.5,
                      ),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius:
                            context.borderRadius(BorderRadiusType.circular),
                        border: Border.all(color: context.borderColor),
                      ),
                      child:
                          Text('${amount.toString()} F', style: context.body2),
                    ),
                  );
                }).toList(),
              );
            }),

            SizedBox(height: context.sectionSpacing),

            // Phone Number Input
            Text('Numéro de réception', style: context.h6),
            SizedBox(height: context.elementSpacing),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: context.body1,
              decoration: InputDecoration(
                hintText: 'Ex: 699999999',
                prefixText: '+237 ',
                prefixIcon: const Icon(Icons.phone),
              ),
            ),

            SizedBox(height: context.sectionSpacing),

            // Warning Card
            Container(
              padding: EdgeInsets.all(context.horizontalPadding),
              decoration: BoxDecoration(
                color: AppThemeSystem.warningColor.withOpacity(0.1),
                borderRadius: context.borderRadius(BorderRadiusType.medium),
                border: Border.all(
                    color: AppThemeSystem.warningColor.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber,
                      color: AppThemeSystem.warningColor),
                  SizedBox(width: context.elementSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Important',
                          style: context.body1.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppThemeSystem.warningColor,
                          ),
                        ),
                        SizedBox(height: context.elementSpacing * 0.5),
                        Text(
                          '• Traitement: jusqu\'à 48 heures',
                          style: context.body2.copyWith(
                            color: AppThemeSystem.warningColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: context.sectionSpacing),

            // Submit Button
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: context.buttonHeight,
                  child: ElevatedButton(
                    onPressed: controller.isProcessingPayment.value
                        ? null
                        : () => _handleWithdrawal(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeSystem.warningColor,
                    ),
                    child: controller.isProcessingPayment.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text('Demander le retrait',
                            style: context.button.copyWith(
                                color: AppThemeSystem.whiteColor)),
                  ),
                )),

            SizedBox(height: context.sectionSpacing),

            // Pending Withdrawals
            Obx(() {
              // Ne charger qu'une seule fois, pas à chaque rebuild !
              if (controller.withdrawals.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: context.borderColor),
                  SizedBox(height: context.elementSpacing),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Retraits en attente', style: context.h6),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: () => controller.loadWithdrawals(status: 'pending'),
                        tooltip: 'Rafraîchir',
                      ),
                    ],
                  ),
                  SizedBox(height: context.elementSpacing),
                  ...controller.withdrawals.map((withdrawal) {
                    return Container(
                      margin: EdgeInsets.only(
                          bottom: context.elementSpacing * 0.5),
                      padding: EdgeInsets.all(context.horizontalPadding),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius:
                            context.borderRadius(BorderRadiusType.medium),
                        border: Border.all(
                            color:
                                AppThemeSystem.warningColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                withdrawal.formattedAmount,
                                style: context.h5,
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.elementSpacing,
                                  vertical: context.elementSpacing * 0.25,
                                ),
                                decoration: BoxDecoration(
                                  color: AppThemeSystem.warningColor
                                      .withOpacity(0.1),
                                  borderRadius: context
                                      .borderRadius(BorderRadiusType.medium),
                                ),
                                child: Text(
                                  withdrawal.statusLabel,
                                  style: context.caption.copyWith(
                                    color: AppThemeSystem.warningColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.elementSpacing * 0.5),
                          Text(
                            '${withdrawal.providerIcon} ${withdrawal.providerName}',
                            style: context.body2
                                .copyWith(color: context.secondaryTextColor),
                          ),
                          Text(
                            withdrawal.phoneNumber,
                            style: context.body2
                                .copyWith(color: context.secondaryTextColor),
                          ),
                          Text(
                            withdrawal.formattedDate,
                            style: context.caption,
                          ),
                          if (withdrawal.isPending) ...[
                            SizedBox(height: context.elementSpacing),
                            TextButton.icon(
                              onPressed: () => _confirmCancel(withdrawal.id),
                              icon: const Icon(Icons.cancel, size: 18),
                              label: Text('Annuler', style: context.button),
                              style: TextButton.styleFrom(
                                foregroundColor: AppThemeSystem.errorColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(
    BuildContext context, {
    required String provider,
    required String label,
    required Color color,
    required bool isSelected,
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
          border: Border.all(
            color: isSelected ? color : context.borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: context.body2.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : context.primaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              SizedBox(height: context.elementSpacing * 0.25),
              Icon(Icons.check_circle, color: color, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleWithdrawal(BuildContext context) async {
    if (amountController.text.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez entrer un montant',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final amount = double.tryParse(amountController.text);
    if (amount == null || amount < 50) {
      Get.snackbar(
        'Erreur',
        'Le montant minimum est de 50 FCFA',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!controller.hasEnoughBalance(amount)) {
      Get.snackbar(
        'Erreur',
        'Solde insuffisant',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (phoneController.text.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez entrer le numéro de réception',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final phoneNumber = '+237${phoneController.text}';

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Confirmer le retrait', style: context.h6),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Montant: ${amount.toStringAsFixed(0)} FCFA',
                style: context.body1),
            Text(
                'Opérateur: ${selectedProvider.value == 'mtn_momo' ? 'MTN MoMo' : 'Orange Money'}',
                style: context.body1),
            Text('Numéro: $phoneNumber', style: context.body1),
            SizedBox(height: context.elementSpacing),
            Text(
              'Le traitement peut prendre jusqu\'à 48 heures.',
              style: context.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Annuler', style: context.button),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: Text('Confirmer', style: context.button),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await controller.requestWithdrawal(
      amount: amount,
      phoneNumber: phoneNumber,
      provider: selectedProvider.value,
    );
  }

  void _confirmCancel(int withdrawalId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Annuler le retrait'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler cette demande de retrait ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.cancelWithdrawal(withdrawalId);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeSystem.errorColor),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }
}
