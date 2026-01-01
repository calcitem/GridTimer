// environment_config.dart

/// Environment configuration
///
/// Enables device to start the app with compile time options
class EnvironmentConfig {
  const EnvironmentConfig._();

  /// Gets whether we build for testing
  static bool test = const bool.fromEnvironment('test');

  /// Gets whether we build for devMode
  static bool devMode = const bool.fromEnvironment('dev_mode');

  /// Gets whether we want catcher to be enabled
  /// Defaults to true
  static bool catcher = const bool.fromEnvironment(
    "catcher",
    defaultValue: true,
  );

  /// Gets log level
  /// Defaults to 0 (all) to record all logs for user viewing
  /// Level values: 0=all, 1=trace, 2=debug, 3=info, 4=warning, 5=error, 6=fatal
  static const int logLevel = int.fromEnvironment("log_level");
}

