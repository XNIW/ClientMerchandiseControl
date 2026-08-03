import 'dart:ui' as ui;

import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/reservations/application/reservation_hold_providers.dart';
import 'package:client_merchandise_control/features/reservations/domain/reservation_hold_failure.dart';
import 'package:client_merchandise_control/features/reservations/presentation/reservation_hold_panel.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reservation_hold_test_support.dart';

void main() {
  testWidgets('guest vede login ma browsing e rendering non sono bloccati', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        identity: null,
        repository: FakeReservationHoldRepository(),
        store: MemoryReservationHoldStore(),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('reservation-hold-sign-in')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap Reserve raggiunge adapter e mostra countdown autorevole', (
    tester,
  ) async {
    final repository = FakeReservationHoldRepository();
    repository.createOutcomes.add(
      reservationResponse(hold: reservationSnapshot()),
    );
    repository.readOutcomes.add(
      reservationResponse(hold: reservationSnapshot(remainingSeconds: 540)),
    );
    await tester.pumpWidget(
      _buildApp(
        identity: reservationIdentity(),
        repository: repository,
        store: MemoryReservationHoldStore(),
        locale: const Locale('it'),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('reservation-hold-create')),
    );

    await tester.tap(find.byKey(const ValueKey('reservation-hold-create')));
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('reservation-hold-active')),
    );

    expect(repository.createCalls.single.quantity, 2);
    expect(repository.readCalls, [reservationTestHold]);
    expect(find.textContaining('9:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offline non mostra successo e offre retry idempotente', (
    tester,
  ) async {
    final repository = FakeReservationHoldRepository();
    repository.createOutcomes.add(
      const ReservationHoldRepositoryException(
        ReservationHoldFailureKind.offline,
      ),
    );
    final store = MemoryReservationHoldStore();
    await tester.pumpWidget(
      _buildApp(
        identity: reservationIdentity(),
        repository: repository,
        store: store,
      ),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('reservation-hold-create')),
    );
    await tester.tap(find.byKey(const ValueKey('reservation-hold-create')));
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('reservation-hold-error')),
    );

    final context = tester.element(find.byType(ReservationHoldPanel));
    final l10n = AppLocalizations.of(context);
    expect(find.text(l10n.reservationHoldOfflineError), findsOneWidget);
    expect(find.text(l10n.reservationHoldActive), findsNothing);
    expect(
      find.byKey(const ValueKey('reservation-hold-retry')),
      findsOneWidget,
    );
    final pending = await store.readEntry(
      ownerSubjectId: reservationTestOwner,
      shopSlug: reservationTestShop,
      publicationId: reservationTestPublication,
    );
    expect(pending?.pendingOperation?.idempotencyKey, reservationTestKey);
  });

  testWidgets('CTA e release hanno Semantics e target minimo 48', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final repository = FakeReservationHoldRepository();
    repository.createOutcomes.add(
      reservationResponse(hold: reservationSnapshot()),
    );
    repository.readOutcomes.add(
      reservationResponse(hold: reservationSnapshot()),
    );
    await tester.pumpWidget(
      _buildApp(
        identity: reservationIdentity(),
        repository: repository,
        store: MemoryReservationHoldStore(),
      ),
    );
    final create = find.byKey(const ValueKey('reservation-hold-create'));
    await _pumpUntilFound(tester, create);
    expect(tester.getSize(create).height, greaterThanOrEqualTo(48));
    var data = tester.getSemantics(create).getSemanticsData();
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
    expect(data.hasAction(ui.SemanticsAction.tap), isTrue);

    await tester.tap(create);
    final release = find.byKey(const ValueKey('reservation-hold-release'));
    await _pumpUntilFound(tester, release);
    expect(tester.getSize(release).height, greaterThanOrEqualTo(48));
    data = tester.getSemantics(release).getSemanticsData();
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
    semantics.dispose();
  });

  testWidgets('locale, dark, 200% e viewport compatti rifluiscono', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in const [Size(320, 568), Size(568, 320)]) {
      await tester.binding.setSurfaceSize(size);
      for (final locale in appSupportedLocales) {
        await tester.pumpWidget(
          _buildApp(
            identity: reservationIdentity(),
            repository: FakeReservationHoldRepository(),
            store: MemoryReservationHoldStore(),
            locale: locale,
            themeMode: ThemeMode.dark,
          ),
        );
        await _pumpUntilFound(
          tester,
          find.byKey(const ValueKey('reservation-hold-create')),
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('modalità cart non inventa CTA se non esiste una hold', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        identity: reservationIdentity(),
        repository: FakeReservationHoldRepository(),
        store: MemoryReservationHoldStore(),
        canCreate: false,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('reservation-hold-create')), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });
}

Widget _buildApp({
  required AuthenticatedCustomer? identity,
  required FakeReservationHoldRepository repository,
  required MemoryReservationHoldStore store,
  Locale locale = const Locale('es', 'CL'),
  ThemeMode themeMode = ThemeMode.light,
  bool canCreate = true,
}) => ProviderScope(
  overrides: [
    appConfigProvider.overrideWithValue(reservationTestConfig()),
    customerAccountIdentityProvider.overrideWithValue(identity),
    reservationHoldRepositoryProvider.overrideWithValue(repository),
    reservationHoldLocalStoreProvider.overrideWithValue(store),
    reservationHoldClockProvider.overrideWithValue(
      () => reservationTestServerTime,
    ),
    customerIdempotencyKeyFactoryProvider.overrideWithValue(
      () => reservationTestKey,
    ),
  ],
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: appSupportedLocales,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: themeMode,
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ReservationHoldPanel(
          publicationId: reservationTestPublication,
          quantity: 2,
          canCreate: canCreate,
        ),
      ),
    ),
  ),
);

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    await tester.pump(const Duration(milliseconds: 10));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Widget non trovato: $finder');
}
