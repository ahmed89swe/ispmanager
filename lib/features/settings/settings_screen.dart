import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/providers/preferences_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final currency = ref.watch(currencyProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: Text(l.theme),
                trailing: DropdownButton<ThemeMode>(
                  value: theme,
                  onChanged: (v) {
                    if (v != null) ref.read(themeModeProvider.notifier).set(v);
                  },
                  items: [
                    DropdownMenuItem(
                        value: ThemeMode.system, child: Text(l.themeSystem)),
                    DropdownMenuItem(
                        value: ThemeMode.light, child: Text(l.themeLight)),
                    DropdownMenuItem(
                        value: ThemeMode.dark, child: Text(l.themeDark)),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.translate),
                title: Text(l.language),
                trailing: DropdownButton<String>(
                  value: locale.languageCode,
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(localeProvider.notifier).set(Locale(v));
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'ar', child: Text('العربية')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: Text(l.defaultCurrency),
                trailing: DropdownButton<AppCurrency>(
                  value: currency,
                  onChanged: (v) {
                    if (v != null) ref.read(currencyProvider.notifier).set(v);
                  },
                  items: AppCurrency.values
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c.code)))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
