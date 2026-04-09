import 'dart:developer' as developer;

/// A centralized logger service to decouple the application from specific logging implementations
/// (like `debugPrint` or external packages).
class LoggerService {
  const LoggerService._();

  /// Log a debug message.
  static void d(String message, [Object? error, StackTrace? stackTrace]) {
    _log('DEBUG', message, error, stackTrace);
  }

  /// Log an info message.
  static void i(String message, [Object? error, StackTrace? stackTrace]) {
    _log('INFO', message, error, stackTrace);
  }

  /// Log an error message.
  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    _log('ERROR', message, error, stackTrace);
  }

  static void _log(String level, String message,
      [Object? error, StackTrace? stackTrace,]) {
    // Use dart:developer log for better console integration in IDEs
    developer.log(
      message,
      name: 'Secretaire.$level',
      time: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
  }
}
