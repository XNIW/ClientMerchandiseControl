import 'dart:convert';

import 'package:client_merchandise_control/features/reservations/data/shared_preferences_reservation_hold_store.dart';
import 'package:client_merchandise_control/features/reservations/domain/reservation_hold_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reservation_hold_test_support.dart';

void main() {
  test(
    'round-trip preserva hold e intenzione idempotente per owner/shop',
    () async {
      final preferences = _MemoryPreferences();
      final store = SharedPreferencesReservationHoldStore(
        preferences: preferences,
      );
      final entry = reservationEntry(
        hold: reservationSnapshot(),
        pending: const ReservationHoldPendingOperation(
          kind: ReservationHoldPendingOperationKind.release,
          idempotencyKey: reservationTestKey,
        ),
      );

      await store.saveEntry(entry);
      final restored = await store.readEntry(
        ownerSubjectId: reservationTestOwner,
        shopSlug: reservationTestShop,
        publicationId: reservationTestPublication,
      );

      expect(restored?.hold?.holdId, reservationTestHold);
      expect(
        restored?.pendingOperation?.kind,
        ReservationHoldPendingOperationKind.release,
      );
      expect(restored?.pendingOperation?.idempotencyKey, reservationTestKey);
      final encoded = preferences.value!;
      expect(encoded, isNot(contains('source_product_id')));
      expect(encoded, isNot(contains('stock_quantity')));
      expect(encoded, isNot(contains('token')));
    },
  );

  test(
    'owner differente non può leggere le entry locali dell altro account',
    () async {
      final store = SharedPreferencesReservationHoldStore(
        preferences: _MemoryPreferences(),
      );
      await store.saveEntry(reservationEntry(hold: reservationSnapshot()));

      final other = await store.readContext(
        ownerSubjectId: reservationSecondOwner,
        shopSlug: reservationTestShop,
      );

      expect(other, isEmpty);
    },
  );

  test(
    'payload corrotto fallisce chiuso e viene sostituito con store vuoto',
    () async {
      final preferences = _MemoryPreferences(
        jsonEncode({
          'version': 1,
          'entries': [
            {'ownerSubjectId': reservationTestOwner, 'unexpected': 'secret'},
          ],
        }),
      );
      final store = SharedPreferencesReservationHoldStore(
        preferences: preferences,
      );

      final result = await store.readContext(
        ownerSubjectId: reservationTestOwner,
        shopSlug: reservationTestShop,
      );

      expect(result, isEmpty);
      expect(jsonDecode(preferences.value!), {'version': 1, 'entries': []});
    },
  );

  test('pruning mantiene al massimo 25 entry e non elimina la nuova', () async {
    final preferences = _MemoryPreferences();
    final store = SharedPreferencesReservationHoldStore(
      preferences: preferences,
    );
    for (var index = 0; index < 26; index++) {
      final suffix = index.toString().padLeft(12, '0');
      final publication = '50000000-0000-4000-8000-$suffix';
      final holdId = '70000000-0000-4000-8000-$suffix';
      await store.saveEntry(
        ReservationHoldLocalEntry(
          ownerSubjectId: reservationTestOwner,
          shopSlug: reservationTestShop,
          publicationId: publication,
          quantity: 1,
          hold: reservationSnapshot(
            holdId: holdId,
            publicationId: publication,
            quantity: 1,
            status: ReservationHoldServerStatus.released,
          ),
          updatedAt: reservationTestServerTime.add(Duration(seconds: index)),
        ),
      );
    }

    final entries = await store.readContext(
      ownerSubjectId: reservationTestOwner,
      shopSlug: reservationTestShop,
    );
    expect(entries, hasLength(reservationHoldMaximumEntriesPerContext));
    expect(
      entries.any(
        (entry) =>
            entry.publicationId == '50000000-0000-4000-8000-000000000025',
      ),
      isTrue,
    );
  });
}

final class _MemoryPreferences implements ReservationHoldPreferences {
  _MemoryPreferences([this.value]);

  String? value;

  @override
  Future<String?> getString(String key) async => value;

  @override
  Future<void> setString(String key, String value) async {
    this.value = value;
  }
}
