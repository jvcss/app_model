import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

// importar seus widgets de página
import 'package:flutter/material.dart';

import '../view/forgot_password/forgot_password_page.dart';
import '../view/home/home_page.dart';
import '../view/login/login_page.dart';
import '../view/register/register_page.dart';


final _routerRefreshProvider = Provider<RouterRefreshProvider>((ref) {
  final notifier = RouterRefreshProvider(ref);
  ref.listen(authProvider, (_, __) => notifier.refresh());
  return notifier;
});


final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(_routerRefreshProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      // validar o tempo de token, se expirou, deslogar o usuario

      final authState = ref.read(authProvider);
      final isAuthenticated = authState.value?.isAuthenticated ?? false;
      final isAtLogin = state.uri.path == '/login';
      final isAtRegister = state.uri.path == '/register';
      final isAtForgotPassword =
          state.uri.path == '/forgot-password'; // NOVA VERIFICAÇÃO

      if (!isAuthenticated && !isAtLogin && !isAtRegister && !isAtForgotPassword) return '/login';
      if (isAuthenticated && (isAtLogin || isAtRegister || isAtForgotPassword)) return '/home';

      return null;
    },

    routes: [
      GoRoute(path: '/login', builder: (context, state) => LoginPage()),
      GoRoute(path: '/register', builder: (context, state) => RegisterPage()),
      GoRoute(path: '/home', builder: (context, state) => HomePage()),
      GoRoute(path: '/forgot-password', builder: (context, state) => ForgotPasswordPage()),
    ],
  );
});

class RouterRefreshProvider extends ChangeNotifier {
  final Ref ref;

  RouterRefreshProvider(this.ref);

  void refresh() {
    notifyListeners();
  }
}
