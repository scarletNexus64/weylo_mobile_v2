import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import 'package:get/get.dart';

class LinkableTextMessage extends StatefulWidget {
  final String text;
  final bool isSentByMe;
  final bool isDark;

  const LinkableTextMessage({
    super.key,
    required this.text,
    required this.isSentByMe,
    required this.isDark,
  });

  @override
  State<LinkableTextMessage> createState() => _LinkableTextMessageState();
}

class _LinkableTextMessageState extends State<LinkableTextMessage> {

  /// Extraire le premier lien du texte
  String? _extractFirstUrl(String text) {
    final urlRegExp = RegExp(
      r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
      caseSensitive: false,
    );

    final match = urlRegExp.firstMatch(text);
    return match?.group(0);
  }

  /// Afficher le dialog de redirection
  void _showRedirectDialog(String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: widget.isDark
              ? AppThemeSystem.darkCardColor
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppThemeSystem.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.open_in_new_rounded,
                    size: 32,
                    color: AppThemeSystem.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Redirection externe',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark ? Colors.white : AppThemeSystem.blackColor,
                  ),
                ),
                const SizedBox(height: 8),

                // Message
                Text(
                  'Vous allez être redirigé vers un site externe',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                  ),
                ),
                const SizedBox(height: 12),

                // URL
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? AppThemeSystem.grey800.withValues(alpha: 0.5)
                        : AppThemeSystem.grey100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    url,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppThemeSystem.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Loader
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppThemeSystem.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Attendre 1.5 secondes puis ouvrir le lien
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context).pop(); // Fermer le dialog
      _launchUrl(url);
    });
  }

  /// Ouvrir un lien
  Future<void> _launchUrl(String url) async {
    try {
      print('🔗 [LinkableText] Tentative d\'ouverture du lien: $url');

      final uri = Uri.parse(url);

      // Tenter d'ouvrir le lien
      final canLaunch = await canLaunchUrl(uri);
      print('🔗 [LinkableText] canLaunchUrl: $canLaunch');

      if (canLaunch) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('🔗 [LinkableText] launchUrl result: $launched');
      } else {
        print('❌ [LinkableText] Impossible d\'ouvrir le lien: $url');
        Get.snackbar(
          'Erreur',
          'Impossible d\'ouvrir ce lien',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppThemeSystem.errorColor,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('❌ [LinkableText] Erreur lors de l\'ouverture du lien: $e');
      Get.snackbar(
        'Erreur',
        'Une erreur s\'est produite lors de l\'ouverture du lien',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.errorColor,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstUrl = _extractFirstUrl(widget.text);
    final hasUrl = firstUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Texte avec liens cliquables
        Linkify(
          onOpen: (link) => _showRedirectDialog(link.url),
          text: widget.text,
          style: TextStyle(
            fontSize: 15,
            color: widget.isSentByMe
                ? Colors.white
                : (widget.isDark ? Colors.white : AppThemeSystem.blackColor),
          ),
          linkStyle: TextStyle(
            fontSize: 15,
            color: widget.isSentByMe
                ? Colors.white
                : AppThemeSystem.primaryColor,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w600,
          ),
        ),

        // Preview du lien si présent
        if (hasUrl) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showRedirectDialog(firstUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AnyLinkPreview(
                link: firstUrl,
                displayDirection: UIDirection.uiDirectionVertical,
                backgroundColor: widget.isSentByMe
                    ? Colors.white.withValues(alpha: 0.15)
                    : (widget.isDark
                        ? AppThemeSystem.grey800.withValues(alpha: 0.6)
                        : AppThemeSystem.grey200),
                bodyStyle: TextStyle(
                  color: widget.isSentByMe
                      ? Colors.white.withValues(alpha: 0.9)
                      : (widget.isDark ? Colors.white70 : AppThemeSystem.grey800),
                  fontSize: 12,
                ),
                titleStyle: TextStyle(
                  color: widget.isSentByMe
                      ? Colors.white
                      : (widget.isDark ? Colors.white : AppThemeSystem.blackColor),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                errorWidget: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.isSentByMe
                        ? Colors.white.withValues(alpha: 0.15)
                        : (widget.isDark
                            ? AppThemeSystem.grey800.withValues(alpha: 0.6)
                            : AppThemeSystem.grey200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.link,
                        size: 16,
                        color: widget.isSentByMe
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppThemeSystem.grey600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          firstUrl,
                          style: TextStyle(
                            color: widget.isSentByMe
                                ? Colors.white.withValues(alpha: 0.8)
                                : AppThemeSystem.grey700,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                cache: const Duration(hours: 1),
                borderRadius: 8,
                removeElevation: true,
                boxShadow: const [],
                bodyMaxLines: 2,
                bodyTextOverflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
