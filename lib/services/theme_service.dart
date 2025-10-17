// lib/services/theme_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider simples para gerenciar o ThemeMode
final themeServiceProvider = StateNotifierProvider<ThemeService, ThemeMode>(
  (ref) => ThemeService(),
);

class ThemeService extends StateNotifier<ThemeMode> {
  static const _key = 'theme_mode';

  ThemeService() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  /// Carrega o tema salvo
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_key);

    if (savedMode != null) {
      state = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedMode,
        orElse: () => ThemeMode.system,
      );
    }
  }

  /// Alterna entre light e dark
  Future<void> toggle() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// Define um tema específico
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.toString());
  }
}
