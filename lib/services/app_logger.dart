import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Sistema centralizado de logging para Flutter
/// 
/// Features:
/// - Logs estruturados
/// - Níveis de severidade
/// - Context enrichment
/// - Performance tracking
/// - Integration com crash reporting (Firebase, Sentry)
class AppLogger {
  final String name;
  
  AppLogger(this.name);

  /// Factory para criar loggers
  factory AppLogger.create(String name) => AppLogger(name);

  // Níveis de log
  void debug(String message, {Map<String, dynamic>? extra}) {
    _log('DEBUG', message, extra: extra);
  }

  void info(String message, {Map<String, dynamic>? extra}) {
    _log('INFO', message, extra: extra);
  }

  void warning(String message, {Map<String, dynamic>? extra}) {
    _log('WARNING', message, extra: extra);
  }

  void error(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? extra}) {
    _log('ERROR', message, error: error, stackTrace: stackTrace, extra: extra);
  }

  void critical(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? extra}) {
    _log('CRITICAL', message, error: error, stackTrace: stackTrace, extra: extra);
  }

  void _log(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    final logData = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': level,
      'logger': name,
      'message': message,
      'platform': 'flutter',
      if (extra != null) 'extra': extra,
    };

    if (error != null) {
      logData['error'] = {
        'type': error.runtimeType.toString(),
        'message': error.toString(),
      };
    }

    if (stackTrace != null) {
      logData['stackTrace'] = stackTrace.toString().split('\n').take(10).toList();
    }

    // Em desenvolvimento: log legível
    if (kDebugMode) {
      final emoji = _getEmoji(level);
      debugPrint('$emoji [$level] $name: $message');
      if (extra != null) {
        debugPrint('   Extra: $extra');
      }
      if (error != null) {
        debugPrint('   Error: $error');
      }
    } 
    // Em produção: JSON estruturado
    else {
      developer.log(
        json.encode(logData),
        name: name,
        level: _getLogLevel(level),
      );
    }

    // TODO: Enviar para backend/crash reporting em produção
    // if (kReleaseMode && level == 'ERROR' || level == 'CRITICAL') {
    //   _sendToBackend(logData);
    // }
  }

  String _getEmoji(String level) {
    switch (level) {
      case 'DEBUG':
        return '🐛';
      case 'INFO':
        return 'ℹ️';
      case 'WARNING':
        return '⚠️';
      case 'ERROR':
        return '❌';
      case 'CRITICAL':
        return '🔥';
      default:
        return '📝';
    }
  }

  int _getLogLevel(String level) {
    switch (level) {
      case 'DEBUG':
        return 500;
      case 'INFO':
        return 800;
      case 'WARNING':
        return 900;
      case 'ERROR':
        return 1000;
      case 'CRITICAL':
        return 1200;
      default:
        return 800;
    }
  }

  // Future<void> _sendToBackend(Map<String, dynamic> logData) async {
  //   // Implementar envio para backend ou serviço de crash reporting
  //   // Exemplo: Firebase Crashlytics, Sentry, etc.
  // }
}

class PerformanceTracker {
  final String operation;
  final AppLogger _logger;
  final DateTime _startTime;
  final Map<String, dynamic>? _extra;

  PerformanceTracker(this.operation, this._logger, {Map<String, dynamic>? extra})
      : _startTime = DateTime.now(),
        _extra = extra;

  void complete({String? message}) {
    final duration = DateTime.now().difference(_startTime);
    final durationMs = duration.inMilliseconds;

    final emoji = durationMs < 100 ? '⚡' : durationMs < 500 ? '🚀' : '🐌';
    
    _logger.info(
      message ?? 'Operation $emoji: $operation',
      extra: {
        'operation': operation,
        'duration_ms': durationMs,
        if (_extra != null) ..._extra,
      },
    );

    if (durationMs > 1000) {
      _logger.warning(
        'Slow operation detected: $operation',
        extra: {
          'operation': operation,
          'duration_ms': durationMs,
          'threshold_ms': 1000,
        },
      );
    }
  }

  void fail(Object error, [StackTrace? stackTrace]) {
    final duration = DateTime.now().difference(_startTime);
    
    _logger.error(
      'Operation failed: $operation',
      error: error,
      stackTrace: stackTrace,
      extra: {
        'operation': operation,
        'duration_ms': duration.inMilliseconds,
        if (_extra != null) ..._extra,
      },
    );
  }
}

extension LoggerExtensions on AppLogger {
  PerformanceTracker trackPerformance(String operation, {Map<String, dynamic>? extra}) {
    return PerformanceTracker(operation, this, extra: extra);
  }
}

final appLogger = AppLogger.create('app');
