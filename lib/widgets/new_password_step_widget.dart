// lib/view/forgot_password/widgets/new_password_step_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/password_reset_provider.dart';
import '../../../providers/notifications_provider.dart';
import '../../../services/app_translations.dart';

class NewPasswordStepWidget extends ConsumerStatefulWidget {
  const NewPasswordStepWidget({super.key});

  @override
  ConsumerState<NewPasswordStepWidget> createState() => _NewPasswordStepWidgetState();
}

class _NewPasswordStepWidgetState extends ConsumerState<NewPasswordStepWidget> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _passwordTouched = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      if (_passwordTouched) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'password_required'.tr;
    }
    
    final validator = ref.read(passwordValidationProvider);
    if (!validator.isValid(value)) {
      return 'password_weak'.tr;
    }
    
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'confirm_password_required'.tr;
    }
    
    if (value != _passwordController.text) {
      return 'passwords_not_match'.tr;
    }
    
    return null;
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _passwordTouched = true;
    });
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(passwordResetProvider.notifier)
          .setNewPassword(_passwordController.text);
      
      ref.read(notificationsProvider.notifier).success(
        'Senha alterada',
        'Sua senha foi redefinida com sucesso!',
      );
    } catch (e) {
      ref.read(notificationsProvider.notifier).error(
        'Erro ao redefinir senha',
        e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final validator = ref.watch(passwordValidationProvider);
    final passwordValidation = validator.validate(_passwordController.text);
    final passwordStrength = validator.strength(_passwordController.text);
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instrução
          Text(
            'create_strong_password'.tr,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          
          // Campo nova senha
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            enabled: !_isSubmitting,
            validator: _validatePassword,
            onChanged: (_) {
              setState(() {
                _passwordTouched = true;
              });
            },
            decoration: InputDecoration(
              labelText: 'new_password'.tr,
              hintText: 'enter_new_password'.tr,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(76),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          // Indicador de força da senha
          if (_passwordTouched && _passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            _PasswordStrengthIndicator(
              strength: passwordStrength,
              validations: passwordValidation,
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Campo confirmar senha
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            enabled: !_isSubmitting,
            validator: _validateConfirmPassword,
            decoration: InputDecoration(
              labelText: 'confirm_password'.tr,
              hintText: 'confirm_new_password'.tr,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(76),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Botão salvar
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _handleSubmit,
              icon: _isSubmitting
                  ? const SizedBox.shrink()
                  : const Icon(Icons.save),
              label: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('save_new_password'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget interno para indicador de força
class _PasswordStrengthIndicator extends StatelessWidget {
  final double strength;
  final Map<String, bool> validations;

  const _PasswordStrengthIndicator({
    required this.strength,
    required this.validations,
  });

  Color _getStrengthColor(BuildContext context) {
    final theme = Theme.of(context);
    if (strength < 0.3) return theme.colorScheme.error;
    if (strength < 0.6) return Colors.orange;
    if (strength < 0.8) return Colors.yellow.shade700;
    return Colors.green;
  }

  String _getStrengthText() {
    if (strength < 0.3) return 'Muito fraca';
    if (strength < 0.6) return 'Fraca';
    if (strength < 0.8) return 'Boa';
    return 'Forte';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strengthColor = _getStrengthColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra de força
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strength,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _getStrengthText(),
              style: TextStyle(
                color: strengthColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Critérios
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CriteriaChip(
              label: 'Mínimo 8 caracteres',
              met: validations['minLength'] ?? false,
            ),
            _CriteriaChip(
              label: 'Letra maiúscula',
              met: validations['hasUppercase'] ?? false,
            ),
            _CriteriaChip(
              label: 'Letra minúscula',
              met: validations['hasLowercase'] ?? false,
            ),
            _CriteriaChip(
              label: 'Número',
              met: validations['hasNumber'] ?? false,
            ),
            _CriteriaChip(
              label: 'Caractere especial',
              met: validations['hasSpecial'] ?? false,
            ),
          ],
        ),
      ],
    );
  }
}

class _CriteriaChip extends StatelessWidget {
  final String label;
  final bool met;

  const _CriteriaChip({
    required this.label,
    required this.met,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: met
            ? Colors.green.withAlpha(25)
            : theme.colorScheme.surfaceContainerHighest.withAlpha(127),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: met
              ? Colors.green
              : theme.colorScheme.outline.withAlpha(76),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: met ? Colors.green : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: met
                  ? Colors.green.shade700
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}