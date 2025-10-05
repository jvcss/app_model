import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

// Variáveis globais privadas - mais eficientes que singleton
late final Map<String, Map<String, String>> _translations;
late final Map<String, String> _locales;
late Locale _currentLocale;

/// Inicializa os arquivos de tradução
Future<void> initTranslations({
  required Map<String, String> locales,
  Locale? startLocale,
}) async {
  _locales = locales;
  _translations = {};

  // Carrega todos os arquivos de tradução
  for (final entry in _locales.entries) {
    final jsonStr = await rootBundle.loadString(entry.value);
    final Map<String, dynamic> map = json.decode(jsonStr);
    _translations[entry.key] = map.map((k, v) => MapEntry(k, v.toString()));
  }

  // Define locale atual: fornecido -> plataforma -> primeiro suportado
  _currentLocale = startLocale ??
      WidgetsBinding.instance.platformDispatcher.locale;
      //  ??       _firstSupportedAsLocale();
  _currentLocale = _resolveToSupported(_currentLocale);
}

/// Altera o locale atual
void setTranslationLocale(Locale locale) {
  _currentLocale = _resolveToSupported(locale);
}

/// Obtém o locale atual
Locale get currentTranslationLocale => _currentLocale;

/// Obtém lista de locales suportados baseada nos arquivos carregados
List<Locale> get supportedLocales {
  return _locales.keys.map((langKey) {
    final parts = langKey.split('_');
    return Locale(parts[0], parts.length > 1 ? parts[1] : null);
  }).toList();
}

/// Função para sincronizar com Riverpod Provider
void syncWithRiverpodLocale(Locale locale) {
  setTranslationLocale(locale);
}

/// Função principal de tradução
String _translate(
  String key, {
  Locale? locale,
  Map<String, Object?> params = const {},
}) {
  final useLocale = locale ?? _currentLocale;
  final langKey = _toLangKey(useLocale);
  final value = _translations[langKey]?[key] ?? key;
  return _interpolate(value, params);
}

// --- Funções auxiliares privadas ---

String _toLangKey(Locale locale) {
  final country = locale.countryCode;
  return country != null ? '${locale.languageCode}_$country' : locale.languageCode;
}

// ignore: unused_element
Locale _firstSupportedAsLocale() {
  final first = _locales.keys.first;
  final parts = first.split('_');
  return Locale(parts[0], parts.length > 1 ? parts[1] : null);
}

/// Resolve locale para um suportado: exato -> fallback de idioma -> primeiro
Locale _resolveToSupported(Locale candidate) {
  final exact = _toLangKey(candidate);
  if (_translations.containsKey(exact)) return candidate;

  // Fallback para idioma apenas (ex: pt -> pt_BR se disponível)
  final langOnly = candidate.languageCode;
  final fallbackKey = _translations.keys.firstWhere(
    (k) => k.startsWith('${langOnly}_') || k == langOnly,
    orElse: () => _locales.keys.first,
  );

  final parts = fallbackKey.split('_');
  return Locale(parts[0], parts.length > 1 ? parts[1] : null);
}

/// Interpolação simples de placeholders: "Olá, {name}!"
String _interpolate(String text, Map<String, Object?> params) {
  if (params.isEmpty) return text;
  var result = text;
  params.forEach((key, value) {
    result = result.replaceAll('{$key}', '${value ?? ''}');
  });
  return result;
}

/// Extensão para adicionar métodos de tradução às strings
extension StringTranslation on String {
  /// Tradução simples: 'app_title'.tr
  String get tr => _translate(this);

  /// Tradução com interpolação: 'welcome_user'.trp({'name': 'João'})
  String trp(Map<String, Object?> params) => _translate(this, params: params);

  /// Tradução com locale específico: 'hello'.trIn(Locale('en', 'US'))
  String trIn(Locale locale, {Map<String, Object?> params = const {}}) =>
      _translate(this, locale: locale, params: params);
}