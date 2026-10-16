import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/app_update/app_update_repository.dart';
import '../features/app_update/update_screen.dart';
import '../l10n/app_localizations.dart';
import '../shared/providers/preferences_providers.dart';
import '../core/models/models.dart';
import '../core/services/notification_service.dart';
import '../features/auth/auth_repository.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class IspUserManagerApp extends ConsumerWidget {
  const IspUserManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final updateAsync = ref.watch(appUpdateProvider);

    return MaterialApp(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: updateAsync.when(
        loading: () => const _SplashScreen(message: 'Checking for updates...'),
        error: (e, _) => _UpdateCheckErrorScreen(
          message: 'Update check error:\n$e',
          onRetry: () => ref.invalidate(appUpdateProvider),
        ),
        data: (info) {
          if (info.needsUpdate) {
            return UpdateScreen(info: info);
          }
          // Initialize notifications whenever the app is completely loaded and no update is required.
          ref.read(notificationServiceProvider).init();
          return const _MainAppRouter();
        },
      ),
    );
  }
}

class _UpdateCheckErrorScreen extends StatelessWidget {
  const _UpdateCheckErrorScreen({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainAppRouter extends ConsumerWidget {
  const _MainAppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<AppUser?>>(currentAppUserProvider, (prev, next) {
      final user = next.valueOrNull;
      if (user != null) {
        ref.read(notificationServiceProvider).syncUserToken(user);
      }
    });

    final currentUser = ref.watch(currentAppUserProvider).valueOrNull;
    if (currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(notificationServiceProvider).syncUserToken(currentUser);
      });
    }

    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(message, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
