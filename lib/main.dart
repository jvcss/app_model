import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'helpers/infos.dart' show printInfo;
import 'routes/app_router.dart';
import 'services/app_translations.dart';
import 'services/locale_provider.dart';
import 'services/theme_service.dart';
import 'widgets/notifications_overlay.dart';
import 'widgets/theme_widget_fancy_toggle.dart';

void main() async {
  printInfo();
  WidgetsFlutterBinding.ensureInitialized();
  await initTranslations(
    locales: {'pt_BR': 'locales/pt_BR.json'},
    startLocale: const Locale('pt', 'BR'),
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeServiceProvider);

    return MaterialApp.router(
      locale: locale,
      supportedLocales: const [Locale('pt', 'BR')],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      title: 'app_title'.tr,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) => Stack(
        children: [
          if (child != null) child,
          // Overlays permanentes (não interferem na navegação)
          const ThemeCornerToggleOverlay(), // canto superior direito
          const NotificationsOverlay(), // já existente
        ],
      ),
    );
  }
}
