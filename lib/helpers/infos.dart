import 'package:flutter/foundation.dart' show debugPrint, kReleaseMode, kProfileMode;

void printInfo() {
  debugPrint('---');
  debugPrint(const String.fromEnvironment('DEBUG_MODE') == 'true' ? 'Debug mode is ON' : 'Debug mode is OFF');
  debugPrint('Backend URL: ${const String.fromEnvironment('BACKEND_URL')}');
  debugPrint('---');
  debugPrint('Dart version: ${const String.fromEnvironment('DART_VERSION')}');
  debugPrint('Flutter version: ${const String.fromEnvironment('FLUTTER_VERSION')}');
  debugPrint('---');
  debugPrint('App version: ${const String.fromEnvironment('APP_VERSION')}');
  debugPrint('Build number: ${const String.fromEnvironment('BUILD_NUMBER')}');
  debugPrint('Build mode: ${kReleaseMode ? 'release' : kProfileMode ? 'profile' : 'debug'}');
  debugPrint('---');
  // color system light
  debugPrint('Primary color (light): ${const String.fromEnvironment('PRIMARY_COLOR_LIGHT')}');
  debugPrint('Complementary color (light): ${const String.fromEnvironment('COMPLEMENTARY_COLOR_LIGHT')}');
  debugPrint('Analogous color 1 (light): ${const String.fromEnvironment('ANALOGOUS_1_COLOR_LIGHT')}');
  debugPrint('Analogous color 2 (light): ${const String.fromEnvironment('ANALOGOUS_2_COLOR_LIGHT')}');
  debugPrint('Triadic color 1 (light): ${const String.fromEnvironment('TRIADIC_1_COLOR_LIGHT')}');
  debugPrint('Triadic color 2 (light): ${const String.fromEnvironment('TRIADIC_2_COLOR_LIGHT')}');
  debugPrint('---');
  // color system dark
  debugPrint('Primary color (dark): ${const String.fromEnvironment('PRIMARY_COLOR_DARK')}');
  debugPrint('Complementary color (dark): ${const String.fromEnvironment('COMPLEMENTARY_COLOR_DARK')}');
  debugPrint('Analogous color 1 (dark): ${const String.fromEnvironment('ANALOGOUS_1_COLOR_DARK')}');
  debugPrint('Analogous color 2 (dark): ${const String.fromEnvironment('ANALOGOUS_2_COLOR_DARK')}');
  debugPrint('Triadic color 1 (dark): ${const String.fromEnvironment('TRIADIC_1_COLOR_DARK')}');
  debugPrint('Triadic color 2 (dark): ${const String.fromEnvironment('TRIADIC_2_COLOR_DARK')}');
  debugPrint('---');
}
