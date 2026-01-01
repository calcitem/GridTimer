import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';

/// Privacy policy dialog shown on first app launch for Chinese locale users.
///
/// This dialog displays a privacy policy notice and allows the user to view
/// the full privacy policy on the website before agreeing to continue.
class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  /// Chinese privacy policy URL.
  static const String _privacyPolicyUrlZh =
      'https://calcitem.github.io/GridTimer/privacy-policy_zh';

  /// Show the privacy policy dialog.
  ///
  /// Returns true if user clicks "I Agree", false otherwise.
  /// The dialog cannot be dismissed by tapping outside (barrierDismissible: false).
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must explicitly click a button
      builder: (context) => const PrivacyPolicyDialog(),
    );
    return result ?? false;
  }

  /// Launch the privacy policy URL in browser.
  Future<void> _launchPrivacyPolicy() async {
    final uri = Uri.parse(_privacyPolicyUrlZh);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
