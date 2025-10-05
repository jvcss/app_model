import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_translations.dart';
import '../services/locale_provider.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final availableLocales = supportedLocales;

    return DropdownButton<Locale>(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      value: currentLocale,
      icon: const Icon(Icons.language),
      elevation: 8,
      style: Theme.of(context).textTheme.bodyMedium,
      underline: Container(
        height: 2,
        color: Theme.of(context).colorScheme.primary,
      ),
      onChanged: (Locale? newLocale) {
        if (newLocale != null) {
          ref.read(localeProvider.notifier).setLocale(newLocale);
        }
      },
      items: availableLocales.map<DropdownMenuItem<Locale>>((Locale locale) {
        return DropdownMenuItem<Locale>(
          value: locale,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _getFlag(locale),
              const SizedBox(width: 8),
              Text(_getLanguageName(locale)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _getFlag(Locale locale) {
    final flagEmoji = switch (locale.languageCode) {
      'pt' => '🇧🇷',
      'en' => '🇺🇸',
      'es' => '🇪🇸',
      'fr' => '🇫🇷',
      'de' => '🇩🇪',
      'it' => '🇮🇹',
      _ => '🌐',
    };
    
    return Text(
      flagEmoji,
      style: const TextStyle(fontSize: 20),
    );
  }

  String _getLanguageName(Locale locale) {
    return switch (locale.languageCode) {
      'pt' => 'Português',
      'en' => 'English',
      'es' => 'Español',
      'fr' => 'Français',
      'de' => 'Deutsch',
      'it' => 'Italiano',
      _ => locale.languageCode.toUpperCase(),
    };
  }
}

/// Versão compacta para usar em AppBar ou espaços pequenos
class CompactLanguageSelector extends ConsumerWidget {
  const CompactLanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final availableLocales = supportedLocales;

    return PopupMenuButton<Locale>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _getFlag(currentLocale),
          const Icon(Icons.arrow_drop_down, size: 16),
        ],
      ),
      onSelected: (Locale locale) {
        ref.read(localeProvider.notifier).setLocale(locale);
      },
      itemBuilder: (BuildContext context) {
        return availableLocales.map((Locale locale) {
          return PopupMenuItem<Locale>(
            value: locale,
            child: Row(
              children: [
                _getFlag(locale),
                const SizedBox(width: 12),
                Text(_getLanguageName(locale)),
                if (locale == currentLocale) ...[
                  const Spacer(),
                  Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
                ],
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _getFlag(Locale locale) {
    final flagEmoji = switch (locale.languageCode) {
      'pt' => '🇧🇷',
      'en' => '🇺🇸',
      'es' => '🇪🇸',
      'fr' => '🇫🇷',
      'de' => '🇩🇪',
      'it' => '🇮🇹',
      _ => '🌐',
    };
    
    return Text(
      flagEmoji,
      style: const TextStyle(fontSize: 18),
    );
  }

  String _getLanguageName(Locale locale) {
    return switch (locale.languageCode) {
      'pt' => 'Português',
      'en' => 'English',
      'es' => 'Español',
      'fr' => 'Français',
      'de' => 'Deutsch',
      'it' => 'Italiano',
      _ => locale.languageCode.toUpperCase(),
    };
  }
}

/// Widget para configurações com título e descrição
class LanguageSettingTile extends ConsumerWidget {
  const LanguageSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final availableLocales = supportedLocales;

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text('language_settings'.tr),
      subtitle: Text('language_settings_description'.tr),
      trailing: DropdownButton<Locale>(
        value: currentLocale,
        underline: const SizedBox(),
        onChanged: (Locale? newLocale) {
          if (newLocale != null) {
            ref.read(localeProvider.notifier).setLocale(newLocale);
          }
        },
        items: availableLocales.map<DropdownMenuItem<Locale>>((Locale locale) {
          return DropdownMenuItem<Locale>(
            value: locale,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _getFlag(locale),
                const SizedBox(width: 8),
                Text(_getLanguageName(locale)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _getFlag(Locale locale) {
    final flagEmoji = switch (locale.languageCode) {
      'pt' => '🇧🇷',
      'en' => '🇺🇸',
      'es' => '🇪🇸',
      'fr' => '🇫🇷',
      'de' => '🇩🇪',
      'it' => '🇮🇹',
      _ => '🌐',
    };
    
    return Text(
      flagEmoji,
      style: const TextStyle(fontSize: 16),
    );
  }

  String _getLanguageName(Locale locale) {
    return switch (locale.languageCode) {
      'pt' => 'Português',
      'en' => 'English',
      'es' => 'Español',
      'fr' => 'Français',
      'de' => 'Deutsch',
      'it' => 'Italiano',
      _ => locale.languageCode.toUpperCase(),
    };
  }
}