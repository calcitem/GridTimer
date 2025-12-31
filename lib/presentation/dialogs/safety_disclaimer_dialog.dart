import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Safety disclaimer dialog shown on first launch.
/// 
/// This dialog serves both legal protection and user education purposes.
/// It clearly communicates the app's limitations while maintaining a
/// friendly, non-alarming tone.
class SafetyDisclaimerDialog extends StatelessWidget {
  const SafetyDisclaimerDialog({super.key});

  /// Show the safety disclaimer dialog.
  /// 
  /// Returns true if user accepts, false if dismissed.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must explicitly accept
      builder: (context) => const SafetyDisclaimerDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const SizedBox.shrink();
    }

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.safetyDisclaimerTitle,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main message
            Text(
              l10n.safetyDisclaimerMessage,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            
            // Recommended uses (green box)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.safetyRecommendedUses,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.safetyRecommendedUsesList,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Not recommended uses (red box)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.safetyNotRecommendedUses,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.safetyNotRecommendedUsesList,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Best practices
            Text(
              l10n.safetyBestPractices,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.safetyBestPracticesList,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ),
      actions: [
        // View full disclaimer button
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            _showFullDisclaimer(context);
          },
          child: Text(l10n.safetyViewFullDisclaimer),
        ),
        // Accept button
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: Text(l10n.safetyAcceptAndContinue),
        ),
      ],
    );
  }

  /// Show full legal disclaimer text.
  static void _showFullDisclaimer(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.fullDisclaimerTitle),
        content: SingleChildScrollView(
          child: Text(
            l10n.fullDisclaimerText,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}
