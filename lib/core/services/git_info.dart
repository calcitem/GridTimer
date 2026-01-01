// Copyright (C) 2025 GridTimer developers
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/services.dart';

/// Information about the local Git repository.
class GitInfo {
  /// Construct a [GitInfo] from a [branch] and [revision].
  const GitInfo({required this.branch, required this.revision});

  /// The current checked out branch.
  final String branch;

  /// The current commit id (SHA-1 hash).
  final String? revision;
}

/// Get the [GitInfo] for the local Git repository.
///
/// This reads the Git information from bundled text files that are generated
/// during the build process by flutter-init.sh.
Future<GitInfo> get gitInfo async {
  final String branch = (await rootBundle.loadString(
    'assets/files/git-branch.txt',
  )).trim();
  final String revisionRaw = (await rootBundle.loadString(
    'assets/files/git-revision.txt',
  )).trim();

  final String? revision = revisionRaw.isEmpty ? null : revisionRaw;

  return GitInfo(branch: branch, revision: revision);
}
