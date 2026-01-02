// constants.dart

/// Application constants
class Constants {
  const Constants._();

  // Project information
  static const String projectName = "GridTimer";
  static String projectNameLower = projectName.toLowerCase();

  // Email configuration for error reports
  static const List<String> recipientEmails = <String>[
    // Add your support email here
    "calcitem@outlook.com",
  ];

  // File names
  static const String crashLogsFile = "$projectName-crash-logs.txt";
}
