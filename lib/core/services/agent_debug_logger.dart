import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Debug-only logger for Cursor "DEBUG MODE" sessions.
///
/// This sends NDJSON-style payloads to the local ingest server, which then writes
/// to the workspace debug log file configured by the IDE.
///
/// IMPORTANT: This is intended for debugging only. All side effects are guarded
/// by assert() so they are stripped in release builds.
class AgentDebugLogger {
  static final Uri _endpoint = Uri.parse(
    'http://127.0.0.1:7242/ingest/6b68d88a-4014-42e5-beb0-a35903bb0943',
  );

  static const String sessionId = 'debug-session';

  /// Tag runs without changing code:
  /// `flutter run --dart-define=GT_DEBUG_RUN_ID=post-fix`
  static const String runId = String.fromEnvironment(
    'GT_DEBUG_RUN_ID',
    defaultValue: 'baseline',
  );

  static void log({
    required String hypothesisId,
    required String location,
    required String message,
    Map<String, Object?> data = const <String, Object?>{},
  }) {
    assert(() {
      unawaited(
        _post(<String, Object?>{
          'sessionId': sessionId,
          'runId': runId,
          'hypothesisId': hypothesisId,
          'location': location,
          'message': message,
          'data': data,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      );
      return true;
    }());
  }

  static Future<void> _post(Map<String, Object?> payload) async {
    try {
      final client = HttpClient();
      final request = await client.postUrl(_endpoint);
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close();
      await response.drain<void>();
      client.close(force: true);
    } catch (_) {
      // Ignore any logging failures in debug mode.
    }
  }
}
