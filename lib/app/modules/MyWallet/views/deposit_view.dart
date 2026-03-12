import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/my_wallet_controller.dart';
import '../../../widgets/app_theme_system.dart';
import '../../../data/services/wallet_service.dart';

class DepositView extends StatefulWidget {
  const DepositView({super.key});

  @override
  State<DepositView> createState() => _DepositViewState();
}

class _DepositViewState extends State<DepositView> {
  final controller = Get.find<MyWalletController>();
  final walletService = WalletService();
  late final TextEditingController amountController;
  late final TextEditingController phoneController;
  final selectedProvider = 'orange'.obs;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
    phoneController = TextEditingController();
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
        title: Text('Dépôt FreeMoPay', style: context.h5),
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
                  colors: [AppThemeSystem.successColor, Color(0xFF66BB6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: context.borderRadius(BorderRadiusType.large),
                boxShadow: [
                  BoxShadow(
                    color: AppThemeSystem.successColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Solde actuel',
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
                        provider: 'orange',
                        label: 'Orange Money',
                        color: const Color(0xFFFF6F00),
                        isSelected: selectedProvider.value == 'orange',
                        onTap: () => selectedProvider.value = 'orange',
                      ),
                    ),
                    SizedBox(width: context.elementSpacing),
                    Expanded(
                      child: _buildProviderCard(
                        context,
                        provider: 'mtn',
                        label: 'MTN MoMo',
                        color: const Color(0xFFFFD700),
                        isSelected: selectedProvider.value == 'mtn',
                        onTap: () => selectedProvider.value = 'mtn',
                      ),
                    ),
                  ],
                )),

            SizedBox(height: context.sectionSpacing),

            // Amount Input
            Text('Montant à déposer', style: context.h6),
            SizedBox(height: context.elementSpacing),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: context.body1,
              decoration: InputDecoration(
                hintText: 'Entrez le montant',
                suffixText: 'FCFA',
                prefixIcon: const Icon(Icons.attach_money),
              ),
            ),

            SizedBox(height: context.elementSpacing),

            // Phone Number Input
            Text('Numéro de téléphone', style: context.h6),
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

            // Submit Button
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: context.buttonHeight,
                  child: ElevatedButton(
                    onPressed: controller.isProcessingPayment.value
                        ? null
                        : () => _handleDeposit(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeSystem.successColor,
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
                        : Text('Initier le dépôt',
                            style: context.button.copyWith(
                                color: AppThemeSystem.whiteColor)),
                  ),
                )),

            SizedBox(height: context.elementSpacing),

            // Minimum Amount Notice
            Center(
              child: Text(
                'Montant minimum: 100 FCFA',
                style: context.caption,
              ),
            ),
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

  Future<void> _handleDeposit(BuildContext context) async {
    // Validation
    if (amountController.text.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez entrer un montant',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final amount = double.tryParse(amountController.text);
    if (amount == null || amount < 100) {
      Get.snackbar(
        'Erreur',
        'Le montant minimum est de 100 FCFA',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (phoneController.text.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez entrer votre numéro de téléphone',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final phoneNumber = '+237${phoneController.text}';

    // Initier le dépôt
    final result = await controller.initiateDeposit(
      amount: amount,
      phoneNumber: phoneNumber,
    );

    if (result['success'] == true) {
      // Afficher le dialogue d'information
      Get.dialog(
        AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: AppThemeSystem.infoColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Paiement initié', style: context.h6),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Un code USSD a été envoyé sur votre téléphone.',
                style: context.body1,
              ),
              SizedBox(height: context.elementSpacing),
              Container(
                padding: EdgeInsets.all(context.horizontalPadding),
                decoration: BoxDecoration(
                  color: AppThemeSystem.infoColor.withValues(alpha: 0.1),
                  borderRadius: context.borderRadius(BorderRadiusType.medium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions :',
                      style: context.body2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppThemeSystem.infoColor,
                      ),
                    ),
                    SizedBox(height: context.elementSpacing * 0.5),
                    Text(
                      '1. Composez le code USSD reçu\n'
                      '2. Entrez votre code PIN\n'
                      '3. Confirmez le paiement de ${amount.toStringAsFixed(0)} FCFA\n\n'
                      'Votre solde sera automatiquement crédité après validation.',
                      style: context.body2.copyWith(
                        color: AppThemeSystem.infoColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Get.back(); // Fermer le dialogue
                Get.back(); // Retourner à la page wallet
              },
              child: Text('Compris', style: context.button),
            ),
          ],
        ),
        barrierDismissible: true,
      );

      // Effacer les champs
      amountController.clear();
      phoneController.clear();
    }
  }
}
