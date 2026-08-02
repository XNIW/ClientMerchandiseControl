import 'dart:async';

import 'package:client_merchandise_control/core/backend/backend_health_service.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_repository.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/home/presentation/home_screen.dart';
import 'package:client_merchandise_control/features/storefront/application/storefront_providers.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_repository.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_failure.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_repository.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../storefront/storefront_test_fixture.dart';

void main() {
  testWidgets(
    'Home guest mostra categorie, featured, offerte e prezzi CLP reali',
    (tester) async {
      await tester.pumpWidget(
        _homeApp(repository: _SequenceRepository.success()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bebidas'), findsOneWidget);
      expect(find.text('Café destacado'), findsOneWidget);
      expect(find.text('Té en oferta'), findsOneWidget);
      expect(find.text(r'$1.500'), findsWidgets);
      expect(find.text(r'$1.200'), findsOneWidget);
      expect(find.text('20% de descuento'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          r'Té en oferta, $1.200, Antes $1.500, 20% de descuento',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('home-retry')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('loading non presenta empty state contraddittori', (
    tester,
  ) async {
    final pending = Completer<StorefrontHomeData>();
    await tester.pumpWidget(
      _homeApp(repository: _SequenceRepository([() => pending.future])),
    );
    await tester.pump();

    final l10n = AppLocalizations.of(tester.element(find.byType(HomeScreen)));
    expect(find.text(l10n.homeLoadingTitle), findsOneWidget);
    expect(find.text(l10n.homeOffersEmptyTitle), findsNothing);
    expect(find.text(l10n.homeFeaturedEmptyTitle), findsNothing);

    pending.complete(validStorefrontHomeData());
    await tester.pumpAndSettle();
    expect(find.text('Café destacado'), findsOneWidget);
  });

  testWidgets('errore rete offre retry e sostituisce lo stato con dati', (
    tester,
  ) async {
    final repository = _SequenceRepository([
      () => Future.error(
        const StorefrontFailure(
          StorefrontFailureKind.offline,
          code: 'network_offline',
        ),
      ),
      () => Future.value(validStorefrontHomeData()),
    ]);
    await tester.pumpWidget(_homeApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-retry')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-retry')));
    await tester.pumpAndSettle();

    expect(find.text('Café destacado'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-retry')), findsNothing);
    expect(repository.calls, 2);
  });

  testWidgets('Home data reflow non overflowa in dark mode e text scale 200%', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _homeApp(
        repository: _SequenceRepository.success(),
        themeMode: ThemeMode.dark,
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(find.text('Té en oferta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home data resta localizzata in es, it, en e zh-Hans', (
    tester,
  ) async {
    for (final locale in const [
      Locale('es', 'CL'),
      Locale('it'),
      Locale('en'),
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    ]) {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.pumpWidget(
        _homeApp(repository: _SequenceRepository.success(), locale: locale),
      );
      await tester.pumpAndSettle();
      expect(find.text('Café destacado'), findsOneWidget, reason: '$locale');
      expect(tester.takeException(), isNull, reason: '$locale');
    }
  });
}

Widget _homeApp({
  required StorefrontRepository repository,
  Locale locale = const Locale('es', 'CL'),
  ThemeMode themeMode = ThemeMode.light,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(
        AppConfig.fromValues(
          appEnvironment: 'staging',
          supabaseUrl: 'https://staging.example.invalid',
          supabasePublishableKey: 'sb_publishable_staging',
          authRedirectUri: AppConfig.allowedAuthRedirectUri,
          googleAuthEnabled: 'false',
          storefrontShopSlug: 'storefront-test',
        ),
      ),
      backendReadinessRepositoryProvider.overrideWithValue(
        const _StaticReadinessRepository(),
      ),
      storefrontRepositoryProvider.overrideWithValue(repository),
      storefrontCacheRepositoryProvider.overrideWithValue(
        const DisabledStorefrontCacheRepository(),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: const Scaffold(body: HomeScreen()),
    ),
  );
}

final class _SequenceRepository extends HomeOnlyStorefrontRepository {
  _SequenceRepository(this.responses);

  factory _SequenceRepository.success() =>
      _SequenceRepository([() => Future.value(validStorefrontHomeData())]);

  final List<Future<StorefrontHomeData> Function()> responses;
  var calls = 0;

  @override
  Future<StorefrontHomeData> fetchHome({
    required String shopSlug,
    required StorefrontRequestCancellation cancellation,
  }) => responses[calls++]();
}

final class _StaticReadinessRepository implements BackendReadinessRepository {
  const _StaticReadinessRepository();

  @override
  BackendReadinessState get initialState => BackendReadinessState.ready;

  @override
  bool get canCheck => false;

  @override
  Future<BackendReadinessState> check({
    required BackendProbeCancellation cancellation,
  }) async => BackendReadinessState.ready;
}
