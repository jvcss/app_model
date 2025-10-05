// lib/providers/password_reset_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/password_reset_repository.dart';

// Provider principal
final passwordResetProvider = AsyncNotifierProvider<PasswordResetNotifier, PasswordResetState>(
  PasswordResetNotifier.new,
);

// Estados do fluxo
enum PasswordResetStep {
  email,        // Inserindo email
  verification, // Inserindo OTP/TOTP
  newPassword,  // Definindo nova senha
  success,      // Concluído
}

// Estado principal
class PasswordResetState {
  final PasswordResetStep currentStep;
  final String? email;
  final String? resetToken;
  final bool requiresTotp;
  final String? message;
  final int remainingTime; // segundos restantes para OTP

  PasswordResetState({
    this.currentStep = PasswordResetStep.email,
    this.email,
    this.resetToken,
    this.requiresTotp = false,
    this.message,
    this.remainingTime = 0,
  });

  PasswordResetState copyWith({
    PasswordResetStep? currentStep,
    String? email,
    String? resetToken,
    bool? requiresTotp,
    String? message,
    int? remainingTime,
  }) {
    return PasswordResetState(
      currentStep: currentStep ?? this.currentStep,
      email: email ?? this.email,
      resetToken: resetToken ?? this.resetToken,
      requiresTotp: requiresTotp ?? this.requiresTotp,
      message: message ?? this.message,
      remainingTime: remainingTime ?? this.remainingTime,
    );
  }
}

// Notifier
class PasswordResetNotifier extends AsyncNotifier<PasswordResetState> {
  Timer? _countdownTimer;
  final _repository = PasswordResetRepository();

  @override
  FutureOr<PasswordResetState> build() {
    ref.onDispose(() {
      _countdownTimer?.cancel();
    });
    return PasswordResetState();
  }

  // Etapa 1: Solicitar recuperação de senha
  Future<void> requestPasswordReset(String email) async {
    state = const AsyncLoading();
    
    try {
      final message = await _repository.startPasswordReset(email);
      
      // Inicia contagem regressiva de 10 minutos
      _startCountdown(600);
      
      state = AsyncData(
        PasswordResetState(
          currentStep: PasswordResetStep.verification,
          email: email,
          message: message,
          remainingTime: 600,
        ),
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  // Etapa 2: Verificar OTP e TOTP (se necessário)
  Future<void> verifyOtp({
    required String otp,
    String? totp,
  }) async {
    final currentState = state.value;
    if (currentState == null || currentState.email == null) {
      state = AsyncError('Estado inválido', StackTrace.current);
      return;
    }

    state = const AsyncLoading();
    
    try {
      final resetToken = await _repository.verifyPasswordReset(
        email: currentState.email!,
        otp: otp,
        totp: totp,
      );
      
      _countdownTimer?.cancel();
      
      state = AsyncData(
        currentState.copyWith(
          currentStep: PasswordResetStep.newPassword,
          resetToken: resetToken,
          remainingTime: 0,
        ),
      );
    } catch (e) {
      // Restaura o estado anterior em caso de erro
      state = AsyncError(e, StackTrace.current);
      // Permite nova tentativa mantendo o estado
      await Future.delayed(const Duration(seconds: 2));
      state = AsyncData(currentState);
    }
  }

  // Etapa 3: Definir nova senha
  Future<void> setNewPassword(String password) async {
    final currentState = state.value;
    if (currentState == null || currentState.resetToken == null) {
      state = AsyncError('Token inválido', StackTrace.current);
      return;
    }

    state = const AsyncLoading();
    
    try {
      await _repository.confirmPasswordReset(
        resetToken: currentState.resetToken!,
        newPassword: password,
      );
      
      state = AsyncData(
        currentState.copyWith(
          currentStep: PasswordResetStep.success,
          message: 'Senha redefinida com sucesso!',
        ),
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  // Reiniciar todo o processo
  void reset() {
    _countdownTimer?.cancel();
    state = AsyncData(PasswordResetState());
  }

  // Voltar para etapa anterior
  void goBack() {
    final currentState = state.value;
    if (currentState == null) return;

    switch (currentState.currentStep) {
      case PasswordResetStep.verification:
        _countdownTimer?.cancel();
        state = AsyncData(PasswordResetState());
        break;
      case PasswordResetStep.newPassword:
        state = AsyncData(
          currentState.copyWith(
            currentStep: PasswordResetStep.verification,
            resetToken: null,
          ),
        );
        _startCountdown(currentState.remainingTime > 0 ? currentState.remainingTime : 600);
        break;
      default:
        break;
    }
  }

  // Controle do timer de contagem regressiva
  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    
    var remaining = seconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      
      final currentState = state.value;
      if (currentState != null && remaining > 0) {
        state = AsyncData(currentState.copyWith(remainingTime: remaining));
      } else {
        timer.cancel();
        if (currentState != null) {
          state = AsyncData(currentState.copyWith(remainingTime: 0));
        }
      }
    });
  }

  // Reenviar OTP
  Future<void> resendOtp() async {
    final currentState = state.value;
    if (currentState == null || currentState.email == null) return;
    
    if (currentState.remainingTime > 540) { // Permite reenvio após 1 minuto
      throw Exception('Aguarde ${currentState.remainingTime - 540} segundos para reenviar');
    }

    await requestPasswordReset(currentState.email!);
  }
}

// Provider para validação de senha
final passwordValidationProvider = Provider<PasswordValidator>((ref) {
  return PasswordValidator();
});

class PasswordValidator {
  static const int minLength = 8;
  static const int maxLength = 128;

  Map<String, bool> validate(String password) {
    return {
      'minLength': password.length >= minLength,
      'hasUppercase': password.contains(RegExp(r'[A-Z]')),
      'hasLowercase': password.contains(RegExp(r'[a-z]')),
      'hasNumber': password.contains(RegExp(r'[0-9]')),
      'hasSpecial': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    };
  }

  bool isValid(String password) {
    final validation = validate(password);
    return validation.values.where((v) => v).length >= 4; // Pelo menos 4 critérios
  }

  double strength(String password) {
    final validation = validate(password);
    final metCriteria = validation.values.where((v) => v).length;
    return metCriteria / validation.length;
  }
}