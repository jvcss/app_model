// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'light_theme.dart';
import 'dark_theme.dart';

/// Sistema de temas da aplicação
/// Exporta light e dark themes prontos para uso
class AppTheme {
  /// Tema claro (baseado no Bitrix 24)
  static ThemeData get light => getLightTheme();

  /// Tema escuro (baseado no Bitrix 24)
  static ThemeData get dark => getDarkTheme();

  /// Retorna tema baseado no ThemeMode
  static ThemeData getTheme(ThemeMode mode, Brightness systemBrightness) {
    switch (mode) {
      case ThemeMode.light:
        return light;
      case ThemeMode.dark:
        return dark;
      case ThemeMode.system:
        return systemBrightness == Brightness.dark ? dark : light;
    }
  }
}