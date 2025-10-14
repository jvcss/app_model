import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/auth_repository.dart';
import '../services/app_logger.dart';
import 'notifications_provider.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// Logger específico para autenticação
final _logger = AppLogger.create('auth');

class AuthState {
  final bool isAuthenticated;
  final String? token;

  AuthState({required this.isAuthenticated, this.token});

  factory AuthState.unauthenticated() => AuthState(isAuthenticated: false);

  AuthState copyWith({bool? isAuthenticated, String? token}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  FutureOr<AuthState> build() {
    _logger.info('AuthNotifier initialized');
    return AuthState.unauthenticated();
  }

  Future<void> login(String email, String password) async {
    final tracker = _logger.trackPerformance('user_login', extra: {
      'email': email,
    });

    state = const AsyncLoading();
    
    try {
      _logger.info('Login attempt', extra: {'email': email});
      
      final authRepository = AuthRepository();
      final token = await authRepository.login(
        kDebugMode ? const String.fromEnvironment("EMAIL_DEBUG") : email,
        kDebugMode ? const String.fromEnvironment("PASSWORD_DEBUG") : password,
      );
      
      state = AsyncData(AuthState(isAuthenticated: true, token: token));
      
      _logger.info('Login successful', extra: {
        'email': email,
        'token_length': token.length,
      });
      
      tracker.complete(message: 'Login completed successfully');
      
    } catch (e, st) {
      _logger.error(
        'Login failed',
        error: e,
        stackTrace: st,
        extra: {'email': email},
      );
      
      tracker.fail(e, st);
      
      ref.read(notificationsProvider.notifier).error(
        'Erro de Login',
        'Não foi possível realizar o login. Verifique suas credenciais.',
      );
      
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    final tracker = _logger.trackPerformance('user_logout');
    
    try {
      _logger.info('Logout initiated');
      
      state = AsyncData(AuthState.unauthenticated());
      
      final authRepository = AuthRepository();
      await authRepository.logout();
      
      _logger.info('Logout completed');
      tracker.complete();
      
    } catch (e, st) {
      _logger.error('Logout failed', error: e, stackTrace: st);
      tracker.fail(e, st);
    }
  }

  Future<void> register(String email, String password, String releaseKey) async {
    final tracker = _logger.trackPerformance('user_registration', extra: {
      'email': email,
    });

    state = const AsyncLoading();
    
    try {
      if (releaseKey !=  const String.fromEnvironment("RELEASE_KEY")) {
        _logger.warning('Registration failed: Invalid release key', extra: {
          'email': email,
        });
        
        tracker.fail(Exception('Invalid release key'));
        return;
      }
      
      _logger.info('Registration attempt', extra: {'email': email});
      
      final authRepository = AuthRepository();
      final token = await authRepository.register(email, password);
      
      state = AsyncData(AuthState(isAuthenticated: true, token: token));
      
      _logger.info('Registration successful', extra: {'email': email});
      tracker.complete(message: 'Registration completed successfully');
      
    } catch (e, st) {
      _logger.error(
        'Registration failed',
        error: e,
        stackTrace: st,
        extra: {'email': email},
      );
      
      tracker.fail(e, st);
      state = AsyncError(e, st);
    }
  }
}