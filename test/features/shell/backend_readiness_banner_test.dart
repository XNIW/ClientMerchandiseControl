import 'dart:async';

import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
import 'package:client_merchandise_control/core/backend/backend_health_service.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_repository.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const callback = AppConfig.allowedAuthRedirectUri;
  final stagingConfig = AppConfig.fromValues(
    appEnvironment: 'staging',
    supabaseUrl: 'https://project.example.invalid',
    supabasePublishableKey: 'sb_publishable_test_key',
    authRedirectUri: callback,
    googleAuthEnabled: 'false',
  );

  Widget buildApp({
    required BackendReadinessRepository repository,
    Locale locale = const Locale('es'),
  }) {
    return ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(stagingConfig),
        backendReadinessRepositoryProvider.overrideWithValue(repository),
      ],
      child: ClientMerchandiseControlApp(locale: locale),
    );
  }

  testWidgets('mostra stato checking senza bloccare la Home', (tester) async {
    final repository = _BannerRepository(
      initialState: BackendReadinessState.initializing,
    );

    await tester.pumpWidget(buildApp(repository: repository));
    await tester.pump();

    expect(find.text('Comprobando la conexión de la tienda…'), findsOneWidget);
    expect(
      find.text('Pronto podrás descubrir aquí las novedades de la tienda.'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('offline offre retry manuale single-flight', (tester) async {
    final repository = _BannerRepository(
      initialState: BackendReadinessState.offline,
    );

    await tester.pumpWidget(buildApp(repository: repository));
    await tester.pump();

    const message =
        'Sin conexión. Puedes seguir explorando y volver a intentarlo.';
    expect(find.text(message), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == message,
      ),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();

    expect(repository.calls, 1);
    expect(find.text('Comprobando la conexión de la tienda…'), findsOneWidget);

    repository.completeNext(BackendReadinessState.ready);
    await tester.pumpAndSettle();

    expect(find.text(message), findsNothing);
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('misconfigured non espone dettagli o valori', (tester) async {
    final repository = _BannerRepository(
      initialState: BackendReadinessState.misconfigured,
      canCheck: false,
    );

    await tester.pumpWidget(buildApp(repository: repository));
    await tester.pumpAndSettle();

    expect(
      find.text('La tienda no está disponible por el momento.'),
      findsOneWidget,
    );
    expect(find.textContaining('project.example.invalid'), findsNothing);
    expect(find.textContaining('sb_publishable_'), findsNothing);
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('authenticationRequired usa copy cliente sicura', (tester) async {
    final repository = _BannerRepository(
      initialState: BackendReadinessState.authenticationRequired,
      canCheck: false,
    );

    await tester.pumpWidget(buildApp(repository: repository));
    await tester.pumpAndSettle();

    expect(
      find.text('Inicia sesión desde Cuenta para continuar.'),
      findsOneWidget,
    );
    expect(
      find.text('Pronto podrás descubrir aquí las novedades de la tienda.'),
      findsOneWidget,
    );
  });

  testWidgets('localizza offline e retry nei quattro locale', (tester) async {
    final cases = <Locale, ({String message, String retry})>{
      const Locale('es'): (
        message:
            'Sin conexión. Puedes seguir explorando y volver a intentarlo.',
        retry: 'Reintentar',
      ),
      const Locale('it'): (
        message:
            'Connessione assente. Puoi continuare a esplorare e riprovare.',
        retry: 'Riprova',
      ),
      const Locale('en'): (
        message: "You're offline. You can keep browsing and try again.",
        retry: 'Try again',
      ),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'): (
        message: '当前无网络连接。你可以继续浏览并重试。',
        retry: '重试',
      ),
    };

    for (final entry in cases.entries) {
      await tester.pumpWidget(
        buildApp(
          repository: _BannerRepository(
            initialState: BackendReadinessState.offline,
          ),
          locale: entry.key,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(entry.value.message), findsOneWidget);
      expect(find.text(entry.value.retry), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('offline resta usabile a 320x568 e testo 200%', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.binding.setSurfaceSize(const Size(320, 568));

    await tester.pumpWidget(
      buildApp(
        repository: _BannerRepository(
          initialState: BackendReadinessState.offline,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final retrySize = tester.getSize(
      find.widgetWithText(TextButton, 'Reintentar'),
    );
    expect(retrySize.height, greaterThanOrEqualTo(48));
    expect(tester, meetsGuideline(labeledTapTargetGuideline));
  });
}

final class _BannerRepository implements BackendReadinessRepository {
  _BannerRepository({required this.initialState, this.canCheck = true});

  @override
  final BackendReadinessState initialState;

  @override
  final bool canCheck;

  final List<Completer<BackendReadinessState>> _results = [];

  int get calls => _results.length;

  @override
  Future<BackendReadinessState> check({
    required BackendProbeCancellation cancellation,
  }) {
    final result = Completer<BackendReadinessState>();
    _results.add(result);
    return result.future;
  }

  void completeNext(BackendReadinessState state) {
    _results.firstWhere((result) => !result.isCompleted).complete(state);
  }
}
