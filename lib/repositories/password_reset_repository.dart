// lib/repositories/password_reset_repository.dart
import '../services/api_service.dart';

class PasswordResetRepository {
  PasswordResetRepository();

  /// Inicia o processo de recuperação enviando OTP por email
  Future<String> startPasswordReset(String email) async {
    final response = await ApiService.post('/auth/forgot-password/start', {
      'email': email,
    });
    
    if (response.statusCode != 202) {
      throw Exception(response.data['detail'] ?? 'Erro ao solicitar recuperação');
    }
    
    return response.data['message'] ?? 'Se o email existe, um código foi enviado.';
  }

  /// Verifica OTP e TOTP (se necessário) e retorna token de sessão
  Future<String> verifyPasswordReset({
    required String email,
    required String otp,
    String? totp,
  }) async {
    final payload = {
      'email': email,
      'otp': otp,
    };
    
    if (totp != null && totp.isNotEmpty) {
      payload['totp'] = totp;
    }
    
    final response = await ApiService.post('/auth/forgot-password/verify', payload);
    
    if (response.statusCode == 429) {
      throw Exception('Muitas tentativas. Aguarde alguns minutos.');
    }
    
    if (response.statusCode != 200) {
      throw Exception(response.data['detail'] ?? 'Código inválido ou expirado');
    }
    
    final token = response.data['reset_session_token'];
    if (token == null) {
      throw Exception('Erro ao obter token de recuperação');
    }
    
    return token;
  }

  /// Confirma a nova senha usando o token de sessão
  Future<void> confirmPasswordReset({
    required String resetToken,
    required String newPassword,
  }) async {
    // Temporariamente configura o token para esta requisição
    final originalToken = ApiService.token;
    ApiService.setToken(resetToken);
    
    try {
      final response = await ApiService.post('/auth/forgot-password/confirm', {
        'new_password': newPassword,
      });
      
      if (response.statusCode != 204) {
        throw Exception(response.data['detail'] ?? 'Erro ao redefinir senha');
      }
    } finally {
      // Restaura o token original (se houver)
      if (originalToken != null) {
        ApiService.setToken(originalToken);
      } else {
        ApiService.clearToken();
      }
    }
  }

  /// Configura 2FA para o usuário (requer autenticação)
  Future<Map<String, String>> setup2FA() async {
    final response = await ApiService.post('/auth/2fa/setup', {});
    
    if (response.statusCode != 200) {
      throw Exception(response.data['detail'] ?? 'Erro ao configurar 2FA');
    }
    
    return {
      'secret': response.data['secret'],
      'otpauth_url': response.data['otpauth_url'],
    };
  }

  /// Verifica código TOTP para ativar 2FA
  Future<void> verify2FA(String code) async {
    final response = await ApiService.post('/auth/2fa/verify', {
      'code': code,
    });
    
    if (response.statusCode != 204) {
      throw Exception(response.data['detail'] ?? 'Código inválido');
    }
  }
}