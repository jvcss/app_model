// lib/view/forgot_password/widgets/email_step_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/password_reset_provider.dart';
import '../../../providers/notifications_provider.dart';
import '../../../services/app_translations.dart';

class EmailStepWidget extends ConsumerStatefulWidget {
  const EmailStepWidget({super.key});

  @override
  ConsumerState<EmailStepWidget> createState() => _EmailStepWidgetState();
}

class _EmailStepWidgetState extends ConsumerState<EmailStepWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  
  bool _isSubmitting = false;
  bool _emailTouched = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      if (_emailTouched) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'email_required'.tr;
    }
    
    final email = value.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    
    if (!emailRegex.hasMatch(email)) {
      return 'email_invalid'.tr;
    }
    
    return null;
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _emailTouched = true;
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
          .requestPasswordReset(_emailController.text.trim());
      
      ref.read(notificationsProvider.notifier).success(
        'Email enviado',
        'Verifique sua caixa de entrada',
      );
    } catch (e) {
      ref.read(notificationsProvider.notifier).error(
        'Erro',
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
    final isDark = theme.brightness == Brightness.dark;
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Descrição
          Text(
            'forgot_password_description'.tr,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          
          // Campo de email
          TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            enabled: !_isSubmitting,
            validator: _validateEmail,
            onFieldSubmitted: (_) => _handleSubmit(),
            decoration: InputDecoration(
              labelText: 'email_label'.tr,
              hintText: 'email_hint'.tr,
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: isDark 
                  ? Colors.white.withAlpha(12)
                  : Colors.black.withAlpha(5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withAlpha(127),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withAlpha(76),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.error,
                ),
              ),
              suffixIcon: _emailTouched
                  ? _validateEmail(_emailController.text) == null
                      ? Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                        )
                      : Icon(
                          Icons.error,
                          color: theme.colorScheme.error,
                        )
                  : null,
            ),
          ),
          const SizedBox(height: 32),
          
          // Botão de enviar
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _handleSubmit,
              icon: _isSubmitting
                  ? const SizedBox.shrink()
                  : const Icon(Icons.send),
              label: _isSubmitting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('sending'.tr),
                      ],
                    )
                  : Text('send_reset_code'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: _isSubmitting ? 0 : 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Informações adicionais
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(76),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withAlpha(51),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'security_notice'.tr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'email_code_info'.tr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}