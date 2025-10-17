import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../models/api_response.dart';
import 'api_client_interface.dart';

/// Cliente HTTP nativo usando dart:io HttpClient
/// Otimizado para Android (reutiliza conexões TCP automaticamente)
class DartHttpClientImpl implements ApiClient {
  static final HttpClient _client = HttpClient();

  @override
  Future<ApiResponse> get(String endpoint, Map<String, String> headers) async {
    try {
      final uri = Uri.parse(endpoint);
      HttpClientRequest request = await _client.getUrl(uri);

      headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      HttpClientResponse response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      dynamic data;
      try {
        data = json.decode(responseBody);
      } catch (_) {
        data = responseBody;
      }

      Map<String, String> responseHeaders = {};
      response.headers.forEach((name, values) {
        responseHeaders[name] = values.join(',');
      });

      if (kDebugMode) {
        print('✅ [dart:io] GET ${response.statusCode} - $endpoint');
      }

      return ApiResponse(
        statusCode: response.statusCode,
        data: data,
        headers: responseHeaders,
      );
    } catch (e) {
      if (kDebugMode) print('❌ [dart:io] GET Error: $e');
      rethrow;
    }
  }

  @override
  Future<ApiResponse> post(String endpoint, Map<String, String> headers, dynamic data) async {
    try {
      final uri = Uri.parse(endpoint);
      HttpClientRequest request = await _client.postUrl(uri);

      headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      if (data is Map || data is List) {
        request.add(utf8.encode(json.encode(data)));
      } else if (data is String) {
        request.add(utf8.encode(data));
      } else {
        throw Exception('Tipo de dado não suportado');
      }

      HttpClientResponse response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final status = response.statusCode;

      if (status < 200 || status >= 300) {
        if (kDebugMode) print('❌ [dart:io] POST $status: $responseBody');
        throw Exception('HTTP $status: $responseBody');
      }

      dynamic parsedData;
      try {
        parsedData = json.decode(responseBody);
      } catch (_) {
        parsedData = responseBody;
      }

      Map<String, String> responseHeaders = {};
      response.headers.forEach((name, values) {
        responseHeaders[name] = values.join(',');
      });

      if (kDebugMode) {
        print('✅ [dart:io] POST $status - $endpoint');
      }

      return ApiResponse(
        statusCode: response.statusCode,
        data: parsedData,
        headers: responseHeaders,
      );
    } catch (e) {
      if (kDebugMode) print('❌ [dart:io] POST Error: $e');
      rethrow;
    }
  }
}