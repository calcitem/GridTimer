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
