import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_timer/core/theme/app_theme.dart';

double _srgbToLinear(int channel) {
  final c = channel / 255.0;
  if (c <= 0.03928) return c / 12.92;
  return pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double _relativeLuminance(Color color) {
  int to8Bit(double v) => (v * 255.0).round().clamp(0, 255);

  final r = _srgbToLinear(to8Bit(color.r));
  final g = _srgbToLinear(to8Bit(color.g));
  final b = _srgbToLinear(to8Bit(color.b));
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double contrastRatio(Color a, Color b) {
  final l1 = _relativeLuminance(a);
  final l2 = _relativeLuminance(b);
  final light = max(l1, l2);
  final dark = min(l1, l2);
  return (light + 0.05) / (dark + 0.05);
}

void main() {
  group('Theme contrast (WCAG)', () {
    test('SoftDarkTheme: key foreground/background pairs >= 4.5:1', () {
      final t = SoftDarkTheme().tokens;

      // Main digits should be safe on all state surfaces.
      expect(contrastRatio(t.textPrimary, t.surfaceIdle), greaterThanOrEqualTo(4.5));
      expect(
        contrastRatio(t.textPrimary, t.surfaceRunning),
        greaterThanOrEqualTo(4.5),
      );
      expect(contrastRatio(t.textPrimary, t.surfacePaused), greaterThanOrEqualTo(4.5));
      expect(
        contrastRatio(t.textPrimary, t.surfaceRinging),
        greaterThanOrEqualTo(4.5),
      );

      // Labels (minutes / preset) should remain AA.
      expect(
        contrastRatio(t.textSecondary, t.surfaceIdle),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastRatio(t.textSecondary, t.surfaceRunning),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastRatio(t.textSecondary, t.surfacePaused),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastRatio(t.focusRing, t.surfaceRinging),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('HighContrastTheme: key foreground/background pairs >= 7:1', () {
      final t = HighContrastTheme().tokens;

      // High contrast mode aims for AAA where possible.
      expect(contrastRatio(t.textPrimary, t.bg), greaterThanOrEqualTo(7.0));
      expect(contrastRatio(t.textSecondary, t.bg), greaterThanOrEqualTo(7.0));
    });
  });
}


