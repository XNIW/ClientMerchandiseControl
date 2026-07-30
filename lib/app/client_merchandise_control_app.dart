import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import 'branding/app_brand.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class ClientMerchandiseControlApp extends ConsumerWidget {
  const ClientMerchandiseControlApp({super.key, this.locale});

  final Locale? locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (_) => AppBrand.technicalDisplayName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: _resolveLocale,
      routerConfig: router,
    );
  }

  Locale _resolveLocale(
    Locale? preferredLocale,
    Iterable<Locale> supportedLocales,
  ) {
    for (final supported in supportedLocales) {
      if (preferredLocale?.languageCode == supported.languageCode) {
        return supported;
      }
    }
    return const Locale('es');
  }
}
