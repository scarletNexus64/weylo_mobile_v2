import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:weylo/app/data/models/legal_page_model.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

class LegalPageDetailView extends StatelessWidget {
  final LegalPageModel page;

  const LegalPageDetailView({
    super.key,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppThemeSystem.darkBackgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          page.title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metadata
            if (page.updatedAt != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppThemeSystem.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.update,
                      size: 14,
                      color: AppThemeSystem.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Dernière mise à jour: ${page.updatedAt}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppThemeSystem.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // HTML Content
            Html(
              data: page.content ?? '<p>Contenu non disponible</p>',
              style: {
                'body': Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontSize: FontSize(15),
                  lineHeight: const LineHeight(1.6),
                  color: isDark ? Colors.white : Colors.black87,
                ),
                'h1': Style(
                  fontSize: FontSize(24),
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(top: 16, bottom: 12),
                  color: isDark ? Colors.white : Colors.black,
                ),
                'h2': Style(
                  fontSize: FontSize(20),
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(top: 16, bottom: 10),
                  color: isDark ? Colors.white : Colors.black,
                ),
                'h3': Style(
                  fontSize: FontSize(18),
                  fontWeight: FontWeight.w600,
                  margin: Margins.only(top: 14, bottom: 8),
                  color: isDark ? Colors.white : Colors.black,
                ),
                'p': Style(
                  margin: Margins.only(bottom: 12),
                  color: isDark ? AppThemeSystem.grey300 : AppThemeSystem.grey700,
                ),
                'a': Style(
                  color: AppThemeSystem.primaryColor,
                  textDecoration: TextDecoration.underline,
                ),
                'ul': Style(
                  margin: Margins.only(bottom: 12, left: 8),
                ),
                'ol': Style(
                  margin: Margins.only(bottom: 12, left: 8),
                ),
                'li': Style(
                  margin: Margins.only(bottom: 6),
                  color: isDark ? AppThemeSystem.grey300 : AppThemeSystem.grey700,
                ),
                'strong': Style(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
                'em': Style(
                  fontStyle: FontStyle.italic,
                ),
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
