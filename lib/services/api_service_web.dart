import 'dart:convert';
// ignore: unused_shown_name
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import 'package:http/http.dart' as http;
import '../models/api_response.dart';

class ApiService {
  static const baseUrl = kDebugMode
      ? 'http://localhost:8000/api'
      : 'https://apisindicancia.growthsolutions.com.br/api';

  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  static void clearToken() {
    _headers.remove('Authorization');
  }

  static Future<ApiResponse> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.get(url, headers: _headers);
    dynamic data;

    try {
      data = json.decode(response.body);
    } catch (_) {
      data = response.body;
    }

    return ApiResponse(
      statusCode: response.statusCode,
      data: data,
      headers: response.headers,
    );
  }

  static Future<ApiResponse> post(String endpoint, dynamic data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final body = json.encode(data);

    final response = await http.post(url, headers: _headers, body: body);

    // if the response is not 2xx, throw an error
    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('POST Error: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to POST data: ${response.statusCode}');
    }

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
  /// get token
  static String? get token {
    return _headers['Authorization']?.replaceFirst('Bearer ', '');
  }
}
