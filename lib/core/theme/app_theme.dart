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
    surfacePaused: Color(0xFFBF360C), // Deep Orange
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
  ThemeData get themeData => _buildThemeData(tokens);
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
    surfacePressed: Color(0xFF222222),
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
  ThemeData get themeData => _buildThemeData(tokens);
}

ThemeData _buildThemeData(AppThemeTokens tokens) {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: tokens.bg,
    colorScheme: ColorScheme.dark(
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
      primary: tokens.accent,
      onPrimary: tokens.bg,
      error: tokens.danger,
      onError: tokens.textPrimary,
      secondary: tokens.textSecondary,
    ),
    cardTheme: CardThemeData(
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.border, width: 1),
      ),
    ),
    iconTheme: IconThemeData(color: tokens.icon),
    dividerTheme: DividerThemeData(color: tokens.divider),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: tokens.accent,
        foregroundColor: tokens.bg,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: tokens.border, width: 1),
        ),
      ),
    ),
  );
}
