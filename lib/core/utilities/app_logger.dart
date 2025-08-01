import 'dart:convert';
import 'dart:developer';
import 'package:logging/logging.dart';

class AppLogger {
  final String identifier;
  final Logger _logger;

  static bool _isLoggingInitialized = false;

  AppLogger({
    required this.identifier,
  }) : _logger = Logger(identifier) {
    if (!_isLoggingInitialized) {
      _initializeLogging();
      _isLoggingInitialized = true;
    }
  }

  static void _initializeLogging() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      final timestamp = record.time.toIso8601String();
      final level = record.level.name;
      final source = record.loggerName;
      final msg = record.message;
      final error = record.error;
      final stack = record.stackTrace;

      final buffer = StringBuffer('[$level] $timestamp [$source]');
      buffer.write(': $msg');
      if (error != null) buffer.write('\nError: $error');
      if (stack != null) buffer.write('\nStackTrace:\n$stack');

      log(buffer.toString());
    });
  }

  void all(String message) => _logger.log(Level.ALL, message);
  void d(String message) => _logger.fine(message);
  void i(String message) => _logger.info(message);
  void w(String message) => _logger.warning(message);
  void f(String message) => _logger.shout(message);

  void e(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.severe(message, error, stackTrace);
  }

  void json(dynamic jsonObject, {Level level = Level.INFO}) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      final pretty = encoder.convert(jsonObject);
      _logger.log(level, 'JSON:\n$pretty');
    } catch (err, stack) {
      _logger.severe('Failed to pretty-print JSON', err, stack);
    }
  }
}
