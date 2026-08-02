import 'package:client_merchandise_control/app/design_system/widgets/storefront_cache_status.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('freshness cached è localizzata e annunciata come live region', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    for (final locale in const [
      Locale('es', 'CL'),
      Locale('it'),
      Locale('en'),
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    ]) {
      await tester.pumpWidget(
        _app(
          locale: locale,
          isStale: true,
          isRefreshing: true,
          textScaler: TextScaler.noScaling,
        ),
      );

      final context = tester.element(
        find.byKey(const ValueKey('storefront-cache-status')),
      );
      final l10n = AppLocalizations.of(context);
      expect(find.textContaining(l10n.storefrontCacheRefreshing), findsOne);
      expect(
        find.bySemanticsLabel(
          RegExp('${l10n.storefrontCacheRefreshing}${r'$'}'),
        ),
        findsOne,
      );
      expect(tester.takeException(), isNull, reason: locale.toLanguageTag());
    }
    semantics.dispose();
  });

  testWidgets('banner cache resta usabile a 320px con testo 200%', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _app(
        locale: const Locale('es', 'CL'),
        isStale: true,
        isRefreshing: false,
        textScaler: const TextScaler.linear(2),
      ),
    );

    expect(
      find.byKey(const ValueKey('storefront-cache-status')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _app({
  required Locale locale,
  required bool isStale,
  required bool isRefreshing,
  required TextScaler textScaler,
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.light(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: textScaler),
    child: child!,
  ),
  home: Scaffold(
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StorefrontCacheStatus(
          cachedAt: DateTime.utc(2026, 8, 2, 12, 30),
          isStale: isStale,
          isRefreshing: isRefreshing,
        ),
      ],
    ),
  ),
);
