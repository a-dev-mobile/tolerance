// engineering_theme.dart - Fixed version of the custom theme
import 'package:flutter/material.dart';

/// Engineering-specific theme class for consistent styling
class EngineeringTheme {
  // Primary colors
  static const Color primaryBlue = Color(0xFF0D47A1);
  static const Color secondaryBlue = Color(0xFF2196F3);
  static const Color accentOrange = Color(0xFFFF5722);

  // Functional colors
  static const Color successColor = Color(0xFF00897B);
  static const Color infoColor = Color(0xFF0277BD);
  static const Color warningColor = Color(0xFFFF8F00);
  static const Color errorColor = Color(0xFFC62828);
  static const Color highlightColor = Color(0xFFFFD54F);

  // Light theme colors
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF263238);
  static const Color lightTextSecondary = Color(0xFF546E7A);
  static const Color lightDivider = Color(0xFFCFD8DC);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFF9E9E9E);
  static const Color darkDivider = Color(0xFF424242);

  /// Специальный цвет для обозначения отверстий
  static const Color holeColor = Color(0xFF0277BD); // #0277BD

  /// Специальный цвет для обозначения валов
  static const Color shaftColor = Color(0xFF558B2F);
  // static const Color shaftColor =  Color(0xFF4F96C1);
  // static const Color shaftColor =  Color(0xFF3C88AE);
  // static const Color shaftColor =  Color(0xFF1A84A7);
  // static const Color shaftColor =  Color(0xFF478CAD);
  // static const Color shaftColor =  Color(0xFFEB5757);
  // static const Color shaftColor =  Color(0xFFC78E4B);
  // static const Color shaftColor =  Color(0xFFBDA602);

  /// Get the appropriate text color based on brightness
  static Color getTextColor(Brightness brightness, bool isPrimary) {
    if (brightness == Brightness.light) {
      return isPrimary ? lightTextPrimary : lightTextSecondary;
    } else {
      return isPrimary ? darkTextPrimary : darkTextSecondary;
    }
  }

  /// Get the appropriate background color based on brightness
  static Color getBackgroundColor(Brightness brightness) {
    return brightness == Brightness.light ? lightBackground : darkBackground;
  }

  /// Get the appropriate surface color based on brightness
  static Color getSurfaceColor(Brightness brightness) {
    return brightness == Brightness.light ? lightSurface : darkSurface;
  }

  /// Get the appropriate divider color based on brightness
  static Color getDividerColor(Brightness brightness) {
    return brightness == Brightness.light ? lightDivider : darkDivider;
  }

  /// Get functional color with adjusted opacity and brightness
  static Color getFunctionalColor(
    Color baseColor,
    Brightness brightness, {
    double opacity = 1.0,
    double intensity = 1.0,
  }) {
    // For dark mode, make functional colors slightly lighter
    if (brightness == Brightness.dark && opacity == 1.0) {
      // Create a lighter version for dark mode
      final HSLColor hslColor = HSLColor.fromColor(baseColor);
      final adjustedColor =
          hslColor
              .withLightness((hslColor.lightness + 0.15).clamp(0.0, 1.0))
              .toColor();
      return adjustedColor.withAlpha((opacity * 255).toInt());
    }

    return baseColor.withAlpha((opacity * intensity * 255).toInt());
  }

  /// Creates a light theme with engineering-specific styling
  static ThemeData lightTheme() {
    return ThemeData(
      primaryColor: primaryBlue,
      colorScheme: ColorScheme.light(
        primary: primaryBlue,
        secondary: secondaryBlue,
        surface: lightSurface,
        error: errorColor,
      ),
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightSurface,
      dividerColor: lightDivider,
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: lightTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: lightTextPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: lightTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: lightTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: lightTextPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: lightTextSecondary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        elevation: 2,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: const BorderSide(color: primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: lightTextSecondary),
        hintStyle: const TextStyle(color: lightTextSecondary),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: lightSurface,
      ),
      dialogTheme: DialogTheme(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: lightSurface,
      ),
    );
  }

  /// Creates a dark theme with engineering-specific styling
  static ThemeData darkTheme() {
    return ThemeData(
      primaryColor: primaryBlue,
      colorScheme: ColorScheme.dark(
        primary: secondaryBlue,
        secondary: primaryBlue,
        surface: darkSurface,
        error: errorColor,
      ),
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkSurface,
      dividerColor: darkDivider,
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: darkTextPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: darkTextSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 2,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        iconTheme: const IconThemeData(color: darkTextPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: const BorderSide(color: secondaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: secondaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: darkTextSecondary),
        hintStyle: const TextStyle(color: darkTextSecondary),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: darkSurface,
      ),
      dialogTheme: DialogTheme(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: darkSurface,
      ),
    );
  }

  /// Creates an widget styling extension for use in the application
  static EngineeringWidgetStyle widgetStyle(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return EngineeringWidgetStyle(brightness);
  }
}

/// Contains styling for specific engineering widgets
class EngineeringWidgetStyle {
  final Brightness brightness;

  const EngineeringWidgetStyle(this.brightness);

  /// Get the color for minimum value display
  Color get minValueColor => EngineeringTheme.getFunctionalColor(
    EngineeringTheme.successColor,
    brightness,
  );

  /// Get the color for maximum value display
  Color get maxValueColor => EngineeringTheme.getFunctionalColor(
    EngineeringTheme.errorColor,
    brightness,
  );

  /// Get the color for nominal value display
  Color get nominalValueColor => EngineeringTheme.getFunctionalColor(
    EngineeringTheme.infoColor,
    brightness,
  );

  /// Get the color for average value display
  Color get avgValueColor => EngineeringTheme.getFunctionalColor(
    EngineeringTheme.warningColor,
    brightness,
  );

  /// Get the color for warning messages
  Color get warningColor => EngineeringTheme.getFunctionalColor(
    EngineeringTheme.accentOrange,
    brightness,
  );

  /// Get the background color for cards
  Color get cardBackground =>
      brightness == Brightness.light
          ? Colors.grey.shade200.withAlpha(153) // 0.6 * 255 = 153
          : Colors.grey.shade800.withAlpha(77); // 0.3 * 255 = 77

  /// Get the background color for value rows
  Color get valueRowBackground =>
      brightness == Brightness.light
          ? Colors.white.withAlpha(217) // 0.85 * 255 = 217
          : Colors.grey.shade900.withAlpha(77); // 0.3 * 255 = 77

  /// Get the appropriate text color
  Color get textPrimary => EngineeringTheme.getTextColor(brightness, true);

  /// Get the appropriate secondary text color
  Color get textSecondary => EngineeringTheme.getTextColor(brightness, false);

  /// Get the background color for the app
  Color get background => EngineeringTheme.getBackgroundColor(brightness);

  /// Get the surface color for cards and dialogs
  Color get surface => EngineeringTheme.getSurfaceColor(brightness);

  /// Get the divider color
  Color get divider => EngineeringTheme.getDividerColor(brightness);

  /// Get the highlight color for search results
  Color get highlight =>
      brightness == Brightness.light
          ? EngineeringTheme.highlightColor.withAlpha(102) // 0.4 * 255 = 102
          : EngineeringTheme.highlightColor.withAlpha(77); // 0.3 * 255 = 77

  /// Get the interval background color
  Color get intervalBackground =>
      brightness == Brightness.light
          ? EngineeringTheme.infoColor.withAlpha(20) // 0.08 * 255 = 20
          : EngineeringTheme.infoColor.withAlpha(38); // 0.15 * 255 = 38

  /// Get direct access to info color
  Color get infoColor => EngineeringTheme.infoColor;

  /// Get direct access to error color
  Color get errorColor => EngineeringTheme.errorColor;

  get shaftColor => EngineeringTheme.shaftColor;

  /// Get styling for an engineering card container
  BoxDecoration getCardDecoration({Color? customColor, double opacity = 0.6}) {
    final color = customColor ?? cardBackground;
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(
            brightness == Brightness.light ? 20 : 51,
          ), // 0.08, 0.2
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Get styling for a value row container in the tolerance calculator
  BoxDecoration getValueRowDecoration(Color accentColor) {
    return BoxDecoration(
      color: valueRowBackground,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: accentColor.withAlpha(
          brightness == Brightness.light ? 51 : 77,
        ), // 0.2, 0.3
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: accentColor.withAlpha(
            brightness == Brightness.light ? 26 : 38,
          ), // 0.1, 0.15
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }
}
