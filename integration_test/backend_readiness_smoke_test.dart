import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/core/config/app_environment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('staging raggiunge Auth health senza bloccare la shell', (
    tester,
  ) async {
    final config = AppConfig.fromEnvironment();
    expect(config.environment, AppEnvironment.staging);
    expect(config.googleAuthEnabled, isFalse);

    final container = ProviderContainer(
      overrides: [appConfigProvider.overrideWithValue(config)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ClientMerchandiseControlApp(locale: Locale('es')),
      ),
    );
    await tester.pump();

    final readiness = container.read(
      backendReadinessControllerProvider.notifier,
    );
    await readiness.retry();
    await tester.pumpAndSettle();

    expect(
      container.read(backendReadinessControllerProvider),
      BackendReadinessState.ready,
    );
    expect(Supabase.instance.isInitialized, isTrue);
    expect(Supabase.instance.client.auth.currentSession, isNull);
    expect(
      find.text('Pronto podrás descubrir aquí las novedades de la tienda.'),
      findsOneWidget,
    );
    expect(find.text('Comprobando la conexión de la tienda…'), findsNothing);
    expect(find.text('Reintentar'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
