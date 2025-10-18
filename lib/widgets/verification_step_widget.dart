// lib/view/forgot_password/widgets/verification_step_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../../providers/password_reset_provider.dart';
import '../../../providers/notifications_provider.dart';
import '../services/app_translations.dart';

class VerificationStepWidget extends ConsumerStatefulWidget {
  const VerificationStepWidget({super.key});

  @override
  ConsumerState<VerificationStepWidget> createState() => _VerificationStepWidgetState();
}

class _VerificationStepWidgetState extends ConsumerState<VerificationStepWidget> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _totpController = TextEditingController();
  
  bool _isSubmitting = false;
  bool _showTotpField = false;
  bool _canResend = false;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _setupOtpListeners();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _totpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _setupOtpListeners() {
    for (int i = 0; i < _otpControllers.length; i++) {
      _otpControllers[i].addListener(() {
        final text = _otpControllers[i].text;
        
        // Auto-avança para o próximo campo
        if (text.length == 1 && i < _otpControllers.length - 1) {
          _otpFocusNodes[i + 1].requestFocus();
        }
        
        // Se colou um código completo
        if (text.length >= 6) {
          final code = text.substring(0, 6);
          for (int j = 0; j < 6; j++) {
            _otpControllers[j].text = code[j];
          }
          _otpFocusNodes[5].requestFocus();
        }
      });
    }
  }

  void _startResendTimer() {
    _resendTimer = Timer(const Duration(seconds: 60), () {
      if (mounted) {
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  String _getOtpValue() {
    return _otpControllers.map((c) => c.text).join();
  }

  bool _validateOtp() {
    final otp = _getOtpValue();
    return otp.length == 6 && RegExp(r'^\d+$').hasMatch(otp);
  }

  Future<void> _handleSubmit() async {
    if (!_validateOtp()) {
      ref.read(notificationsProvider.notifier).error(
        'Código inválido',
        'Digite os 6 dígitos do código',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(passwordResetProvider.notifier).verifyOtp(
        otp: _getOtpValue(),
        totp: _showTotpField ? _totpController.text : null,
      );
      
      ref.read(notificationsProvider.notifier).success(
        'Verificação concluída',
        'Agora defina sua nova senha',
      );
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      
      // Se o erro indicar necessidade de TOTP
      if (errorMessage.contains('authenticator') || errorMessage.contains('totp')) {
        setState(() {
          _showTotpField = true;
        });
        ref.read(notificationsProvider.notifier).warning(
          'Autenticação adicional',
          'Digite o código do seu aplicativo autenticador',
        );
      } else {
        ref.read(notificationsProvider.notifier).error(
          'Erro na verificação',
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;
    
    setState(() {
      _canResend = false;
    });
    
    try {
      await ref.read(passwordResetProvider.notifier).resendOtp();
      
      ref.read(notificationsProvider.notifier).success(
        'Código reenviado',
        'Verifique seu email novamente',
      );
      
      // Limpa os campos
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _totpController.clear();
      _otpFocusNodes[0].requestFocus();
      
      // Reinicia o timer
      _startResendTimer();
    } catch (e) {
      ref.read(notificationsProvider.notifier).error(
        'Erro ao reenviar',
        e.toString().replaceAll('Exception: ', ''),
      );
      setState(() {
        _canResend = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resetState = ref.watch(passwordResetProvider);
    final remainingTime = resetState.value?.remainingTime ?? 0;
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email que recebeu o código
          if (resetState.value?.email != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(76),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.email,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      resetState.value!.email!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Instrução
          Text(
            'enter_verification_code'.tr,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          
          // Campos OTP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 45,
                child: TextFormField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  enabled: !_isSubmitting,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    if (value.isEmpty && index > 0) {
                      // Volta para o campo anterior ao apagar
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                  },
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(76),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withAlpha(127),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ),
          
          // Campo TOTP (se necessário)
          if (_showTotpField) ...[
            const SizedBox(height: 24),
            TextFormField(
              controller: _totpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              enabled: !_isSubmitting,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'authenticator_code'.tr,
                hintText: '000000',
                prefixIcon: const Icon(Icons.security),
                counterText: '',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(76),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          
          // Tempo restante
          if (remainingTime > 0) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Código expira em ${_formatTime(remainingTime)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: remainingTime < 60
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Botão verificar
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _handleSubmit,
              icon: _isSubmitting
                  ? const SizedBox.shrink()
                  : const Icon(Icons.verified_user),
              label: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('verify_code'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          // Botão reenviar
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _canResend && !_isSubmitting ? _handleResend : null,
              icon: const Icon(Icons.refresh),
              label: Text(
                _canResend ? 'resend_code'.tr : 'resend_available_soon'.tr,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}