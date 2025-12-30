/// Clock abstraction for testability.
abstract interface class IClock {
  /// Returns current epoch milliseconds (UTC).
  int nowEpochMs();

  /// Returns current DateTime.
  DateTime now();
}

/// System clock implementation.
class SystemClock implements IClock {
  const SystemClock();

  @override
  int nowEpochMs() => DateTime.now().millisecondsSinceEpoch;

  @override
  DateTime now() => DateTime.now();
}
