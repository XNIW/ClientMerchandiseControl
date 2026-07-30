import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import 'branding/app_brand.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

const appSupportedLocales = <Locale>[
  Locale('en'),
  Locale('es'),
  Locale('it'),
  Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
];

class ClientMerchandiseControlApp extends ConsumerWidget {
  const ClientMerchandiseControlApp({super.key, this.locale});

  final Locale? locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (_) => AppBrand.effectiveDisplayName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: appSupportedLocales,
      localeListResolutionCallback: resolveAppLocale,
      routerConfig: router,
    );
  }
}

@visibleForTesting
Locale resolveAppLocale(
  List<Locale>? preferredLocales,
  Iterable<Locale> supportedLocales,
) {
  final supported = supportedLocales.toList(growable: false);

  for (final preferred in preferredLocales ?? const <Locale>[]) {
    if (preferred.languageCode == 'zh') {
      final isSimplifiedChinese =
          preferred.scriptCode == 'Hans' ||
          (preferred.scriptCode == null &&
              const {'CN', 'SG'}.contains(preferred.countryCode));
      if (!isSimplifiedChinese) {
        continue;
      }

      for (final candidate in supported) {
        if (candidate.languageCode == 'zh' && candidate.scriptCode == 'Hans') {
          return candidate;
        }
      }
      continue;
    }

    for (final candidate in supported) {
      if (candidate.languageCode == preferred.languageCode) {
        return candidate;
      }
    }
  }

  for (final candidate in supported) {
    if (candidate.languageCode == 'es') {
      return candidate;
    }
  }
  return const Locale('es');
}
