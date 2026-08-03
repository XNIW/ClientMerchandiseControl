import 'package:client_merchandise_control/features/checkout/data/shared_preferences_checkout_draft_store.dart';
import 'package:client_merchandise_control/features/checkout/domain/checkout_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _owner = '10000000-0000-4000-8000-000000000001';
const _pointId = '51000000-0000-4000-8000-000000000001';
const _slotId = '53000000-0000-4000-8000-000000000001';
const _quoteId = '54000000-0000-4000-8000-000000000001';
const _key = '56000000-0000-4000-8000-000000000001';
final _now = DateTime.utc(2026, 8, 3, 3);

void main() {
  late _MemoryPreferences preferences;
  late SharedPreferencesCheckoutDraftStore store;

  setUp(() {
    preferences = _MemoryPreferences();
    store = SharedPreferencesCheckoutDraftStore(preferences: preferences);
  });

  test('persistenza conserva solo IDs pubblici e intent idempotente', () async {
    await store.save(_draft());

    final restored = await store.read(
      ownerSubjectId: _owner,
      shopSlug: 'storefront-test',
    );

    expect(restored?.step, CheckoutStep.confirmation);
    expect(restored?.selection.mode, CheckoutFulfillmentMode.pickup);
    expect(restored?.selection.pickupPointId, _pointId);
    expect(restored?.quoteId, _quoteId);
    expect(restored?.pendingOperation?.idempotencyKey, _key);
    final encoded = preferences.values.values.single;
    expect(encoded, isNot(contains('source_product_id')));
    expect(encoded, isNot(contains('priceClp')));
    expect(encoded, isNot(contains('totalClp')));
    expect(encoded, isNot(contains('addressLine1')));
  });

  test('account o shop diverso non eredita il checkout', () async {
    await store.save(_draft());

    expect(
      await store.read(
        ownerSubjectId: '10000000-0000-4000-8000-000000000002',
        shopSlug: 'storefront-test',
      ),
      isNull,
    );
    expect(
      await store.read(ownerSubjectId: _owner, shopSlug: 'storefront-other'),
      isNull,
    );
  });

  test('record corrotto viene rimosso e non provoca crash', () async {
    preferences.values[SharedPreferencesCheckoutDraftStore.storageKey] =
        '{"version":1,"totalClp":1}';

    expect(
      await store.read(ownerSubjectId: _owner, shopSlug: 'storefront-test'),
      isNull,
    );
    expect(preferences.values, isEmpty);
  });

  test('clear è scoped e serializzato', () async {
    await store.save(_draft());
    await store.clear(ownerSubjectId: _owner, shopSlug: 'storefront-other');
    expect(preferences.values, isNotEmpty);

    await store.clear(ownerSubjectId: _owner, shopSlug: 'storefront-test');
    expect(preferences.values, isEmpty);
  });

  test('draft invalido fallisce chiuso senza sovrascrivere', () async {
    await expectLater(
      store.save(
        CheckoutLocalDraft(
          ownerSubjectId: _owner,
          shopSlug: 'storefront-test',
          step: CheckoutStep.review,
          selection: const CheckoutSelection(
            mode: CheckoutFulfillmentMode.delivery,
            pickupPointId: _pointId,
          ),
          quoteId: null,
          pendingOperation: null,
          updatedAt: _now,
        ),
      ),
      throwsFormatException,
    );
    expect(preferences.values, isEmpty);
  });
}

CheckoutLocalDraft _draft() => CheckoutLocalDraft(
  ownerSubjectId: _owner,
  shopSlug: 'storefront-test',
  step: CheckoutStep.confirmation,
  selection: const CheckoutSelection(
    mode: CheckoutFulfillmentMode.pickup,
    pickupPointId: _pointId,
    slotId: _slotId,
  ),
  quoteId: _quoteId,
  pendingOperation: const CheckoutPendingOperation(
    kind: CheckoutPendingOperationKind.confirm,
    idempotencyKey: _key,
    cartVersion: 7,
    quoteId: _quoteId,
    expectedQuoteVersion: 2,
  ),
  updatedAt: _now,
);

final class _MemoryPreferences implements CheckoutDraftPreferences {
  final Map<String, String> values = {};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}
