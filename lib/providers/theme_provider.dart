// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// final themeModeProvider =
//     StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
//   return ThemeModeNotifier();
// });

// class ThemeModeNotifier extends StateNotifier<ThemeMode> {
//   static const _k = 'themeMode';
//   ThemeModeNotifier() : super(ThemeMode.system) {
//     _load();
//   }

//   Future<void> _load() async {
//     final prefs = await SharedPreferences.getInstance();
//     final raw = prefs.getString(_k);
//     if (raw == null) return;
//     switch (raw) {
//       case 'light':
//         state = ThemeMode.light;
//         break;
//       case 'dark':
//         state = ThemeMode.dark;
//         break;
//       default:
//         state = ThemeMode.system;
//     }
//   }

//   Future<void> set(ThemeMode mode) async {
//     state = mode;
//     final prefs = await SharedPreferences.getInstance();
//     final raw = switch (mode) {
//       ThemeMode.light => 'light',
//       ThemeMode.dark => 'dark',
//       _ => 'system',
//     };
//     await prefs.setString(_k, raw);
//   }

//   Future<void> toggle() async {
//     final next =
//         state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
//     await set(next);
//   }
// }
