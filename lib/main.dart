import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'helpers/infos.dart' show printInfo;
import 'routes/app_router.dart';
import 'services/app_translations.dart';
import 'services/locale_provider.dart';
import 'widgets/notifications_overlay.dart';
import 'providers/theme_provider.dart';
import 'widgets/theme_widget_fancy_toggle.dart';

void main() async {
  printInfo();
  WidgetsFlutterBinding.ensureInitialized();
  await initTranslations(
    locales: {'pt_BR': 'appends/locales/pt_BR.json'},
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
    final themeMode = ref.watch(themeModeProvider);

    final light = ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
      useMaterial3: true,
    );

    final dark = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.lightBlueAccent,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );

    return MaterialApp.router(
      locale: locale,
      supportedLocales: const [Locale('pt', 'BR')],
      theme: light,
      darkTheme: dark,
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
