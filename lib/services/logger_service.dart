import 'package:logging/logging.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class LoggerService {
  static final Logger _logger = Logger('RutasAndinas');
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // En desarrollo, usamos dart:developer para logging
      if (record.level >= Level.SEVERE) {
        developer.log(
          '${record.level.name}: ${record.time}: ${record.message}',
          time: record.time,
          level: record.level.value,
          name: record.loggerName,
          error: record.error,
          stackTrace: record.stackTrace,
        );
      }
    });
    
    _initialized = true;
    info('LoggerService inicializado');
  }

  static void info(String message) {
    if (kDebugMode) print('📘 INFO: $message');
  }

  static void warning(String message) {
    if (kDebugMode) print('📙 WARNING: $message');
  }

  static void error(String message, [dynamic e]) {
    if (kDebugMode) {
      print('📕 ERROR: $message');
      if (e != null) print('📕 EXCEPTION: $e');
    }
  }

  static void debug(String message) {
    if (kDebugMode) print('📓 DEBUG: $message');
  }

  static void _ensureInitialized() {
    if (!_initialized) init();
  }
} 