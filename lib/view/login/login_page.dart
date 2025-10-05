import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../models/app_notification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../services/app_translations.dart';
import '../../widgets/language_selector.dart';
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  String _appVersion = '';
  bool _isEmailValid = true;
  bool _isPasswordValid = true;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();

    // Add listeners to controllers
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);

    // Prefill for development (remove in production)
    if (kDebugMode) {
      _emailController.text = 'jvcs.mecatronica@gmail.com';
      _passwordController.text = 'jvcs.mecatronica@gmail.com';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _validateEmail() {
    setState(() {
      _isEmailValid =
          _emailController.text.trim().isNotEmpty &&
          RegExp(
            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
          ).hasMatch(_emailController.text.trim());
    });
  }

  void _validatePassword() {
    setState(() {
      _isPasswordValid = _passwordController.text.isNotEmpty;
    });
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'v${info.version} (${info.buildNumber})';
    });
  }

  Future<void> _onLogin() async {
    // Validate fields before attempting login
    _validateEmail();
    _validatePassword();

    if (!_isEmailValid || !_isPasswordValid) {
      ref
          .read(notificationsProvider.notifier)
          .error(
            'Erro de Validação',
            'Por favor, verifique os campos de email e senha.',
          );
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      ref
          .read(notificationsProvider.notifier)
          .show(
            title: 'Acesso',
            message: 'Fazendo login',
            type: AppNotificationType.info,
            duration: const Duration(seconds: 3),
          );

      await ref.read(authProvider.notifier).login(email, password);
    } catch (e) {
      ref
          .read(notificationsProvider.notifier)
          .error(
            'Erro de Login',
            'Não foi possível realizar o login. Verifique suas credenciais.',
          );
    }
  }

  void _launchWhatsApp() {
    final email = _emailController.text.trim();
    launchUrlString(
      'https://wa.me/5562985031343?text=*Assunto:*%20Solicitação%20de%20acesso%0A*Mensagem:*%20Olá,%20preciso%20de%20acesso%20ao%20sistema%20IA%20Sindicancia.%0A*Email:*%20$email',
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                margin: const EdgeInsets.all(24),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LanguageSelector(),
                        const SizedBox(height: 16),
                        Text(
                          'welcome_title'.tr,
                          style: theme.textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          decoration: InputDecoration(
                            labelText: 'email_input'.tr,
                            hintText: 'email_hint'.tr,
                            errorText: _isEmailValid ? null : 'email_error'.tr,
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) {
                            FocusScope.of(
                              context,
                            ).requestFocus(_passwordFocusNode);
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          decoration: InputDecoration(
                            labelText: 'password_input'.tr,
                            hintText: 'password_hint'.tr,
                            errorText: _isPasswordValid
                                ? null
                                : 'password_error'.tr,
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                          ),
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _onLogin(),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            child: Text(
                              'forgot_password'.tr,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50, // Altura consistente
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _onLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: authState.isLoading
                                ? const CircularProgressIndicator()
                                : Text(
                                    'login_label'.tr,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            _launchWhatsApp();
                            context.go('/register');
                          },
                          child: Text('request_access'.tr),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_appVersion.isNotEmpty)
                Text(
                  _appVersion,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
