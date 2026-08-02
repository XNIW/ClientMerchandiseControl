import 'package:client_merchandise_control/app/design_system/widgets/storefront_status_banner.dart';
import 'package:client_merchandise_control/bootstrap.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/core/config/app_environment.dart';
import 'package:client_merchandise_control/features/catalog/presentation/catalog_screen.dart';
import 'package:client_merchandise_control/features/catalog/application/catalog_controller.dart';
import 'package:client_merchandise_control/features/home/presentation/home_screen.dart';
import 'package:client_merchandise_control/features/shell/presentation/app_shell_screen.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bootstrap staging raggiunge Auth health e naviga la shell', (
    tester,
  ) async {
    final config = AppConfig.fromEnvironment();
    expect(config.environment, AppEnvironment.staging);
    expect(config.googleAuthEnabled, isFalse);

    await bootstrap();
    await tester.pump();

    expect(find.byType(AppShellScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(StorefrontStatusBanner), findsOneWidget);

    final shellContext = tester.element(find.byType(AppShellScreen));
    final container = ProviderScope.containerOf(shellContext);
    final l10n = AppLocalizations.of(shellContext);
    expect(
      container.read(backendReadinessControllerProvider),
      BackendReadinessState.initializing,
    );
    expect(find.text(l10n.backendChecking), findsOneWidget);

    await _waitForReady(tester, container);

    expect(
      container.read(backendReadinessControllerProvider),
      BackendReadinessState.ready,
    );
    expect(find.byType(StorefrontStatusBanner), findsNothing);
    expect(find.text(l10n.backendChecking), findsNothing);
    expect(Supabase.instance.isInitialized, isTrue);
    expect(Supabase.instance.client.auth.currentSession, isNull);
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-catalog')));
    await tester.pump();

    expect(find.byType(CatalogScreen), findsOneWidget);
    await _waitForCatalog(tester, container);
    final catalogTitle = tester.widget<Text>(
      find.byKey(const ValueKey('shell-title-1')),
    );
    expect(
      catalogTitle.data,
      l10n.catalogTitle,
      reason: 'Il titolo Catalogo appartiene alla shell persistente.',
    );
    expect(find.byKey(const ValueKey('catalog-grid')), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(Supabase.instance.client.auth.currentSession, isNull);
    expect(tester.takeException(), isNull);
    binding.reportData = <String, Object?>{
      'bootstrap': 'PASS',
      'initializingBannerObserved': 'PASS',
      'stagingReadiness': 'ready',
      'catalogNavigation': 'PASS',
      'customerSession': 'absent',
      'googleAuth': 'disabled',
      'dataAccess': 'readiness-plus-home-controller-not-asserted',
      'processAlive': 'PASS',
    };
  });
}

Future<void> _waitForCatalog(
  WidgetTester tester,
  ProviderContainer container,
) async {
  for (var attempt = 0; attempt < 120; attempt += 1) {
    final state = container.read(catalogControllerProvider);
    if (state.status == CatalogLoadStatus.data) return;
    if (state.status != CatalogLoadStatus.loading) {
      fail('Catalogo staging terminato in ${state.status.name}.');
    }
    await tester.pump(const Duration(milliseconds: 250));
  }
  fail('Catalogo staging non ha raggiunto data entro 30 secondi.');
}

Future<void> _waitForReady(
  WidgetTester tester,
  ProviderContainer container,
) async {
  const attempts = 120;

  for (var attempt = 0; attempt < attempts; attempt++) {
    final state = container.read(backendReadinessControllerProvider);
    if (state == BackendReadinessState.ready) {
      return;
    }
    if (state != BackendReadinessState.initializing) {
      fail('La readiness staging è terminata nello stato ${state.name}.');
    }

    final exception = tester.takeException();
    if (exception != null) {
      fail('Eccezione durante il bootstrap staging: $exception');
    }
    await tester.pump(const Duration(milliseconds: 250));
  }

  fail('La readiness staging non ha raggiunto ready entro 30 secondi.');
}
