import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../models/api_response.dart';
import 'api_client_interface.dart';
import 'api_interceptor.dart';

/// Cliente HTTP usando package:http com ApiInterceptor
/// Adiciona rastreamento end-to-end (x-request-id) e logs estruturados
class PackageHttpClientImpl implements ApiClient {
  static final http.Client _client = ApiInterceptor(http.Client());

  @override
  Future<ApiResponse> get(String endpoint, Map<String, String> headers) async {
    final url = Uri.parse(endpoint);
    
    try {
      final response = await _client.get(url, headers: headers);
      return _processResponse(response);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [package:http] GET Error: $e');
      rethrow;
    }
  }

  @override
  Future<ApiResponse> post(String endpoint, Map<String, String> headers, dynamic data) async {
    final url = Uri.parse(endpoint);
    final body = json.encode(data);

    try {
      final response = await _client.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final requestId = response.headers['x-request-id'] ?? 'unknown';
        
        if (kDebugMode) {
          debugPrint('❌ [package:http] POST ${response.statusCode} - ${response.body}');
          debugPrint('   Request-ID: $requestId');
        }
        
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Failed to POST data',
          requestId: requestId,
          body: response.body,
        );
      }

      return _processResponse(response);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [package:http] POST Exception: $e');
      rethrow;
    }
  }

  ApiResponse _processResponse(http.Response response) {
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