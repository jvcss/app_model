import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import '../models/api_response.dart';

/// Serviço de API sem biblioteca externa (Dio)
class ApiService {
  static final String baseUrl = kDebugMode
      ? 'http://localhost:8000/api'
      : 'https://apisindicancia.growthsolutions.com.br/api';

  static final HttpClient _client = HttpClient();

  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  ApiService() {
    // code
    // Opcional: Configurar timeout na conexão, se necessário.
    // _client.connectionTimeout = const Duration(seconds: 5);
  }

  static void clearToken() {
    _headers.remove('Authorization');
  }

  /// Executa uma requisição GET para o endpoint informado.
  static Future<ApiResponse> get(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      HttpClientRequest request = await _client.getUrl(uri);

      // Adiciona cabeçalhos à requisição.
      _headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      // Envia a requisição e aguarda a resposta.
      HttpClientResponse response = await request.close();

      // Lê a resposta (como String).
      final responseBody = await response.transform(utf8.decoder).join();

      // Log da resposta para depuração.
      //debugPrint('GET: $uri -> ${response.statusCode}');
      //debugPrint('Response Body: $responseBody');

      // Tenta decodificar o JSON; caso não seja possível, retorna o corpo cru.
      dynamic data;
      try {
        data = json.decode(responseBody);
      } catch (_) {
        data = responseBody;
      }

      // Converte os cabeçalhos da resposta para um Map<String, String>.
      Map<String, String> responseHeaders = {};
      response.headers.forEach((name, values) {
        responseHeaders[name] = values.join(',');
      });

      return ApiResponse(
        statusCode: response.statusCode,
        data: data,
        headers: responseHeaders,
      );
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }

  /// Executa uma requisição POST para o endpoint informado com os dados fornecidos.
  static Future<ApiResponse> post(String endpoint, dynamic data) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      HttpClientRequest request = await _client.postUrl(uri);

      // Adiciona os cabeçalhos configurados.
      _headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      // Trata os dados a serem enviados: se for Map ou List, converte para JSON.
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

      return ApiResponse(
        statusCode: response.statusCode,
        data: parsedData,
        headers: responseHeaders,
      );
    } catch (e) {
      throw Exception('Failed to post data: $e');
    }
  }

  /// Define o token de autorização para as próximas requisições.
  static void setToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }

  /// get token
  static String? get token {
    return _headers['Authorization']?.replaceFirst('Bearer ', '');
  }
}
