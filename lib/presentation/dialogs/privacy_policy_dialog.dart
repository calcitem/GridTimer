import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/environment_config.dart';
import '../../core/config/supported_locales.dart';
import '../../l10n/app_localizations.dart';

/// Privacy policy dialog shown on first app launch for locales that require it.
///
/// This dialog displays a privacy policy notice and allows the user to view
/// the full privacy policy on the website before agreeing to continue.
///
/// Which locales require this dialog is configured in [SupportedLocales].
class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key, required this.privacyPolicyUrl});

  /// Privacy policy URL to display.
  final String privacyPolicyUrl;

  /// Show the privacy policy dialog.
  ///
  /// [privacyPolicyUrl] - The URL to the privacy policy page. If not provided,
  /// falls back to the default URL from [SupportedLocales].
  ///
  /// Returns true if user clicks "I Agree", false otherwise.
  /// The dialog cannot be dismissed by tapping outside (barrierDismissible: false).
  static Future<bool> show(
    BuildContext context, {
    String? privacyPolicyUrl,
  }) async {
    final url = privacyPolicyUrl ?? SupportedLocales.defaultPrivacyPolicyUrl;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must explicitly click a button
      builder: (context) => PrivacyPolicyDialog(privacyPolicyUrl: url),
    );
    return result ?? false;
  }

  /// Launch the privacy policy URL in browser.
  Future<void> _launchPrivacyPolicy() async {
    // Block URL launching in test environment to prevent interference with Monkey testing
    if (EnvironmentConfig.test) {
      debugPrint('URL launch blocked in test environment: $privacyPolicyUrl');
      return;
    }

    final uri = Uri.parse(privacyPolicyUrl);
    // Try to launch URL directly without canLaunchUrl check
    // canLaunchUrl can return false on some devices even when URL can be launched
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Failed to launch URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const SizedBox.shrink();
    }

    return AlertDialog(
      title: Semantics(
        header: true,
        child: Row(
          children: [
            const Icon(Icons.privacy_tip, color: Color(0xFFFFD600), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.privacyPolicyTitle,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main message
            Text(
              l10n.privacyPolicyMessage,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Privacy policy link button
            Center(
              child: OutlinedButton.icon(
                onPressed: _launchPrivacyPolicy,
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.privacyPolicyViewDetails),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFD600),
                  side: const BorderSide(color: Color(0xFFFFD600)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Agree button - closes dialog and saves acceptance
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: Text(l10n.privacyPolicyAgree),
        ),
      ],
    );
  }
}
