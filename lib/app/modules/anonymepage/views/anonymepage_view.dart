import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:weylo/app/widgets/animated_border_card.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

import '../controllers/anonymepage_controller.dart';

class AnonymepageView extends GetView<AnonymepageController> {
  const AnonymepageView({super.key});

  @override
  Widget build(BuildContext context) {
    final myLink = 'weylo.app/u/johndoe123'; // Mon lien personnel

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: context.elementSpacing),

          // My Anonymous Link Card with Animated Border
          AnimatedBorderCard(
            borderRadius: 20,
            borderWidth: 3,
            borderColor: AppThemeSystem.primaryColor,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppThemeSystem.darkCardColor
                : Colors.white,
            padding: EdgeInsets.all(context.elementSpacing * 1.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppThemeSystem.primaryColor.withValues(alpha: 0.2),
                            AppThemeSystem.secondaryColor.withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.link_rounded,
                        color: AppThemeSystem.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mon lien anonyme',
                            style: context.textStyle(FontSizeType.h4).copyWith(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : AppThemeSystem.blackColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Partagez pour recevoir des messages',
                            style: context.textStyle(FontSizeType.caption).copyWith(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppThemeSystem.grey400
                                  : AppThemeSystem.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.elementSpacing * 1.2),

                // Link display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppThemeSystem.grey800.withValues(alpha: 0.4)
                        : AppThemeSystem.grey100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppThemeSystem.grey700
                          : AppThemeSystem.grey300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          myLink,
                          style: context.textStyle(FontSizeType.body2).copyWith(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : AppThemeSystem.blackColor,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          Get.snackbar(
                            'Copié !',
                            'Lien copié dans le presse-papiers',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppThemeSystem.successColor,
                            colorText: Colors.white,
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppThemeSystem.primaryColor.withValues(alpha: 0.15),
                                AppThemeSystem.secondaryColor.withValues(alpha: 0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.copy_rounded,
                            color: AppThemeSystem.primaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: context.elementSpacing * 1.2),

                // Share button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppThemeSystem.primaryColor,
                          AppThemeSystem.secondaryColor,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppThemeSystem.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await SharePlus.instance.share(
                          ShareParams(
                            text: 'Hey! Envoie-moi un message anonyme sur Weylo: $myLink',
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.share_rounded,
                        size: 22,
                      ),
                      label: Text(
                        'Partager mon lien',
                        style: context.textStyle(FontSizeType.button).copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: context.sectionSpacing),

          // Messages received header
          Row(
            children: [
              Icon(
                Icons.mail_rounded,
                color: AppThemeSystem.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Messages reçus',
                style: context.textStyle(FontSizeType.h3).copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppThemeSystem.blackColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppThemeSystem.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '12 nouveaux',
                  style: context.textStyle(FontSizeType.caption).copyWith(
                    color: AppThemeSystem.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: context.elementSpacing),

          // Anonymous messages received
          ...List.generate(
            8,
            (index) => _buildAnonymousMessageCard(context, index),
          ),
        ],
      ),
    );
  }

  Widget _buildAnonymousMessageCard(BuildContext context, int index) {
    final isNew = index < 3; // First 3 messages are new

    return Container(
      margin: EdgeInsets.only(bottom: context.elementSpacing),
      padding: EdgeInsets.all(context.elementSpacing),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppThemeSystem.darkCardColor
            : Colors.white,
        borderRadius: context.borderRadius(BorderRadiusType.medium),
        border: isNew
            ? Border.all(
                color: AppThemeSystem.tertiaryColor.withOpacity(0.3),
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppThemeSystem.tertiaryColor.withOpacity(0.2),
                      AppThemeSystem.secondaryColor.withOpacity(0.2),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mail_outline_rounded,
                  color: AppThemeSystem.tertiaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Message anonyme',
                          style: context.textStyle(FontSizeType.body1).copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : AppThemeSystem.blackColor,
                          ),
                        ),
                        if (isNew) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppThemeSystem.primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'NOUVEAU',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Il y a ${index + 1}h',
                      style: context.textStyle(FontSizeType.caption).copyWith(
                        color: AppThemeSystem.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: Icon(
                  Icons.more_vert,
                  color: AppThemeSystem.grey600,
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20),
                        SizedBox(width: 8),
                        Text('Supprimer'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.report_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Signaler'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: context.elementSpacing),

          // Message content
          Container(
            padding: EdgeInsets.all(context.elementSpacing),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppThemeSystem.darkBackgroundColor
                  : AppThemeSystem.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              index == 0
                  ? 'Salut ! J\'adore ton profil, continue comme ça ! 💜'
                  : index == 1
                      ? 'Tu es une source d\'inspiration pour moi. Merci pour tout ! ✨'
                      : index == 2
                          ? 'J\'aimerais mieux te connaître, tu as l\'air génial ! 😊'
                          : 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt.',
              style: context.textStyle(FontSizeType.body2).copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppThemeSystem.blackColor,
                height: 1.5,
              ),
            ),
          ),

          SizedBox(height: context.elementSpacing),

          // Reply button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Get.snackbar(
                  'Répondre',
                  'Fonctionnalité de réponse à venir',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              icon: const Icon(Icons.reply_rounded, size: 20),
              label: Text(
                'Répondre anonymement',
                style: context.textStyle(FontSizeType.button).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppThemeSystem.primaryColor,
                side: BorderSide(
                  color: AppThemeSystem.primaryColor,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
