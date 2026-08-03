import 'dart:async';

import 'package:client_merchandise_control/features/reservations/data/supabase_reservation_hold_repository.dart';
import 'package:client_merchandise_control/features/reservations/domain/reservation_hold_failure.dart';
import 'package:client_merchandise_control/features/reservations/domain/reservation_hold_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reservation_hold_test_support.dart';

void main() {
  test(
    'create invia solo parametri pubblici e interpreta il contratto v1',
    () async {
      final port = _FakePort(_activePayload());
      final repository = SupabaseReservationHoldRepository(port);

      final response = await repository.create(
        shopSlug: reservationTestShop,
        publicationId: reservationTestPublication,
        quantity: 2,
        idempotencyKey: reservationTestKey,
      );

      expect(port.calls, hasLength(1));
      expect(port.calls.single.function, 'customer_reservation_hold_create_v1');
      expect(
        port.calls.single.parameters,
        containsPair('p_shop_slug', reservationTestShop),
      );
      expect(
        port.calls.single.parameters,
        containsPair('p_publication_id', reservationTestPublication),
      );
      expect(port.calls.single.parameters, containsPair('p_quantity', 2));
      expect(
        port.calls.single.parameters,
        containsPair('p_idempotency_key', reservationTestKey),
      );
      expect(port.calls.single.parameters, hasLength(4));
      expect(response.status, ReservationHoldRemoteStatus.ok);
      expect(response.hold?.holdId, reservationTestHold);
      expect(response.hold?.remainingSeconds, 600);
      expect(response.hold?.isActive, isTrue);
    },
  );

  test(
    'read e release usano identificatori opachi e mappano terminale',
    () async {
      final released = _activePayload()
        ..['status'] = 'terminal'
        ..['holdStatus'] = 'released'
        ..['terminalAt'] = reservationTestServerTime.toIso8601String()
        ..['remainingSeconds'] = 0;
      final port = _QueuePort([_activePayload(), released]);
      final repository = SupabaseReservationHoldRepository(port);

      final read = await repository.read(holdId: reservationTestHold);
      final release = await repository.release(
        holdId: reservationTestHold,
        idempotencyKey: reservationSecondKey,
      );

      expect(read.hold?.status, ReservationHoldServerStatus.active);
      expect(release.hold?.status, ReservationHoldServerStatus.released);
      expect(port.calls[0].function, 'customer_reservation_hold_read_v1');
      expect(port.calls[1].function, 'customer_reservation_hold_release_v1');
    },
  );

  test('rifiuta qualsiasi campo interno o shape non allow-listed', () async {
    final payload = _activePayload()..['sourceProductId'] = reservationTestHold;
    final repository = SupabaseReservationHoldRepository(_FakePort(payload));

    await expectLater(
      repository.read(holdId: reservationTestHold),
      throwsA(
        isA<ReservationHoldRepositoryException>().having(
          (error) => error.kind,
          'kind',
          ReservationHoldFailureKind.unexpected,
        ),
      ),
    );
  });

  test('risposta business minimale non può includere dettagli stock', () async {
    final payload = <String, Object?>{
      'apiVersion': 'customer-reservation-hold.v1',
      'status': 'unavailable',
      'idempotent': false,
      'serverTime': reservationTestServerTime.toIso8601String(),
      'stockQuantity': 1,
    };
    final repository = SupabaseReservationHoldRepository(_FakePort(payload));

    await expectLater(
      repository.create(
        shopSlug: reservationTestShop,
        publicationId: reservationTestPublication,
        quantity: 2,
        idempotencyKey: reservationTestKey,
      ),
      throwsA(
        isA<ReservationHoldRepositoryException>().having(
          (error) => error.kind,
          'kind',
          ReservationHoldFailureKind.unexpected,
        ),
      ),
    );
  });

  test('timeout è distinto e non viene trasformato in successo', () async {
    final port = _PendingPort();
    final repository = SupabaseReservationHoldRepository(
      port,
      requestTimeout: const Duration(milliseconds: 1),
    );

    await expectLater(
      repository.read(holdId: reservationTestHold),
      throwsA(
        isA<ReservationHoldRepositoryException>().having(
          (error) => error.kind,
          'kind',
          ReservationHoldFailureKind.timeout,
        ),
      ),
    );
  });

  test('input invalido fallisce chiuso prima del port', () async {
    final port = _FakePort(_activePayload());
    final repository = SupabaseReservationHoldRepository(port);

    await expectLater(
      repository.create(
        shopSlug: 'INVALID SHOP',
        publicationId: reservationTestPublication,
        quantity: 100,
        idempotencyKey: reservationTestKey,
      ),
      throwsA(isA<ReservationHoldRepositoryException>()),
    );
    expect(port.calls, isEmpty);
  });
}

Map<String, Object?> _activePayload() => <String, Object?>{
  'apiVersion': 'customer-reservation-hold.v1',
  'status': 'ok',
  'idempotent': false,
  'holdId': reservationTestHold,
  'shopSlug': reservationTestShop,
  'publicationId': reservationTestPublication,
  'quantity': 2,
  'holdStatus': 'active',
  'expiresAt': reservationTestServerTime
      .add(const Duration(minutes: 15))
      .toIso8601String(),
  'serverTime': reservationTestServerTime.toIso8601String(),
  'remainingSeconds': 600,
};

final class _FakePort implements ReservationHoldPort {
  _FakePort(this.response);

  final Object? response;
  final List<({String function, Map<String, Object?> parameters})> calls = [];

  @override
  Future<Object?> invoke(
    String function,
    Map<String, Object?> parameters,
  ) async {
    calls.add((function: function, parameters: parameters));
    return response;
  }
}

final class _QueuePort implements ReservationHoldPort {
  _QueuePort(this.responses);

  final List<Object?> responses;
  final List<({String function, Map<String, Object?> parameters})> calls = [];

  @override
  Future<Object?> invoke(
    String function,
    Map<String, Object?> parameters,
  ) async {
    calls.add((function: function, parameters: parameters));
    return responses.removeAt(0);
  }
}

final class _PendingPort implements ReservationHoldPort {
  @override
  Future<Object?> invoke(String function, Map<String, Object?> parameters) =>
      Completer<Object?>().future;
}
