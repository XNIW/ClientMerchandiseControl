import 'dart:convert';

import 'package:client_merchandise_control/features/checkout/data/shared_preferences_checkout_draft_store.dart';
import 'package:client_merchandise_control/features/checkout/domain/checkout_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _ownerA = '10000000-0000-4000-8000-000000000001';
const _ownerB = '10000000-0000-4000-8000-000000000002';
const _quoteId = '54000000-0000-4000-8000-000000000001';
const _key = '56000000-0000-4000-8000-000000000001';
const _pointId = '51000000-0000-4000-8000-000000000001';
const _slotId = '53000000-0000-4000-8000-000000000001';
final _now = DateTime.utc(2026, 10, 12, 12);

void main() {
  late _Preferences preferences;
  late SharedPreferencesCheckoutDraftStore store;

  setUp(() {
    preferences = _Preferences();
    store = SharedPreferencesCheckoutDraftStore(preferences: preferences);
  });

  test('A-B-A dopo riavvio conserva identico intent ordine ambiguo', () async {
    await store.save(_pendingOrder());
    await store.save(_pendingOrder(owner: _ownerB));
    final restarted = SharedPreferencesCheckoutDraftStore(
      preferences: preferences,
    );

    final restored = await restarted.read(
      ownerSubjectId: _ownerA,
      shopSlug: 'storefront-test',
    );
    expect(
      restored?.pendingOperation?.kind,
      CheckoutPendingOperationKind.order,
    );
    expect(restored?.pendingOperation?.idempotencyKey, _key);
    expect(restored?.pendingOperation?.cartVersion, 7);
    expect(restored?.pendingOperation?.quoteId, _quoteId);
    expect(restored?.pendingOperation?.expectedQuoteVersion, 2);
    expect(
      restored?.pendingOperation?.paymentMethod,
      CheckoutPaymentMethod.payAtPickup,
    );
    expect(restored?.updatedAt, _now);
    expect(
      (await restarted.read(
        ownerSubjectId: _ownerB,
        shopSlug: 'storefront-test',
      ))?.ownerSubjectId,
      _ownerB,
    );
  });

  test(
    'cambio shop e clear del secondo non cancellano pending del primo',
    () async {
      await store.save(_pendingOrder());
      await store.save(_pendingOrder(shop: 'storefront-other'));
      await store.clear(ownerSubjectId: _ownerA, shopSlug: 'storefront-other');
      final restarted = SharedPreferencesCheckoutDraftStore(
        preferences: preferences,
      );

      expect(
        (await restarted.read(
          ownerSubjectId: _ownerA,
          shopSlug: 'storefront-test',
        ))?.pendingOperation?.idempotencyKey,
        _key,
      );
      expect(
        await restarted.read(
          ownerSubjectId: _ownerA,
          shopSlug: 'storefront-other',
        ),
        isNull,
      );
    },
  );

  test(
    'clear di B preserva ordine ambiguo di A e ultimo clear rimuove key',
    () async {
      await store.save(_pendingOrder());
      await store.save(_pendingOrder(owner: _ownerB));
      await store.clear(ownerSubjectId: _ownerB, shopSlug: 'storefront-test');
      expect(
        (await store.read(
          ownerSubjectId: _ownerA,
          shopSlug: 'storefront-test',
        ))?.pendingOperation?.idempotencyKey,
        _key,
      );
      await store.clear(ownerSubjectId: _ownerA, shopSlug: 'storefront-test');
      expect(preferences.values, isEmpty);
    },
  );

  test(
    'legacy v4 migra atomicamente senza cambiare chiave idempotente',
    () async {
      preferences.values[SharedPreferencesCheckoutDraftStore.storageKey] =
          _legacyOrder();
      final restored = await store.read(
        ownerSubjectId: _ownerA,
        shopSlug: 'storefront-test',
      );

      expect(restored?.pendingOperation?.idempotencyKey, _key);
      final encoded = preferences.values.values.single;
      expect(jsonDecode(encoded)['version'], 5);
      final restarted = SharedPreferencesCheckoutDraftStore(
        preferences: preferences,
      );
      await restarted.save(_pendingOrder(owner: _ownerB));
      expect(
        (await restarted.read(
          ownerSubjectId: _ownerA,
          shopSlug: 'storefront-test',
        ))?.pendingOperation?.idempotencyKey,
        _key,
      );
      expect(encoded, isNot(contains('addressLine1')));
      expect(encoded, isNot(contains('priceClp')));
      expect(encoded, isNot(contains('totalClp')));
    },
  );

  test(
    'errore scrittura migrazione conserva byte legacy e retry recupera',
    () async {
      final legacy = _legacyOrder();
      preferences.values[SharedPreferencesCheckoutDraftStore.storageKey] =
          legacy;
      preferences.failNextWrite = true;

      await expectLater(
        store.read(ownerSubjectId: _ownerA, shopSlug: 'storefront-test'),
        throwsStateError,
      );
      expect(
        preferences.values[SharedPreferencesCheckoutDraftStore.storageKey],
        legacy,
      );
      expect(
        (await store.read(
          ownerSubjectId: _ownerA,
          shopSlug: 'storefront-test',
        ))?.pendingOperation?.idempotencyKey,
        _key,
      );
    },
  );

  test(
    'errore salvataggio B non sostituisce il legacy pendente di A',
    () async {
      final legacy = _legacyOrder();
      preferences.values[SharedPreferencesCheckoutDraftStore.storageKey] =
          legacy;
      preferences.failNextWrite = true;

      await expectLater(
        store.save(_pendingOrder(owner: _ownerB)),
        throwsStateError,
      );
      expect(
        preferences.values[SharedPreferencesCheckoutDraftStore.storageKey],
        legacy,
      );
      await store.save(_pendingOrder(owner: _ownerB));
      expect(
        (await store.read(
          ownerSubjectId: _ownerA,
          shopSlug: 'storefront-test',
        ))?.pendingOperation?.idempotencyKey,
        _key,
      );
    },
  );

  test(
    'limite16 scope fallisce prima di espellere o inviare nuovi intenti',
    () async {
      for (var index = 0; index < 16; index++) {
        await store.save(_pendingOrder(shop: 'storefront-scope-$index'));
      }
      final before = preferences.values.values.single;
      await expectLater(
        store.save(_pendingOrder(shop: 'storefront-scope-16')),
        throwsStateError,
      );
      expect(preferences.values.values.single, before);
      for (var index = 0; index < 16; index++) {
        expect(
          (await store.read(
            ownerSubjectId: _ownerA,
            shopSlug: 'storefront-scope-$index',
          ))?.pendingOperation?.idempotencyKey,
          _key,
        );
      }
    },
  );

  test(
    'salvataggi concorrenti sullo store conservano entrambi gli scope',
    () async {
      await Future.wait([
        store.save(_pendingOrder()),
        store.save(_pendingOrder(owner: _ownerB)),
      ]);
      expect(
        (await store.read(
          ownerSubjectId: _ownerA,
          shopSlug: 'storefront-test',
        ))?.ownerSubjectId,
        _ownerA,
      );
      expect(
        (await store.read(
          ownerSubjectId: _ownerB,
          shopSlug: 'storefront-test',
        ))?.ownerSubjectId,
        _ownerB,
      );
    },
  );

  test(
    'envelope corrotto non viene cancellato né sovrascritto da altro account',
    () async {
      final corrupt = jsonEncode({
        'version': 5,
        'drafts': [
          jsonDecode(_legacyOrder()),
          {'version': 4, 'totalClp': 1},
        ],
      });
      preferences.values[SharedPreferencesCheckoutDraftStore.storageKey] =
          corrupt;

      expect(
        await store.read(ownerSubjectId: _ownerA, shopSlug: 'storefront-test'),
        isNull,
      );
      await expectLater(
        store.save(_pendingOrder(owner: _ownerB)),
        throwsFormatException,
      );
      await expectLater(
        store.clear(ownerSubjectId: _ownerB, shopSlug: 'storefront-test'),
        throwsFormatException,
      );
      expect(preferences.values.values.single, corrupt);
    },
  );

  test('scope duplicato o envelope oltre limite non viene riscritto', () async {
    for (final entries in [
      [jsonDecode(_legacyOrder()), jsonDecode(_legacyOrder())],
      [for (var index = 0; index < 17; index++) jsonDecode(_legacyOrder())],
    ]) {
      final invalid = jsonEncode({'version': 5, 'drafts': entries});
      preferences.values[SharedPreferencesCheckoutDraftStore.storageKey] =
          invalid;
      expect(
        await store.read(ownerSubjectId: _ownerA, shopSlug: 'storefront-test'),
        isNull,
      );
      await expectLater(store.save(_pendingOrder()), throwsFormatException);
      expect(preferences.values.values.single, invalid);
    }
  });
}

CheckoutLocalDraft _pendingOrder({
  String owner = _ownerA,
  String shop = 'storefront-test',
}) => CheckoutLocalDraft(
  ownerSubjectId: owner,
  shopSlug: shop,
  step: CheckoutStep.confirmation,
  selection: const CheckoutSelection(
    mode: CheckoutFulfillmentMode.pickup,
    pickupPointId: _pointId,
    slotId: _slotId,
    paymentMethod: CheckoutPaymentMethod.payAtPickup,
  ),
  quoteId: _quoteId,
  pendingOperation: const CheckoutPendingOperation(
    kind: CheckoutPendingOperationKind.order,
    idempotencyKey: _key,
    cartVersion: 7,
    quoteId: _quoteId,
    expectedQuoteVersion: 2,
    paymentMethod: CheckoutPaymentMethod.payAtPickup,
  ),
  updatedAt: _now,
);

String _legacyOrder() => jsonEncode({
  'version': 4,
  'ownerSubjectId': _ownerA,
  'shopSlug': 'storefront-test',
  'step': 'confirmation',
  'selection': {
    'mode': 'pickup',
    'addressId': null,
    'pickupPointId': _pointId,
    'slotId': _slotId,
    'paymentMethod': 'payAtPickup',
    'deliveryContextVersion': null,
  },
  'quoteId': _quoteId,
  'orderId': null,
  'pendingOperation': {
    'kind': 'order',
    'idempotencyKey': _key,
    'cartVersion': 7,
    'quoteId': _quoteId,
    'expectedQuoteVersion': 2,
    'paymentMethod': 'payAtPickup',
  },
  'updatedAt': _now.toIso8601String(),
});

final class _Preferences implements CheckoutDraftPreferences {
  final Map<String, String> values = {};
  var failNextWrite = false;

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('fixture_write_failed');
    }
    values[key] = value;
  }
}
