import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../l10n/app_localizations.dart';

/// Page displaying the app's own license (Apache 2.0).
///
/// This page loads the Apache 2.0 license text from assets and displays it
/// in a scrollable view with monospace font for better readability.
class LicenseAgreementPage extends StatelessWidget {
  const LicenseAgreementPage({super.key});

  /// Path to the Apache 2.0 license file in assets.
  static const String _licensePath = 'assets/licenses/Apache-2.0.txt';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = l10n?.license ?? 'License';

    return FutureBuilder<String>(
      future: rootBundle.loadString(_licensePath),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        // Show loading indicator while loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Determine content to display
        final String content;
        if (snapshot.hasData) {
          content = snapshot.data!;
        } else if (snapshot.hasError) {
          content = 'Failed to load license: ${snapshot.error}';
        } else {
          content = 'No license content available.';
        }

        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              content,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }
}
