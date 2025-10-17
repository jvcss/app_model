// export 'api_service_io.dart'
//     if (dart.library.io) 'api_service_io.dart'
//     if (dart.library.html) 'api_service_web.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kDebugMode;
import '../models/api_response.dart';
import 'api_client_interface.dart';
import 'http_client_impl.dart';
import 'package_http_impl.dart';

/// Serviço de API com seleção automática de cliente HTTP
/// - Android: usa dart:io HttpClient (otimizado)
/// - iOS/Web: usa package:http com ApiInterceptor (rastreamento)
class ApiService {
  static const baseUrl = kDebugMode
      ? String.fromEnvironment(
          'BACKEND_URL',
          defaultValue: 'https://dev.jvcss.com.br/api',
        )
      : String.fromEnvironment(
          'BACKEND_URL_PROD',
          defaultValue: 'https://api.jvcss.com.br/api',
        );

  /// Cliente HTTP selecionado automaticamente
  static final ApiClient _client = _createClient();
  
  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Factory que escolhe dart:io para Android e package:http para iOS/Web
  static ApiClient _createClient() {
    if (kDebugMode) {
      print('🔧 Initializing HTTP Client for: ${Platform.operatingSystem}');
    }
    
    if (Platform.isAndroid) {
      if (kDebugMode) print('   → Using dart:io HttpClient (Android)');
      return DartHttpClientImpl();
    } else {
      if (kDebugMode) print('   → Using package:http with ApiInterceptor (iOS/Web)');
      return PackageHttpClientImpl();
    }
  }

  static void clearToken() {
    _headers.remove('Authorization');
  }

  /// GET request (usa automaticamente o cliente correto)
  static Future<ApiResponse> get(String endpoint) async {
    final fullUrl = '$baseUrl$endpoint';
    return _client.get(fullUrl, _headers);
  }

  /// POST request (usa automaticamente o cliente correto)
  static Future<ApiResponse> post(String endpoint, dynamic data) async {
    final fullUrl = '$baseUrl$endpoint';
    return _client.post(fullUrl, _headers, data);
  }

  static void setToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }

  static String? get token {
    return _headers['Authorization']?.replaceFirst('Bearer ', '');
  }
}

