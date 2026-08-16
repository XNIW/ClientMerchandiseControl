import 'package:client_merchandise_control/app/branding/app_brand.dart';
import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
import 'package:client_merchandise_control/app/design_system/tokens/app_sizes.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/catalog/presentation/catalog_screen.dart';
import 'package:client_merchandise_control/features/home/presentation/home_screen.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp() {
    return ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(AppConfig.fromValues())],
      child: const ClientMerchandiseControlApp(locale: Locale('es', 'CL')),
    );
  }

  testWidgets('Home guest usa il brand centralizzato e stati futuri onesti', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(HomeScreen)));

    expect(find.text(AppBrand.effectiveDisplayName), findsOneWidget);
    expect(find.text(l10n.homeWelcomeTitle), findsNothing);
    expect(find.text(l10n.homeSelectedStore), findsOneWidget);
    expect(find.byKey(const ValueKey('home-search')), findsOneWidget);
    expect(find.text(l10n.homeCategoriesTitle), findsOneWidget);
    expect(find.text(l10n.homeOffersEmptyTitle), findsOneWidget);
    expect(find.text(l10n.homeFeaturedEmptyTitle), findsOneWidget);
    expect(find.byType(Image), findsNothing);

    final visibleText = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>()
        .join(' ');
    expect(
      RegExp(
        r'(?:CLP\s*\d|\$\s*\d|stock\s*[:=]?\s*\d)',
        caseSensitive: false,
      ).hasMatch(visibleText),
      isFalse,
    );
  });

  testWidgets('ricerca e CTA Home aprono il Catalogo senza login', (
    tester,
  ) async {
    for (final key in const [
      ValueKey('home-search'),
      ValueKey('home-categories'),
    ]) {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(key));
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();

      expect(find.byType(CatalogScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('le azioni Home sono accessibili e rispettano 48 dp', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    for (final key in const [
      ValueKey('home-search'),
      ValueKey('home-categories'),
    ]) {
      final finder = find.byKey(key);
      await tester.ensureVisible(finder);
      expect(
        tester.getSize(finder).height,
        greaterThanOrEqualTo(AppSizes.minimumTouchTarget),
      );
    }

    expect(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(tester, meetsGuideline(androidTapTargetGuideline));
    expect(tester, meetsGuideline(iOSTapTargetGuideline));
  });
}
