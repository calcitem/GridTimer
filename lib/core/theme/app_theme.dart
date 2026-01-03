import 'package:flutter/material.dart';

/// Semantic color tokens for the application.
class AppThemeTokens {
  final Color bg;
  final Color surface;
  final Color surfacePressed;
  final Color surfaceDisabled;

  // Status-specific surfaces (for Timer Cards)
  final Color surfaceIdle;
  final Color surfaceRunning;
  final Color surfacePaused;
  final Color surfaceRinging;

  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color focusRing;

  // Semantic status colors (for text/icons)
  final Color success;
  final Color warning;
  final Color danger;

  // Specific UI elements
  final Color icon;
  final Color divider;

  const AppThemeTokens({
    required this.bg,
    required this.surface,
    required this.surfacePressed,
    required this.surfaceDisabled,
    required this.surfaceIdle,
    required this.surfaceRunning,
    required this.surfacePaused,
    required this.surfaceRinging,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.focusRing,
    required this.success,
    required this.warning,
    required this.danger,
    required this.icon,
    required this.divider,
  });
}

/// Base class for App Themes.
abstract class AppTheme {
  String get id;
  String get name;
  AppThemeTokens get tokens;
  ThemeData get themeData;
}

/// Theme A: Default Soft Dark Mode.
class SoftDarkTheme extends AppTheme {
  @override
  String get id => 'soft_dark';

  @override
  String get name => 'Soft Dark';

  @override
  AppThemeTokens get tokens => const AppThemeTokens(
    bg: Color(0xFF121212),
    surface: Color(0xFF2C2C2C),
    surfacePressed: Color(0xFF3E3E3E),
    surfaceDisabled: Color(0xFF1E1E1E),

    // Colored backgrounds for states (Standard Mode)
    surfaceIdle: Color(0xFF2C2C2C),
    surfaceRunning: Color(0xFF1B5E20), // Dark Green
    surfacePaused: Color(0xFF8A2A0A), // Deep Orange (higher contrast)
    surfaceRinging: Color(0xFFB71C1C), // Deep Red

    border: Color(0xFF3A3A3A),
    textPrimary: Color(0xFFE0E0E0),
    textSecondary: Color(0xFFFFB74D), // Amber
    accent: Color(0xFFFFB74D),
    focusRing: Color(0xFFFFD54F),
    success: Color(0xFF43A047),
    warning: Color(0xFFFB8C00),
    danger: Color(0xFFE53935),
    icon: Color(0xFFE0E0E0),
    divider: Color(0xFF3A3A3A),
  );

  @override
  ThemeData get themeData => _buildThemeData(tokens, borderWidth: 1);
}

/// Theme B: High Contrast Mode.
class HighContrastTheme extends AppTheme {
  @override
  String get id => 'high_contrast';

  @override
  String get name => 'High Contrast';

  @override
  AppThemeTokens get tokens => const AppThemeTokens(
    bg: Color(0xFF000000),
    surface: Color(0xFF000000),
    surfacePressed: Color(0xFF424242), // Lighter grey for visible feedback
    surfaceDisabled: Color(0xFF111111),

    // Unified background for states (High Contrast - rely on text/border)
    surfaceIdle: Color(0xFF000000),
    surfaceRunning: Color(0xFF000000),
    surfacePaused: Color(0xFF000000),
    surfaceRinging: Color(0xFF000000),

    border: Color(0xFFFFFFFF), // Strong White Border
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFFFFF00), // Yellow
    accent: Color(0xFFFFFF00),
    focusRing: Color(0xFFFFFF00),
    success: Color(0xFF00FF00),
    warning: Color(0xFFFF0000),
    danger: Color(0xFFFF0000),
    icon: Color(0xFFFFFFFF),
    divider: Color(0xFFFFFFFF),
  );

  @override
  ThemeData get themeData => _buildThemeData(tokens, borderWidth: 2);
}

/// Theme C: Light High Contrast Mode.
class LightHighContrastTheme extends AppTheme {
  @override
  String get id => 'light_high_contrast';

  @override
  String get name => 'Light High Contrast';

  @override
  AppThemeTokens get tokens => const AppThemeTokens(
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFF0F0F0),
    surfacePressed: Color(0xFFE0E0E0),
    surfaceDisabled: Color(0xFFCCCCCC),

    // Distinct colors for states, but optimized for light mode
    surfaceIdle: Color(0xFFF5F5F5), // Near white
    surfaceRunning: Color(0xFFE8F5E9), // Very light green
    surfacePaused: Color(0xFFFFF3E0), // Very light orange
    surfaceRinging: Color(0xFFFFEBEE), // Very light red

    border: Color(0xFF000000), // Stark black border
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF000000), // Black for max contrast
    accent: Color(0xFF0000AA), // Deep Blue for primary actions
    focusRing: Color(0xFF000000),
    success: Color(0xFF006400), // Dark green
    warning: Color(0xFFE65100), // Dark orange
    danger: Color(0xFFB71C1C), // Dark red
    icon: Color(0xFF000000),
    divider: Color(0xFF000000),
  );

  @override
  ThemeData get themeData =>
      _buildThemeData(tokens, borderWidth: 2, isDark: false);
}

/// Theme D: Traditional Theme (Warm, muted tones preferred by seniors)
class TraditionalTheme extends AppTheme {
  @override
  String get id => 'traditional';

  @override
  String get name => 'Traditional';

  @override
  AppThemeTokens get tokens => const AppThemeTokens(
    bg: Color(0xFFF5F1E8), // Washi paper color (off-white/beige)
    surface: Color(0xFFE6DBC6), // Slightly darker beige
    surfacePressed: Color(0xFFD4C5A9),
    surfaceDisabled: Color(0xFFC7BCA5),

    // Subdued, natural colors for states
    surfaceIdle: Color(0xFFE6DBC6),
    surfaceRunning: Color(0xFF8DA399), // Matcha Green (muted green)
    surfacePaused: Color(0xFFD4A59A), // Old Rose (muted pink/red)
    surfaceRinging: Color(0xFFC97F7F), // Muted Red

    border: Color(0xFF594F4F), // Dark Brown/Grey (Sumi ink-like but softer)
    textPrimary: Color(0xFF4A403A), // Dark Brown (Tea color)
    textSecondary: Color(0xFF7D7269), // Muted Brown
    accent: Color(0xFF9E7A7A), // Azuki Red (Muted Red/Brown)
    focusRing: Color(0xFFD4A59A), // Matches paused state
    success: Color(0xFF6B8E23), // Olive Green
    warning: Color(0xFFCD853F), // Peru (muted orange)
    danger: Color(0xFFB22222), // Firebrick (muted red)
    icon: Color(0xFF4A403A), // Match text primary
    divider: Color(0xFF8C8279), // Grey-brown
  );

  @override
  ThemeData get themeData =>
      _buildThemeData(tokens, borderWidth: 1.5, isDark: false);
}

/// Theme E: Pastel Garden (Subtle pastels, airy, modern traditional)
class PastelGardenTheme extends AppTheme {
  @override
  String get id => 'pastel_garden';

  @override
  String get name => 'Pastel Garden';

  @override
  AppThemeTokens get tokens => const AppThemeTokens(
    bg: Color(0xFFF8F9FA), // Off-white/Clean greyish white
    surface: Color(0xFFFFFFFF), // Pure white
    surfacePressed: Color(0xFFE9ECEF),
    surfaceDisabled: Color(0xFFDEE2E6),

    // Pastel tones commonly found in Hanbok/modern Korean design
    surfaceIdle: Color(0xFFFFFFFF),
    surfaceRunning: Color(0xFFD4E4BC), // Pale Green (Jade-like)
    surfacePaused: Color(0xFFFBE4D8), // Pale Pink/Peach
    surfaceRinging: Color(0xFFFFC9C9), // Light Coral Red

    border: Color(0xFFADB5BD), // Clean Grey
    textPrimary: Color(0xFF343A40), // Dark Grey (Charcoal)
    textSecondary: Color(0xFF6C757D), // Medium Grey
    accent: Color(0xFF9FA8DA), // Periwinkle Blue (Serenity)
    focusRing: Color(0xFFFBE4D8),
    success: Color(0xFF82C91E), // Lime Green
    warning: Color(0xFFFD7E14), // Orange
    danger: Color(0xFFFA5252), // Red
    icon: Color(0xFF495057),
    divider: Color(0xFFE9ECEF),
  );

  @override
  ThemeData get themeData =>
      _buildThemeData(tokens, borderWidth: 1.0, isDark: false);
}

/// Theme F: Ink & Vermilion (Ink, Rice Paper, Vermilion - High legibility)
class InkVermilionTheme extends AppTheme {
  @override
  String get id => 'ink_vermilion';

  @override
  String get name => 'Ink & Vermilion';

  @override
  AppThemeTokens get tokens => const AppThemeTokens(
    bg: Color(0xFFF7F7F7), // Very Light Grey (Clean, modern paper)
    surface: Color(0xFFFFFFFF), // Pure White
    surfacePressed: Color(0xFFEEEEEE),
    surfaceDisabled: Color(0xFFE0E0E0),

    // Traditional but functional colors (Ink & Vermilion)
    surfaceIdle: Color(0xFFFFFFFF),
    surfaceRunning: Color(0xFFE8F5E9), // Very pale green tint
    surfacePaused: Color(0xFFFFF3E0), // Very pale orange tint
    surfaceRinging: Color(0xFFFFEBEE), // Very pale red tint

    border: Color(0xFF8D6E63), // Brownish Grey (Subtle frame)
    textPrimary: Color(0xFF212121), // Ink Black (Very high contrast)
    textSecondary: Color(0xFF757575), // Grey
    accent: Color(0xFFB71C1C), // Vermilion / Chinese Red (Deep, authoritative)
    focusRing: Color(0xFFD32F2F),
    success: Color(0xFF2E7D32), // Bamboo Green
    warning: Color(0xFFEF6C00), // Persimmon Orange
    danger: Color(0xFFC62828), // Rich Red
    icon: Color(0xFFB71C1C), // Red icons for vitality
    divider: Color(0xFFBDBDBD),
  );

  @override
  ThemeData get themeData =>
      _buildThemeData(tokens, borderWidth: 1.5, isDark: false);
}

/// Theme G: Glacial Blue (Cool greys, blues, nature-inspired, high legibility)
class GlacialBlueTheme extends AppTheme {
  @override
  String get id => 'glacial_blue';

  @override
  String get name => 'Glacial Blue';

  @override
  AppThemeTokens get tokens => const AppThemeTokens(
    bg: Color(0xFFECEFF1), // Blue-grey white
    surface: Color(0xFFFFFFFF),
    surfacePressed: Color(0xFFCFD8DC),
    surfaceDisabled: Color(0xFFB0BEC5),

    // Cool, calm nature tones
    surfaceIdle: Color(0xFFFFFFFF),
    surfaceRunning: Color(0xFFB2DFDB), // Teal 100
    surfacePaused: Color(0xFFFFF9C4), // Pale Yellow
    surfaceRinging: Color(0xFFFFCCBC), // Deep Orange 100

    border: Color(0xFF546E7A), // Blue-grey
    textPrimary: Color(0xFF263238), // Dark Blue-grey
    textSecondary: Color(0xFF546E7A), // Medium Blue-grey
    accent: Color(0xFF009688), // Teal
    focusRing: Color(0xFF80CBC4),
    success: Color(0xFF00796B),
    warning: Color(0xFFF57C00),
    danger: Color(0xFFD32F2F),
    icon: Color(0xFF37474F),
    divider: Color(0xFFCFD8DC),
  );

  @override
  ThemeData get themeData =>
      _buildThemeData(tokens, borderWidth: 1.0, isDark: false);
}

/// Theme H: Classic Navy (High contrast, bold blue/white/red hints, sturdy)
class ClassicNavyTheme extends AppTheme {
  @override
  String get id => 'classic_navy';

  @override
  String get name => 'Classic Navy';

  @override
  AppThemeTokens get tokens => const AppThemeTokens(
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFF5F5F5), // Light Grey
    surfacePressed: Color(0xFFE0E0E0),
    surfaceDisabled: Color(0xFFBDBDBD),

    // Familiar, standard functional colors
    surfaceIdle: Color(0xFFF5F5F5),
    surfaceRunning: Color(0xFFE3F2FD), // Light Blue
    surfacePaused: Color(0xFFFFF3E0), // Light Orange
    surfaceRinging: Color(0xFFFFEBEE), // Light Red

    border: Color(0xFF1565C0), // Corporate Blue (Trustworthy)
    textPrimary: Color(0xFF0D47A1), // Dark Blue (High readability)
    textSecondary: Color(0xFF424242), // Dark Grey
    accent: Color(0xFFD32F2F), // Red (Accent)
    focusRing: Color(0xFF64B5F6),
    success: Color(0xFF2E7D32),
    warning: Color(0xFFEF6C00),
    danger: Color(0xFFC62828),
    icon: Color(0xFF1565C0), // Blue icons
    divider: Color(0xFF1565C0),
  );

  @override
  ThemeData get themeData =>
      _buildThemeData(tokens, borderWidth: 2.0, isDark: false);
}

ThemeData _buildThemeData(
  AppThemeTokens tokens, {
  required double borderWidth,
  bool isDark = true,
}) {
  final secondaryText = tokens.textPrimary.withValues(alpha: 0.7);

  return ThemeData(
    brightness: isDark ? Brightness.dark : Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: tokens.bg,
    colorScheme: isDark
        ? ColorScheme.dark(
            surface: tokens.surface,
            onSurface: tokens.textPrimary,
            primary: tokens.accent,
            onPrimary: tokens.bg,
            onSecondary: tokens.bg,
            error: tokens.danger,
            onError: tokens.textPrimary,
            secondary: tokens.textSecondary,
          )
        : ColorScheme.light(
            surface: tokens.surface,
            onSurface: tokens.textPrimary,
            primary: tokens.accent,
            onPrimary: tokens.bg,
            onSecondary: tokens.bg,
            error: tokens.danger,
            onError: tokens.textPrimary,
            secondary: tokens.textSecondary,
          ),
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.bg,
      foregroundColor: tokens.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        color: tokens.textPrimary,
        height: 1.1,
      ),
      iconTheme: IconThemeData(color: tokens.textPrimary, size: 28),
    ),
    cardTheme: CardThemeData(
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.border, width: borderWidth),
      ),
    ),
    iconTheme: IconThemeData(color: tokens.icon, size: 28),
    dividerTheme: DividerThemeData(
      color: tokens.divider,
      thickness: borderWidth,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: tokens.textPrimary,
        height: 1.2,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 18,
        color: secondaryText,
        height: 1.35,
      ),
      iconColor: tokens.icon,
      tileColor: Colors.transparent,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        fontSize: 20,
        color: tokens.textPrimary,
        height: 1.3,
      ),
      bodyMedium: TextStyle(
        fontSize: 18,
        color: tokens.textPrimary,
        height: 1.3,
      ),
      bodySmall: TextStyle(fontSize: 16, color: secondaryText, height: 1.3),
      titleMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: tokens.textPrimary,
        height: 1.2,
      ),
      titleSmall: TextStyle(fontSize: 18, color: secondaryText, height: 1.2),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: tokens.border, width: borderWidth),
      ),
      titleTextStyle: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        color: tokens.textPrimary,
        height: 1.2,
      ),
      contentTextStyle: TextStyle(
        fontSize: 20,
        color: tokens.textPrimary,
        height: 1.35,
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: tokens.accent,
        foregroundColor: tokens.bg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: tokens.border, width: borderWidth),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: tokens.accent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.all(tokens.border),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return tokens.accent;
        }
        return tokens.surfaceDisabled;
      }),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return tokens.bg;
        }
        return tokens.textPrimary;
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.surfacePressed,
      labelStyle: TextStyle(fontSize: 18, color: secondaryText),
      floatingLabelStyle: TextStyle(fontSize: 20, color: tokens.accent),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.border, width: borderWidth),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.border, width: borderWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.focusRing, width: borderWidth + 1),
      ),
    ),
  );
}
