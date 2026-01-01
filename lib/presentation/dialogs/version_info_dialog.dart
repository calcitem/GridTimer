// Copyright (C) 2025 GridTimer developers
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import '../../core/services/git_info.dart';
import '../../l10n/app_localizations.dart';

/// Version information dialog showing app version and Git information.
class VersionInfoDialog extends StatelessWidget {
  const VersionInfoDialog({super.key});

  /// Show the version information dialog.
  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const VersionInfoDialog(),
    );
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
          const Icon(Icons.info_outline, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(l10n.versionInfo, style: const TextStyle(fontSize: 20)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App version
            Text(l10n.version, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            const Text('1.0.0+1', style: TextStyle(fontSize: 15)),
            const SizedBox(height: 16),

            // Git information
            FutureBuilder<GitInfo>(
              future: gitInfo,
              builder: (BuildContext context, AsyncSnapshot<GitInfo> snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final GitInfo info = snapshot.data!;
                final List<Widget> rows = <Widget>[
                  Text(
                    l10n.gitBranch,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    info.branch,
                    style: const TextStyle(
                      fontSize: 15,
                      fontFamily: 'monospace',
                    ),
                  ),
                ];

                // Revision can be absent when no git metadata is packaged.
                if (info.revision != null && info.revision!.isNotEmpty) {
                  rows.addAll([
                    const SizedBox(height: 16),
                    Text(
                      l10n.gitRevision,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      info.revision!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: 'Courier New',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ]);
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rows,
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
