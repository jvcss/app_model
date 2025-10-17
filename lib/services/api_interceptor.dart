import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

/// Interceptor customizado para adicionar headers de rastreamento
class ApiInterceptor extends http.BaseClient {
  final http.Client _inner;
  static const _uuid = Uuid();

  ApiInterceptor(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Gera request_id único para rastreamento end-to-end
    final requestId = _uuid.v4();
    request.headers['x-request-id'] = requestId;
    
    // Adiciona timestamp
    request.headers['x-client-timestamp'] = DateTime.now().toIso8601String();
    
    // User agent customizado
    request.headers['user-agent'] = 'Flutter-App/1.0.0';
    
    // Log de saída (opcional em dev)
    _logRequest(request, requestId);
    
    final startTime = DateTime.now();
    
    try {
      final response = await _inner.send(request);
      
      final duration = DateTime.now().difference(startTime);
      _logResponse(response, requestId, duration);
      
      return response;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      _logError(request, requestId, duration, e);
      rethrow;
    }
  }

  void _logRequest(http.BaseRequest request, String requestId) {
    debugPrint('🚀 [REQUEST] ${request.method} ${request.url}');
    debugPrint('   Request-ID: $requestId');
  }

  void _logResponse(
    http.StreamedResponse response,
    String requestId,
    Duration duration,
  ) {
    final emoji = response.statusCode < 400 ? '✅' : '❌';
    debugPrint('$emoji [RESPONSE] ${response.statusCode} - ${duration.inMilliseconds}ms');
    debugPrint('   Request-ID: $requestId');
    
    // Extrai process time do backend
    final processTime = response.headers['x-process-time'];
    if (processTime != null) {
      debugPrint('   Backend Time: ${processTime}ms');
    }
  }

  void _logError(
    http.BaseRequest request,
    String requestId,
    Duration duration,
    Object error,
  ) {
    debugPrint('💥 [ERROR] ${request.method} ${request.url}');
    debugPrint('   Request-ID: $requestId');
    debugPrint('   Duration: ${duration.inMilliseconds}ms');
    debugPrint('   Error: $error');
  }
}