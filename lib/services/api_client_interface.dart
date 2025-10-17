import '../models/api_response.dart';

/// Interface abstrata para clientes HTTP
abstract class ApiClient {
  Future<ApiResponse> get(String endpoint, Map<String, String> headers);
  Future<ApiResponse> post(String endpoint, Map<String, String> headers, dynamic data);
}