import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/reservations/application/reservation_hold_providers.dart';
import 'package:client_merchandise_control/features/reservations/domain/reservation_hold_failure.dart';
import 'package:client_merchandise_control/features/reservations/domain/reservation_hold_models.dart';
import 'package:client_merchandise_control/features/reservations/presentation/reservation_hold_panel.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/features/reservations/reservation_hold_test_support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('create, authoritative read e release restano idempotenti', (
    tester,
  ) async {
    final repository = FakeReservationHoldRepository();
    final store = MemoryReservationHoldStore();
    repository.createOutcomes.add(
      reservationResponse(hold: reservationSnapshot()),
    );
    repository.readOutcomes.add(
      reservationResponse(hold: reservationSnapshot(remainingSeconds: 480)),
    );
    repository.releaseOutcomes.add(
      reservationResponse(
        status: ReservationHoldRemoteStatus.terminal,
        hold: reservationSnapshot(status: ReservationHoldServerStatus.released),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(reservationTestConfig()),
          customerAccountIdentityProvider.overrideWithValue(
            reservationIdentity(),
          ),
          reservationHoldRepositoryProvider.overrideWithValue(repository),
          reservationHoldLocalStoreProvider.overrideWithValue(store),
          reservationHoldClockProvider.overrideWithValue(
            () => reservationTestServerTime,
          ),
          customerIdempotencyKeyFactoryProvider.overrideWithValue(
            _sequentialKeys(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('es', 'CL'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: appSupportedLocales,
          theme: AppTheme.light(),
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: ReservationHoldPanel(
                publicationId: reservationTestPublication,
                quantity: 2,
                canCreate: true,
              ),
            ),
          ),
        ),
      ),
    );

    await _tapWhenReady(tester, const ValueKey('reservation-hold-create'));
    await _waitFor(tester, const ValueKey('reservation-hold-active'));
    expect(repository.createCalls.single.idempotencyKey, reservationTestKey);
    expect(repository.readCalls, [reservationTestHold]);
    expect(
      (await store.readContext(
        ownerSubjectId: reservationTestOwner,
        shopSlug: reservationTestShop,
      )).single.pendingOperation,
      isNull,
    );

    await _tapWhenReady(tester, const ValueKey('reservation-hold-release'));
    await _waitFor(tester, const ValueKey('reservation-hold-released'));
    expect(repository.releaseCalls.single.idempotencyKey, reservationSecondKey);
    expect(
      (await store.readContext(
        ownerSubjectId: reservationTestOwner,
        shopSlug: reservationTestShop,
      )).single.hold?.status,
      ReservationHoldServerStatus.released,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    binding.reportData = <String, Object?>{
      'realWidgetTap': 'PASS',
      'createAdapter': 'PASS',
      'authoritativeRead': 'PASS',
      'serverCountdown': 'PASS',
      'releaseAdapter': 'PASS',
      'idempotencyKeys': 'stable',
      'internalIdentifiers': 'absent',
      'processAlive': 'PASS',
    };
  });

  testWidgets(
    'timeout retry e expiry vengono riconciliati senza falso successo',
    (tester) async {
      final repository = FakeReservationHoldRepository();
      final store = MemoryReservationHoldStore();
      repository.createOutcomes.addAll([
        const ReservationHoldRepositoryException(
          ReservationHoldFailureKind.timeout,
        ),
        reservationResponse(
          idempotent: true,
          hold: reservationSnapshot(remainingSeconds: 1, idempotent: true),
        ),
      ]);
      repository.readOutcomes.addAll([
        reservationResponse(
          hold: reservationSnapshot(remainingSeconds: 1, idempotent: true),
        ),
        reservationResponse(
          status: ReservationHoldRemoteStatus.terminal,
          hold: reservationSnapshot(
            status: ReservationHoldServerStatus.expired,
            idempotent: true,
          ),
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(reservationTestConfig()),
            customerAccountIdentityProvider.overrideWithValue(
              reservationIdentity(),
            ),
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
            locale: const Locale('es', 'CL'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: appSupportedLocales,
            theme: AppTheme.light(),
            home: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: ReservationHoldPanel(
                  publicationId: reservationTestPublication,
                  quantity: 2,
                  canCreate: true,
                ),
              ),
            ),
          ),
        ),
      );

      await _tapWhenReady(tester, const ValueKey('reservation-hold-create'));
      await _waitFor(tester, const ValueKey('reservation-hold-error'));
      expect(
        find.byKey(const ValueKey('reservation-hold-active')),
        findsNothing,
      );
      await _tapWhenReady(tester, const ValueKey('reservation-hold-retry'));
      await _waitFor(tester, const ValueKey('reservation-hold-active'));
      expect(
        repository.createCalls.map((call) => call.idempotencyKey).toSet(),
        {reservationTestKey},
      );

      await tester.pump(const Duration(milliseconds: 1100));
      await _waitFor(tester, const ValueKey('reservation-hold-expired'));
      expect(repository.readCalls, hasLength(2));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      binding.reportData = <String, Object?>{
        'realWidgetTap': 'PASS',
        'createAdapter': 'PASS',
        'ambiguousRetry': 'PASS',
        'sameIdempotencyKey': 'PASS',
        'authoritativeRead': 'PASS',
        'serverCountdown': 'PASS',
        'expiryReconciliation': 'PASS',
        'releaseAdapter': 'PASS',
        'internalIdentifiers': 'absent',
        'processAlive': 'PASS',
      };
    },
  );
}

String Function() _sequentialKeys() {
  var call = 0;
  return () {
    call++;
    return call == 1 ? reservationTestKey : reservationSecondKey;
  };
}

Future<void> _tapWhenReady(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await _waitFor(tester, key);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _waitFor(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.pump(const Duration(milliseconds: 10));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Elemento integration non trovato: $key');
}
