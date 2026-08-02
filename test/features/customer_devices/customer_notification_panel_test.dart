import 'dart:ui' as ui;

import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/customer_devices/application/customer_device_providers.dart';
import 'package:client_merchandise_control/features/customer_devices/domain/customer_device_failure.dart';
import 'package:client_merchandise_control/features/customer_devices/domain/customer_device_models.dart';
import 'package:client_merchandise_control/features/customer_devices/presentation/customer_notification_panel.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'customer_device_test_support.dart';

void main() {
  testWidgets('provider assente è dichiarato e non abilita una CTA fittizia', (
    tester,
  ) async {
    final pushProvider = FakePushTokenProvider(
      availability: CustomerPushProviderAvailability.notConfigured,
      permission: CustomerDevicePermissionStatus.notDetermined,
      token: null,
    );
    addTearDown(pushProvider.dispose);
    final repository = FakeCustomerDeviceRepository();

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        pushProvider: pushProvider,
        store: MemoryCustomerDeviceStore(),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CustomerNotificationPanel)),
    );
    expect(
      find.text(l10n.customerNotificationsProviderUnavailable),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('customer-notifications-enable')),
          )
          .onPressed,
      isNull,
    );
    expect(repository.registerCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap Enable raggiunge adapter e mostra conferma server', (
    tester,
  ) async {
    final pushProvider = FakePushTokenProvider();
    addTearDown(pushProvider.dispose);
    final repository = FakeCustomerDeviceRepository();

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        pushProvider: pushProvider,
        store: MemoryCustomerDeviceStore(),
        locale: const Locale('it'),
      ),
    );
    await tester.pumpAndSettle();
    final enable = find.byKey(const ValueKey('customer-notifications-enable'));
    await tester.ensureVisible(enable);
    await tester.tap(enable);
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CustomerNotificationPanel)),
    );
    expect(repository.registerCalls, 1);
    expect(repository.registrations.single.locale, 'it');
    expect(find.text(l10n.customerNotificationsActive), findsOneWidget);
    expect(
      find.byKey(const ValueKey('customer-notifications-revoke')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('offline non mostra successo e retry usa stessa intenzione', (
    tester,
  ) async {
    final pushProvider = FakePushTokenProvider();
    addTearDown(pushProvider.dispose);
    final repository = FakeCustomerDeviceRepository();
    final store = MemoryCustomerDeviceStore();
    repository.registerError = const CustomerDeviceRepositoryException(
      CustomerDeviceFailureKind.offline,
    );

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        pushProvider: pushProvider,
        store: store,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('customer-notifications-enable')),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CustomerNotificationPanel)),
    );
    expect(find.text(l10n.customerNotificationsOffline), findsOneWidget);
    expect(find.text(l10n.customerNotificationsActive), findsNothing);
    expect(store.record.pendingOperation?.idempotencyKey, testDeviceKey);

    repository.registerError = null;
    await tester.tap(
      find.byKey(const ValueKey('customer-notifications-retry')),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.customerNotificationsActive), findsOneWidget);
    expect(repository.registerCalls, 2);
  });

  testWidgets('azioni hanno Semantics e target minimo 48', (tester) async {
    final semantics = tester.ensureSemantics();
    final pushProvider = FakePushTokenProvider();
    addTearDown(pushProvider.dispose);
    await tester.pumpWidget(
      _buildApp(
        repository: FakeCustomerDeviceRepository(),
        pushProvider: pushProvider,
        store: MemoryCustomerDeviceStore(),
      ),
    );
    await tester.pumpAndSettle();

    for (final key in const [
      ValueKey('customer-notifications-not-now'),
      ValueKey('customer-notifications-enable'),
    ]) {
      final finder = find.byKey(key);
      await tester.ensureVisible(finder);
      final size = tester.getSize(finder);
      expect(size.height, greaterThanOrEqualTo(48), reason: key.toString());
      final data = tester.getSemantics(finder).getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
      expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
    }
    semantics.dispose();
  });

  testWidgets('quattro locale, dark, 200% e portrait/landscape rifluiscono', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in const [Size(320, 568), Size(568, 320)]) {
      await tester.binding.setSurfaceSize(size);
      for (final locale in appSupportedLocales) {
        final pushProvider = FakePushTokenProvider();
        await tester.pumpWidget(
          _buildApp(
            repository: FakeCustomerDeviceRepository(),
            pushProvider: pushProvider,
            store: MemoryCustomerDeviceStore(),
            locale: locale,
            themeMode: ThemeMode.dark,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('customer-notifications-panel')),
          findsOneWidget,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${size.width}x${size.height} ${locale.toLanguageTag()}',
        );
        await pushProvider.dispose();
      }
    }
  });
}

Widget _buildApp({
  required FakeCustomerDeviceRepository repository,
  required FakePushTokenProvider pushProvider,
  required MemoryCustomerDeviceStore store,
  Locale locale = const Locale('es', 'CL'),
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    overrides: [
      customerDeviceIdentityProvider.overrideWithValue(_identity()),
      customerDeviceRepositoryProvider.overrideWithValue(repository),
      customerDeviceLocalStoreProvider.overrideWithValue(store),
      customerPushTokenProvider.overrideWithValue(pushProvider),
      customerDeviceUuidFactoryProvider.overrideWithValue(() => testDeviceKey),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: appSupportedLocales,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: CustomerNotificationPanel(),
        ),
      ),
    ),
  );
}

AuthenticatedCustomer _identity() {
  return AuthenticatedCustomer.fromUntrustedIdentity(
    subjectId: testDeviceOwner,
    email: 'customer@example.invalid',
    metadata: const {'name': 'Cliente'},
  );
}
