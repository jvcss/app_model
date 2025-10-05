import '../models/api_response.dart';
import '../services/api_service.dart';

class AuthRepository {
  AuthRepository();

  Future<String> login(String email, String password) async {
    try {
      ApiResponse response = await ApiService.post('/auth/login', {
        'email': email,
        'password': password,
      });
      final token = response.data['access_token'];
      if (token != null) {
        ApiService.setToken(token);
      }
      return token;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> register(String email, String password) async {
    final response = await ApiService.post('/auth/register', {
      'name': email
          .split('@')[0]
          .substring(
            0,
            13,
          ), // Assuming name is derived from email firsts 10 characters
      'email': email,
      'password': password,
    });
    final trueEmail = response.data['email'];
    final loginResponse = await ApiService.post('/auth/login', {
      'email': trueEmail,
      'password': password,
    });
    final token = loginResponse
        .data['access_token']; // Assuming the token is returned in the response
    if (token != null) {
      ApiService.setToken(token);
    }
    return token;
  }

  Future<void> logout() async {
    await ApiService.post('/auth/logout', {});
    ApiService.clearToken();
  }

  Future<dynamic> getProfile() async {
    final response = await ApiService.get('/auth/me');
    return response.data;
  }
}
