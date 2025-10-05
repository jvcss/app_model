// lib/view/forgot_password/forgot_password_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/password_reset_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../services/app_translations.dart';
import '../../widgets/email_step_widget.dart';
import '../../widgets/new_password_step_widget.dart';
import '../../widgets/success_step_widget.dart';
import '../../widgets/verification_step_widget.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleBack() {
    final state = ref.read(passwordResetProvider);
    
    state.whenData((resetState) {
      if (resetState.currentStep == PasswordResetStep.email) {
        context.go('/login');
      } else {
        ref.read(passwordResetProvider.notifier).goBack();
      }
    });
  }

  Widget _buildStepContent(PasswordResetState resetState) {
    switch (resetState.currentStep) {
      case PasswordResetStep.email:
        return const EmailStepWidget();
      case PasswordResetStep.verification:
        return const VerificationStepWidget();
      case PasswordResetStep.newPassword:
        return const NewPasswordStepWidget();
      case PasswordResetStep.success:
        return const SuccessStepWidget();
    }
  }

  String _getStepTitle(PasswordResetStep step) {
    switch (step) {
      case PasswordResetStep.email:
        return 'forgot_password_title'.tr;
      case PasswordResetStep.verification:
        return 'verification_title'.tr;
      case PasswordResetStep.newPassword:
        return 'new_password_title'.tr;
      case PasswordResetStep.success:
        return 'success_title'.tr;
    }
  }

  int _getStepNumber(PasswordResetStep step) {
    switch (step) {
      case PasswordResetStep.email:
        return 1;
      case PasswordResetStep.verification:
        return 2;
      case PasswordResetStep.newPassword:
        return 3;
      case PasswordResetStep.success:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resetState = ref.watch(passwordResetProvider);
    
    // Reinicia a animação quando muda de etapa
    ref.listen(passwordResetProvider, (previous, next) {
      if (previous?.value?.currentStep != next.value?.currentStep) {
        _animationController.reset();
        _animationController.forward();
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withAlpha(12),
              theme.colorScheme.secondary.withAlpha(12),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: resetState.when(
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) {
                  // Mostra erro temporariamente e retorna ao estado anterior
                  Future.microtask(() {
                    ref.read(notificationsProvider.notifier).error(
                      'Erro',
                      error.toString().replaceAll('Exception: ', ''),
                    );
                  });
                  
                  // Retorna ao widget anterior se houver estado
                  if (resetState.valueOrNull != null) {
                    return _buildMainContent(resetState.valueOrNull!);
                  }
                  
                  return Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        error.toString().replaceAll('Exception: ', ''),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Voltar ao login'),
                      ),
                    ],
                  );
                },
                data: (state) => _buildMainContent(state),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(PasswordResetState resetState) {
    final theme = Theme.of(context);
    final currentStep = _getStepNumber(resetState.currentStep);
    final isSuccess = resetState.currentStep == PasswordResetStep.success;
    
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 450),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header com logo ou ícone
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withAlpha(76),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              isSuccess ? Icons.check : Icons.lock_reset,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          
          // Título da etapa atual
          Text(
            _getStepTitle(resetState.currentStep),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (!isSuccess) ...[
            const SizedBox(height: 24),
            
            // Indicador de progresso
            _buildProgressIndicator(currentStep),
            const SizedBox(height: 32),
          ] else
            const SizedBox(height: 24),
          
          // Conteúdo da etapa com animação
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildStepContent(resetState),
                ),
              ),
            ),
          ),
          
          // Botão de voltar (exceto na tela de sucesso)
          if (!isSuccess) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _handleBack,
              icon: const Icon(Icons.arrow_back),
              label: Text(
                resetState.currentStep == PasswordResetStep.email
                    ? 'Voltar ao login'
                    : 'Voltar',
              ),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(int currentStep) {
    final theme = Theme.of(context);
    
    return Row(
      children: List.generate(3, (index) {
        final stepNumber = index + 1;
        final isActive = stepNumber == currentStep;
        final isCompleted = stepNumber < currentStep;
        
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              left: index > 0 ? 4 : 0,
              right: index < 2 ? 4 : 0,
            ),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isActive || isCompleted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        );
      }),
    );
  }
}