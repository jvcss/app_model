import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/auth_repository.dart';
import 'notifications_provider.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

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
    return AuthState.unauthenticated();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final authRepository = AuthRepository();

      final token = await authRepository.login(
        kDebugMode ? "jvcs.mecatronica@gmail.com" : email,
        kDebugMode ? "jvcs.mecatronica@gmail.com" : password,
      );
      state = AsyncData(AuthState(isAuthenticated: true, token: token));
    } catch (e, st) {
      ref
          .read(notificationsProvider.notifier)
          .error(
            'Erro de Validação',
            'Por favor, verifique os campos de email e senha.',
          );
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    state = AsyncData(AuthState.unauthenticated());
    // limpar o token do repositório, se necessário
    final authRepository = AuthRepository();
    await authRepository.logout();
  }

  Future<void> register(
    String email,
    String password,
    String releaseKey,
  ) async {
    state = const AsyncLoading();
    try {
      if (releaseKey != 'jvcs.mecatronica@gmail.com') {
        return;
      }
      final authRepository = AuthRepository();
      final token = await authRepository.register(email, password);
      state = AsyncData(AuthState(isAuthenticated: true, token: token));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
