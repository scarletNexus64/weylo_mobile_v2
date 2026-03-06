import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Système de theming automatique et responsive pour Ngoma
/// Gère automatiquement les thèmes sombre/clair et toutes les tailles d'écran
class AppThemeSystem {
  // ================================
  // COULEURS DU DESIGN SYSTEM
  // ================================

  // 🎨 Palette inspirée du logo Weylo (dégradé rose/orange)
  static const Color primaryColor = Color(0xFFf35453); // Rouge cerise vif
  static const Color secondaryColor = Color(0xFFeb316f); // Orange tangerine
  static const Color tertiaryColor = Color(0xFF972bde); // Magenta profond
  static const Color accentColor = Color(0xFFFFB703); // Jaune doré
  static const Color neutralColor = Color(0xFF1D1D2C); // Noir bleuté

  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF000000);
  static const Color backgroundColor = Color(0xFFF6F6F6);
  static const Color darkBackgroundColor = Color(0xFF0D1117);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color darkCardColor = Color(0xFF151B23);

  // Couleurs grises
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Couleurs sémantiques
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color infoColor = Color(0xFF2196F3);

  // ================================
  // BREAKPOINTS RESPONSIVE
  // ================================

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double largeTabletBreakpoint = 1024;
  static const double iPadPro13Breakpoint = 1366; // iPad Pro 13" width
  static const double desktopBreakpoint = 1200;

  /// Détermine le type d'appareil basé sur la largeur d'écran
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    if (width < largeTabletBreakpoint) return DeviceType.largeTablet;
    if (width < iPadPro13Breakpoint) return DeviceType.iPadPro13;
    return DeviceType.desktop;
  }

  /// Vérifie si l'appareil est en mode portrait
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Vérifie si l'appareil est une tablette ou plus grand
  static bool isTabletOrLarger(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  // ================================
  // SYSTÈME DE TYPOGRAPHIE RESPONSIVE
  // ================================

  /// Tailles de police responsives basées sur le type d'appareil
  static double getFontSize(BuildContext context, FontSizeType type) {
    final deviceType = getDeviceType(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Facteur de scaling adaptatif basé sur le type d'appareil
    double scaleFactor;
    if (deviceType == DeviceType.iPadPro13) {
      // Pour iPad Pro 13", on utilise un facteur plus généreux
      final heightFactor = (screenHeight / 1024).clamp(1.1, 1.4);
      final widthFactor = (screenWidth / 1366).clamp(1.1, 1.3);
      scaleFactor = (heightFactor + widthFactor) / 2;
    } else if (deviceType == DeviceType.largeTablet) {
      final heightFactor = (screenHeight / 1024).clamp(1.0, 1.3);
      final widthFactor = (screenWidth / 1024).clamp(1.0, 1.2);
      scaleFactor = (heightFactor + widthFactor) / 2;
    } else if (deviceType == DeviceType.tablet) {
      scaleFactor = (screenHeight / 800).clamp(0.95, 1.25);
    } else {
      scaleFactor = (screenHeight / 800).clamp(0.8, 1.2);
    }

    switch (type) {
      case FontSizeType.h1:
        switch (deviceType) {
          case DeviceType.mobile:
            return (32 * scaleFactor);
          case DeviceType.tablet:
            return (36 * scaleFactor);
          case DeviceType.largeTablet:
            return (42 * scaleFactor);
          case DeviceType.iPadPro13:
            return (48 * scaleFactor); // Plus grand pour iPad Pro 13"
          case DeviceType.desktop:
            return (40 * scaleFactor);
        }
      case FontSizeType.h2:
        switch (deviceType) {
          case DeviceType.mobile:
            return (28 * scaleFactor);
          case DeviceType.tablet:
            return (32 * scaleFactor);
          case DeviceType.largeTablet:
            return (36 * scaleFactor);
          case DeviceType.iPadPro13:
            return (40 * scaleFactor);
          case DeviceType.desktop:
            return (36 * scaleFactor);
        }
      case FontSizeType.h3:
        switch (deviceType) {
          case DeviceType.mobile:
            return (24 * scaleFactor);
          case DeviceType.tablet:
            return (28 * scaleFactor);
          case DeviceType.largeTablet:
            return (32 * scaleFactor);
          case DeviceType.iPadPro13:
            return (36 * scaleFactor);
          case DeviceType.desktop:
            return (32 * scaleFactor);
        }
      case FontSizeType.h4:
        switch (deviceType) {
          case DeviceType.mobile:
            return (20 * scaleFactor);
          case DeviceType.tablet:
            return (24 * scaleFactor);
          case DeviceType.largeTablet:
            return (28 * scaleFactor);
          case DeviceType.iPadPro13:
            return (32 * scaleFactor);
          case DeviceType.desktop:
            return (28 * scaleFactor);
        }
      case FontSizeType.h5:
        switch (deviceType) {
          case DeviceType.mobile:
            return (18 * scaleFactor);
          case DeviceType.tablet:
            return (20 * scaleFactor);
          case DeviceType.largeTablet:
            return (24 * scaleFactor);
          case DeviceType.iPadPro13:
            return (28 * scaleFactor);
          case DeviceType.desktop:
            return (24 * scaleFactor);
        }
      case FontSizeType.h6:
        switch (deviceType) {
          case DeviceType.mobile:
            return (16 * scaleFactor);
          case DeviceType.tablet:
            return (18 * scaleFactor);
          case DeviceType.largeTablet:
            return (20 * scaleFactor);
          case DeviceType.iPadPro13:
            return (24 * scaleFactor);
          case DeviceType.desktop:
            return (20 * scaleFactor);
        }
      case FontSizeType.subtitle1:
        switch (deviceType) {
          case DeviceType.mobile:
            return (16 * scaleFactor);
          case DeviceType.tablet:
            return (18 * scaleFactor);
          case DeviceType.largeTablet:
            return (20 * scaleFactor);
          case DeviceType.iPadPro13:
            return (22 * scaleFactor);
          case DeviceType.desktop:
            return (20 * scaleFactor);
        }
      case FontSizeType.subtitle2:
        switch (deviceType) {
          case DeviceType.mobile:
            return (14 * scaleFactor);
          case DeviceType.tablet:
            return (16 * scaleFactor);
          case DeviceType.largeTablet:
            return (18 * scaleFactor);
          case DeviceType.iPadPro13:
            return (20 * scaleFactor);
          case DeviceType.desktop:
            return (18 * scaleFactor);
        }
      case FontSizeType.body1:
        switch (deviceType) {
          case DeviceType.mobile:
            return (16 * scaleFactor);
          case DeviceType.tablet:
            return (17 * scaleFactor);
          case DeviceType.largeTablet:
            return (18 * scaleFactor);
          case DeviceType.iPadPro13:
            return (20 * scaleFactor);
          case DeviceType.desktop:
            return (18 * scaleFactor);
        }
      case FontSizeType.body2:
        switch (deviceType) {
          case DeviceType.mobile:
            return (14 * scaleFactor);
          case DeviceType.tablet:
            return (15 * scaleFactor);
          case DeviceType.largeTablet:
            return (16 * scaleFactor);
          case DeviceType.iPadPro13:
            return (18 * scaleFactor);
          case DeviceType.desktop:
            return (16 * scaleFactor);
        }
      case FontSizeType.caption:
        switch (deviceType) {
          case DeviceType.mobile:
            return (12 * scaleFactor);
          case DeviceType.tablet:
            return (13 * scaleFactor);
          case DeviceType.largeTablet:
            return (14 * scaleFactor);
          case DeviceType.iPadPro13:
            return (16 * scaleFactor);
          case DeviceType.desktop:
            return (14 * scaleFactor);
        }
      case FontSizeType.overline:
        switch (deviceType) {
          case DeviceType.mobile:
            return (10 * scaleFactor);
          case DeviceType.tablet:
            return (11 * scaleFactor);
          case DeviceType.largeTablet:
            return (12 * scaleFactor);
          case DeviceType.iPadPro13:
            return (14 * scaleFactor);
          case DeviceType.desktop:
            return (12 * scaleFactor);
        }
      case FontSizeType.button:
        switch (deviceType) {
          case DeviceType.mobile:
            return (14 * scaleFactor);
          case DeviceType.tablet:
            return (15 * scaleFactor);
          case DeviceType.largeTablet:
            return (16 * scaleFactor);
          case DeviceType.iPadPro13:
            return (18 * scaleFactor);
          case DeviceType.desktop:
            return (16 * scaleFactor);
        }
    }
  }

  // ================================
  // STYLES DE TEXTE AUTOMATIQUES
  // ================================

  /// Génère un TextStyle basé sur le thème actuel et le type de device
  static TextStyle getTextStyle(
    BuildContext context,
    FontSizeType type, {
    FontWeight? fontWeight,
    Color? color,
    double? height,
    bool useGoogleFont = false,
    String fontFamily = 'SF-Pro',
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fontSize = getFontSize(context, type);

    // Couleur automatique basée sur le thème
    Color textColor = color ?? (isDark ? whiteColor : blackColor);

    if (useGoogleFont) {
      return GoogleFonts.getFont(
        fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: textColor,
        height: height,
      );
    } else {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: textColor,
        height: height,
        fontFamily: fontFamily,
      );
    }
  }

  // ================================
  // ESPACEMENTS RESPONSIFS
  // ================================

  /// Espacement horizontal responsive
  static double getHorizontalPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    final screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor;

    if (deviceType == DeviceType.iPadPro13) {
      scaleFactor = (screenWidth / 1366).clamp(
        1.1,
        1.4,
      ); // Facteur plus généreux pour iPad Pro 13"
    } else if (deviceType == DeviceType.largeTablet) {
      scaleFactor = (screenWidth / 1024).clamp(1.0, 1.25);
    } else if (deviceType == DeviceType.tablet) {
      scaleFactor = (screenWidth / 768).clamp(0.95, 1.2);
    } else {
      scaleFactor = (screenWidth / 375).clamp(0.9, 1.3);
    }

    switch (deviceType) {
      case DeviceType.mobile:
        return (16 * scaleFactor);
      case DeviceType.tablet:
        return (24 * scaleFactor);
      case DeviceType.largeTablet:
        return (32 * scaleFactor);
      case DeviceType.iPadPro13:
        return (40 * scaleFactor);
      case DeviceType.desktop:
        return (32 * scaleFactor);
    }
  }

  /// Espacement vertical responsive
  static double getVerticalPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    final screenHeight = MediaQuery.of(context).size.height;
    double scaleFactor;

    if (deviceType == DeviceType.iPadPro13) {
      scaleFactor = (screenHeight / 1024).clamp(1.1, 1.4);
    } else if (deviceType == DeviceType.largeTablet) {
      scaleFactor = (screenHeight / 1024).clamp(1.0, 1.25);
    } else if (deviceType == DeviceType.tablet) {
      scaleFactor = (screenHeight / 800).clamp(0.95, 1.2);
    } else {
      scaleFactor = (screenHeight / 800).clamp(0.8, 1.2);
    }

    switch (deviceType) {
      case DeviceType.mobile:
        return (16 * scaleFactor);
      case DeviceType.tablet:
        return (20 * scaleFactor);
      case DeviceType.largeTablet:
        return (24 * scaleFactor);
      case DeviceType.iPadPro13:
        return (28 * scaleFactor);
      case DeviceType.desktop:
        return (24 * scaleFactor);
    }
  }

  /// Espacement entre sections
  static double getSectionSpacing(BuildContext context) {
    final deviceType = getDeviceType(context);
    final screenHeight = MediaQuery.of(context).size.height;
    double scaleFactor;

    if (deviceType == DeviceType.iPadPro13) {
      scaleFactor = (screenHeight / 1024).clamp(1.1, 1.4);
    } else if (deviceType == DeviceType.largeTablet) {
      scaleFactor = (screenHeight / 1024).clamp(1.0, 1.25);
    } else if (deviceType == DeviceType.tablet) {
      scaleFactor = (screenHeight / 800).clamp(0.95, 1.2);
    } else {
      scaleFactor = (screenHeight / 800).clamp(0.8, 1.2);
    }

    switch (deviceType) {
      case DeviceType.mobile:
        return (24 * scaleFactor);
      case DeviceType.tablet:
        return (32 * scaleFactor);
      case DeviceType.largeTablet:
        return (40 * scaleFactor);
      case DeviceType.iPadPro13:
        return (48 * scaleFactor);
      case DeviceType.desktop:
        return (40 * scaleFactor);
    }
  }

  /// Espacement entre éléments
  static double getElementSpacing(BuildContext context) {
    final deviceType = getDeviceType(context);
    final screenHeight = MediaQuery.of(context).size.height;
    double scaleFactor;

    if (deviceType == DeviceType.iPadPro13) {
      scaleFactor = (screenHeight / 1024).clamp(1.1, 1.4);
    } else if (deviceType == DeviceType.largeTablet) {
      scaleFactor = (screenHeight / 1024).clamp(1.0, 1.25);
    } else if (deviceType == DeviceType.tablet) {
      scaleFactor = (screenHeight / 800).clamp(0.95, 1.2);
    } else {
      scaleFactor = (screenHeight / 800).clamp(0.8, 1.2);
    }

    switch (deviceType) {
      case DeviceType.mobile:
        return (12 * scaleFactor);
      case DeviceType.tablet:
        return (16 * scaleFactor);
      case DeviceType.largeTablet:
        return (20 * scaleFactor);
      case DeviceType.iPadPro13:
        return (24 * scaleFactor);
      case DeviceType.desktop:
        return (20 * scaleFactor);
    }
  }

  // ================================
  // COULEURS AUTOMATIQUES PAR THÈME
  // ================================

  /// Couleur de surface basée sur le thème
  static Color getSurfaceColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkCardColor : cardColor;
  }

  /// Couleur de background basée sur le thème
  static Color getBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkBackgroundColor : backgroundColor;
  }

  /// Couleur de texte primaire basée sur le thème
  static Color getPrimaryTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? whiteColor : blackColor;
  }

  /// Couleur de texte secondaire basée sur le thème
  static Color getSecondaryTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? grey300 : grey600;
  }

  /// Couleur de bordure basée sur le thème
  static Color getBorderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? grey700 : grey300;
  }

  // ================================
  // CONFIGURATIONS DE WIDGETS
  // ================================

  /// Hauteur de bouton responsive
  static double getButtonHeight(BuildContext context) {
    final deviceType = getDeviceType(context);
    final screenHeight = MediaQuery.of(context).size.height;
    double scaleFactor;

    if (deviceType == DeviceType.iPadPro13) {
      scaleFactor = (screenHeight / 1024).clamp(1.0, 1.2);
    } else if (deviceType == DeviceType.largeTablet) {
      scaleFactor = (screenHeight / 1024).clamp(0.9, 1.1);
    } else if (deviceType == DeviceType.tablet) {
      scaleFactor = (screenHeight / 800).clamp(0.85, 1.05);
    } else {
      scaleFactor = (screenHeight / 800).clamp(0.8, 1.2);
    }

    switch (deviceType) {
      case DeviceType.mobile:
        return (48 * scaleFactor);
      case DeviceType.tablet:
        return (44 * scaleFactor).clamp(40, 50);
      case DeviceType.largeTablet:
        return (48 * scaleFactor).clamp(44, 54);
      case DeviceType.iPadPro13:
        return (52 * scaleFactor).clamp(48, 58);
      case DeviceType.desktop:
        return (56 * scaleFactor);
    }
  }

  /// Hauteur de conteneur de stats adaptée pour éviter les overflows
  static double getStatsContainerHeight(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 85;
      case DeviceType.tablet:
        return 100; // Réduit davantage pour éviter les overflows
      case DeviceType.largeTablet:
        return 110;
      case DeviceType.iPadPro13:
        return 120;
      case DeviceType.desktop:
        return 120;
    }
  }

  /// Espacement vertical adaptatif pour éviter les overflows
  static double getAdaptiveSpacing(
    BuildContext context, {
    double baseSpacing = 8,
  }) {
    final deviceType = getDeviceType(context);
    final screenHeight = MediaQuery.of(context).size.height;

    double factor;
    switch (deviceType) {
      case DeviceType.mobile:
        factor = (screenHeight / 800).clamp(0.8, 1.2);
        break;
      case DeviceType.tablet:
        factor = (screenHeight / 1024).clamp(
          0.5,
          0.8,
        ); // Réduit encore plus pour tablettes
        break;
      case DeviceType.largeTablet:
        factor = (screenHeight / 1024).clamp(0.7, 1.0);
        break;
      case DeviceType.iPadPro13:
        factor = (screenHeight / 1366).clamp(0.8, 1.2);
        break;
      case DeviceType.desktop:
        factor = 1.0;
        break;
    }

    final result = baseSpacing * factor;
    final maxValue = baseSpacing * 1.5;
    return result.clamp(2.0, maxValue < 2.0 ? baseSpacing : maxValue);
  }

  /// Border radius responsive
  static double getBorderRadius(BuildContext context, BorderRadiusType type) {
    final deviceType = getDeviceType(context);
    final screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor;

    if (deviceType == DeviceType.iPadPro13) {
      scaleFactor = (screenWidth / 1366).clamp(1.1, 1.4);
    } else if (deviceType == DeviceType.largeTablet) {
      scaleFactor = (screenWidth / 1024).clamp(1.0, 1.3);
    } else if (deviceType == DeviceType.tablet) {
      scaleFactor = (screenWidth / 768).clamp(0.95, 1.25);
    } else {
      scaleFactor = (screenWidth / 375).clamp(0.9, 1.3);
    }

    switch (type) {
      case BorderRadiusType.small:
        switch (deviceType) {
          case DeviceType.mobile:
            return (4 * scaleFactor);
          case DeviceType.tablet:
            return (6 * scaleFactor);
          case DeviceType.largeTablet:
            return (7 * scaleFactor);
          case DeviceType.iPadPro13:
            return (8 * scaleFactor);
          case DeviceType.desktop:
            return (8 * scaleFactor);
        }
      case BorderRadiusType.medium:
        switch (deviceType) {
          case DeviceType.mobile:
            return (8 * scaleFactor);
          case DeviceType.tablet:
            return (10 * scaleFactor);
          case DeviceType.largeTablet:
            return (11 * scaleFactor);
          case DeviceType.iPadPro13:
            return (14 * scaleFactor);
          case DeviceType.desktop:
            return (12 * scaleFactor);
        }
      case BorderRadiusType.large:
        switch (deviceType) {
          case DeviceType.mobile:
            return (16 * scaleFactor);
          case DeviceType.tablet:
            return (18 * scaleFactor);
          case DeviceType.largeTablet:
            return (19 * scaleFactor);
          case DeviceType.iPadPro13:
            return (22 * scaleFactor);
          case DeviceType.desktop:
            return (20 * scaleFactor);
        }
      case BorderRadiusType.circular:
        return (50 * scaleFactor);
    }
  }

  /// Élévation d'ombre responsive
  static double getElevation(BuildContext context, ElevationType type) {
    final deviceType = getDeviceType(context);

    switch (type) {
      case ElevationType.none:
        return 0;
      case ElevationType.low:
        switch (deviceType) {
          case DeviceType.mobile:
            return 2;
          case DeviceType.tablet:
            return 3;
          case DeviceType.largeTablet:
            return 3;
          case DeviceType.iPadPro13:
            return 4;
          case DeviceType.desktop:
            return 4;
        }
      case ElevationType.medium:
        switch (deviceType) {
          case DeviceType.mobile:
            return 4;
          case DeviceType.tablet:
            return 6;
          case DeviceType.largeTablet:
            return 7;
          case DeviceType.iPadPro13:
            return 8;
          case DeviceType.desktop:
            return 8;
        }
      case ElevationType.high:
        switch (deviceType) {
          case DeviceType.mobile:
            return 8;
          case DeviceType.tablet:
            return 12;
          case DeviceType.largeTablet:
            return 14;
          case DeviceType.iPadPro13:
            return 16;
          case DeviceType.desktop:
            return 16;
        }
    }
  }

  // ================================
  // THÈME LIGHT
  // ================================

  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'SF-Pro',

      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        surface: cardColor,
        surfaceContainerHighest: backgroundColor,
        error: errorColor,
        onPrimary: whiteColor,
        onSecondary: whiteColor,
        onSurface: blackColor,
        onError: whiteColor,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: whiteColor,
        foregroundColor: blackColor,
        elevation: 0,
        centerTitle: true,
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: whiteColor,
          minimumSize: const Size(double.infinity, 48),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: grey100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: grey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }

  // ================================
  // THÈME DARK
  // ================================

  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackgroundColor,
      fontFamily: 'SF-Pro',

      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        surface: darkCardColor,
        surfaceContainerHighest: darkBackgroundColor,
        error: errorColor,
        onPrimary: whiteColor,
        onSecondary: whiteColor,
        onSurface: whiteColor,
        onError: whiteColor,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: darkCardColor,
        foregroundColor: whiteColor,
        elevation: 0,
        centerTitle: true,
      ),

      cardTheme: CardThemeData(
        color: darkCardColor,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: whiteColor,
          minimumSize: const Size(double.infinity, 48),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: grey800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: grey700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: grey700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }
}

// ================================
// ENUMS POUR LA TYPOLOGIE
// ================================

enum DeviceType { mobile, tablet, largeTablet, iPadPro13, desktop }

enum FontSizeType {
  h1,
  h2,
  h3,
  h4,
  h5,
  h6,
  subtitle1,
  subtitle2,
  body1,
  body2,
  caption,
  overline,
  button,
}

enum BorderRadiusType { small, medium, large, circular }

enum ElevationType { none, low, medium, high }

// ================================
// EXTENSIONS POUR FACILITER L'USAGE
// ================================

extension ThemeExtension on BuildContext {
  /// Accès rapide au système de thème
  AppThemeSystem get appTheme => AppThemeSystem();

  /// Accès rapide aux couleurs du thème
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Vérifie si le thème est sombre
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Type d'appareil
  DeviceType get deviceType => AppThemeSystem.getDeviceType(this);

  /// Vérifie si c'est une tablette ou plus
  bool get isTabletOrLarger => AppThemeSystem.isTabletOrLarger(this);

  /// Espacement horizontal
  double get horizontalPadding => AppThemeSystem.getHorizontalPadding(this);

  /// Espacement vertical
  double get verticalPadding => AppThemeSystem.getVerticalPadding(this);

  /// Espacement entre sections
  double get sectionSpacing => AppThemeSystem.getSectionSpacing(this);

  /// Espacement entre éléments
  double get elementSpacing => AppThemeSystem.getElementSpacing(this);

  /// Couleur de surface
  Color get surfaceColor => AppThemeSystem.getSurfaceColor(this);

  /// Couleur de background
  Color get backgroundColor => AppThemeSystem.getBackgroundColor(this);

  /// Couleur de texte primaire
  Color get primaryTextColor => AppThemeSystem.getPrimaryTextColor(this);

  /// Couleur de texte secondaire
  Color get secondaryTextColor => AppThemeSystem.getSecondaryTextColor(this);

  /// Couleur de bordure
  Color get borderColor => AppThemeSystem.getBorderColor(this);

  /// Hauteur de bouton
  double get buttonHeight => AppThemeSystem.getButtonHeight(this);
}

extension TextStyleExtension on BuildContext {
  /// Génère un TextStyle responsive
  TextStyle textStyle(
    FontSizeType type, {
    FontWeight? fontWeight,
    Color? color,
    double? height,
    bool useGoogleFont = false,
    String fontFamily = 'SF-Pro',
  }) => AppThemeSystem.getTextStyle(
    this,
    type,
    fontWeight: fontWeight,
    color: color,
    height: height,
    useGoogleFont: useGoogleFont,
    fontFamily: fontFamily,
  );

  /// Styles prédéfinis
  TextStyle get h1 => textStyle(FontSizeType.h1, fontWeight: FontWeight.bold);
  TextStyle get h2 => textStyle(FontSizeType.h2, fontWeight: FontWeight.bold);
  TextStyle get h3 => textStyle(FontSizeType.h3, fontWeight: FontWeight.w600);
  TextStyle get h4 => textStyle(FontSizeType.h4, fontWeight: FontWeight.w600);
  TextStyle get h5 => textStyle(FontSizeType.h5, fontWeight: FontWeight.w500);
  TextStyle get h6 => textStyle(FontSizeType.h6, fontWeight: FontWeight.w500);
  TextStyle get subtitle1 =>
      textStyle(FontSizeType.subtitle1, fontWeight: FontWeight.w500);
  TextStyle get subtitle2 =>
      textStyle(FontSizeType.subtitle2, fontWeight: FontWeight.w400);
  TextStyle get body1 => textStyle(FontSizeType.body1);
  TextStyle get body2 => textStyle(FontSizeType.body2);
  TextStyle get caption =>
      textStyle(FontSizeType.caption, color: secondaryTextColor);
  TextStyle get overline =>
      textStyle(FontSizeType.overline, fontWeight: FontWeight.w500);
  TextStyle get button =>
      textStyle(FontSizeType.button, fontWeight: FontWeight.w500);
}

extension BorderRadiusExtension on BuildContext {
  /// Border radius responsive
  BorderRadius borderRadius(BorderRadiusType type) =>
      BorderRadius.circular(AppThemeSystem.getBorderRadius(this, type));
}

extension ElevationExtension on BuildContext {
  /// Élévation responsive
  double elevation(ElevationType type) =>
      AppThemeSystem.getElevation(this, type);
}
