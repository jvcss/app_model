import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import 'api_interceptor.dart';

class ApiService {
  static const baseUrl = kDebugMode
      // ignore: unnecessary_const
      ? const String.fromEnvironment(
          'BACKEND_URL',
          defaultValue: 'https://dev.jvcss.com.br/api',
        )
      : 
      // ignore: unnecessary_const
      const String.fromEnvironment(
          'BACKEND_URL_PROD',
          defaultValue: 'https://api.jvcss.com.br/api',
        );

  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Cliente HTTP com interceptor
  static final _client = ApiInterceptor(http.Client());

  static void clearToken() {
    _headers.remove('Authorization');
  }

  static Future<ApiResponse> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    
    try {
      final response = await _client.get(url, headers: _headers);
      return _processResponse(response);
    } catch (e) {
      debugPrint('❌ GET Error: $e');
      rethrow;
    }
  }

  static Future<ApiResponse> post(String endpoint, dynamic data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final body = json.encode(data);

    try {
      final response = await _client.post(
        url,
        headers: _headers,
        body: body,
      );

      // Se a resposta não for 2xx, lança erro com contexto
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final requestId = response.headers['x-request-id'] ?? 'unknown';
        
        debugPrint('❌ POST Error: ${response.statusCode} - ${response.body}');
        debugPrint('   Request-ID: $requestId');
        
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Failed to POST data',
          requestId: requestId,
          body: response.body,
        );
      }

      return _processResponse(response);
    } catch (e) {
      debugPrint('❌ POST Exception: $e');
      rethrow;
    }
  }

  static ApiResponse _processResponse(http.Response response) {
    dynamic parsedData;
    try {
      parsedData = json.decode(response.body);
    } catch (_) {
      parsedData = response.body;
    }

    return ApiResponse(
      statusCode: response.statusCode,
      data: parsedData,
      headers: response.headers,
    );
  }

  static void setToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }

  static String? get token {
    return _headers['Authorization']?.replaceFirst('Bearer ', '');
  }
}

/// Exception customizada com contexto de logging
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String requestId;
  final String? body;

  ApiException({
    required this.statusCode,
    required this.message,
    required this.requestId,
    this.body,
  });

  @override
  String toString() {
    return 'ApiException($statusCode): $message [Request-ID: $requestId]';
  }
}