import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/checkout_models.dart';
import '../domain/checkout_repository.dart';

abstract interface class CheckoutDraftPreferences {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);

  Future<void> remove(String key);
}

final class PlatformCheckoutDraftPreferences
    implements CheckoutDraftPreferences {
  PlatformCheckoutDraftPreferences([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> getString(String key) => _preferences.getString(key);

  @override
  Future<void> remove(String key) => _preferences.remove(key);

  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);
}

final class SharedPreferencesCheckoutDraftStore implements CheckoutDraftStore {
  SharedPreferencesCheckoutDraftStore({CheckoutDraftPreferences? preferences})
    : _preferences = preferences ?? PlatformCheckoutDraftPreferences();

  static const storageKey = 'cmc.checkout-draft.v1';

  final CheckoutDraftPreferences _preferences;
  Future<void> _tail = Future<void>.value();

  @override
  Future<CheckoutLocalDraft?> read({
    required String ownerSubjectId,
    required String shopSlug,
  }) {
    return _serialized(() async {
      _validateContext(ownerSubjectId, shopSlug);
      final encoded = await _preferences.getString(storageKey);
      if (encoded == null) return null;
      try {
        final draft = _decode(encoded);
        if (draft.ownerSubjectId != ownerSubjectId ||
            draft.shopSlug != shopSlug) {
          return null;
        }
        return draft;
      } on Object {
        await _preferences.remove(storageKey);
        return null;
      }
    });
  }

  @override
  Future<void> save(CheckoutLocalDraft draft) {
    return _serialized(() async {
      _validateDraft(draft);
      await _preferences.setString(storageKey, _encode(draft));
    });
  }

  @override
  Future<void> clear({
    required String ownerSubjectId,
    required String shopSlug,
  }) {
    return _serialized(() async {
      _validateContext(ownerSubjectId, shopSlug);
      final encoded = await _preferences.getString(storageKey);
      if (encoded == null) return;
      try {
        final draft = _decode(encoded);
        if (draft.ownerSubjectId != ownerSubjectId ||
            draft.shopSlug != shopSlug) {
          return;
        }
      } on Object {
        // Un record corrotto non deve sopravvivere al cleanup esplicito.
      }
      await _preferences.remove(storageKey);
    });
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final operation = _tail.then((_) => action());
    _tail = operation.then<void>((_) {}, onError: (_, _) {});
    return operation;
  }
}

String _encode(CheckoutLocalDraft draft) {
  _validateDraft(draft);
  return jsonEncode({
    'version': 3,
    'ownerSubjectId': draft.ownerSubjectId,
    'shopSlug': draft.shopSlug,
    'step': draft.step.name,
    'selection': {
      'mode': draft.selection.mode?.name,
      'addressId': draft.selection.addressId,
      'pickupPointId': draft.selection.pickupPointId,
      'slotId': draft.selection.slotId,
      'paymentMethod': draft.selection.paymentMethod?.name,
    },
    'quoteId': draft.quoteId,
    'orderId': draft.orderId,
    'pendingOperation': draft.pendingOperation == null
        ? null
        : {
            'kind': draft.pendingOperation!.kind.name,
            'idempotencyKey': draft.pendingOperation!.idempotencyKey,
            'cartVersion': draft.pendingOperation!.cartVersion,
            'quoteId': draft.pendingOperation!.quoteId,
            'expectedQuoteVersion':
                draft.pendingOperation!.expectedQuoteVersion,
            'paymentMethod': draft.pendingOperation!.paymentMethod?.name,
          },
    'updatedAt': draft.updatedAt.toUtc().toIso8601String(),
  });
}

CheckoutLocalDraft _decode(String encoded) {
  if (encoded.length > 8192) throw const FormatException('checkout_draft_size');
  final decoded = jsonDecode(encoded);
  if (decoded is! Map) throw const FormatException('checkout_draft_map');
  final version = decoded['version'];
  final root = _strictMap(
    decoded,
    version == 1
        ? const {
            'version',
            'ownerSubjectId',
            'shopSlug',
            'step',
            'selection',
            'quoteId',
            'pendingOperation',
            'updatedAt',
          }
        : const {
            'version',
            'ownerSubjectId',
            'shopSlug',
            'step',
            'selection',
            'quoteId',
            'orderId',
            'pendingOperation',
            'updatedAt',
          },
  );
  if (version != 1 && version != 2 && version != 3) {
    throw const FormatException('checkout_draft_version');
  }
  final selectionMap = _strictMap(
    root['selection'],
    version == 3
        ? const {
            'mode',
            'addressId',
            'pickupPointId',
            'slotId',
            'paymentMethod',
          }
        : const {'mode', 'addressId', 'pickupPointId', 'slotId'},
  );
  final mode = switch (selectionMap['mode']) {
    null => null,
    'pickup' => CheckoutFulfillmentMode.pickup,
    'reservation' => CheckoutFulfillmentMode.reservation,
    'delivery' => CheckoutFulfillmentMode.delivery,
    _ => throw const FormatException('checkout_draft_mode'),
  };
  final pendingRaw = root['pendingOperation'];
  CheckoutPendingOperation? pending;
  if (pendingRaw != null) {
    final map = _strictMap(
      pendingRaw,
      version == 3
          ? const {
              'kind',
              'idempotencyKey',
              'cartVersion',
              'quoteId',
              'expectedQuoteVersion',
              'paymentMethod',
            }
          : const {
              'kind',
              'idempotencyKey',
              'cartVersion',
              'quoteId',
              'expectedQuoteVersion',
            },
    );
    pending = CheckoutPendingOperation(
      kind: switch (map['kind']) {
        'create' => CheckoutPendingOperationKind.create,
        'confirm' => CheckoutPendingOperationKind.confirm,
        'order' => CheckoutPendingOperationKind.order,
        _ => throw const FormatException('checkout_draft_pending_kind'),
      },
      idempotencyKey: _string(map, 'idempotencyKey'),
      cartVersion: _integer(map, 'cartVersion'),
      quoteId: _optionalString(map, 'quoteId'),
      expectedQuoteVersion: _optionalInteger(map, 'expectedQuoteVersion'),
      paymentMethod: version == 3 ? _paymentMethod(map['paymentMethod']) : null,
    );
  }
  final draft = CheckoutLocalDraft(
    ownerSubjectId: _string(root, 'ownerSubjectId'),
    shopSlug: _string(root, 'shopSlug'),
    step: switch (root['step']) {
      'mode' => CheckoutStep.mode,
      'destination' => CheckoutStep.destination,
      'slot' => CheckoutStep.slot,
      'review' => CheckoutStep.review,
      'confirmation' => CheckoutStep.confirmation,
      _ => throw const FormatException('checkout_draft_step'),
    },
    selection: CheckoutSelection(
      mode: mode,
      addressId: _optionalString(selectionMap, 'addressId'),
      pickupPointId: _optionalString(selectionMap, 'pickupPointId'),
      slotId: _optionalString(selectionMap, 'slotId'),
      paymentMethod: version == 3
          ? _paymentMethod(selectionMap['paymentMethod'])
          : null,
    ),
    quoteId: _optionalString(root, 'quoteId'),
    orderId: version >= 2 ? _optionalString(root, 'orderId') : null,
    pendingOperation: pending,
    updatedAt: _date(root, 'updatedAt'),
  );
  _validateDraft(draft);
  return draft;
}

Map<String, Object?> _strictMap(Object? value, Set<String> keys) {
  if (value is! Map) throw const FormatException('checkout_draft_map');
  final map = value.map((key, value) => MapEntry(key.toString(), value));
  if (map.length != keys.length || map.keys.any((key) => !keys.contains(key))) {
    throw const FormatException('checkout_draft_keys');
  }
  return map;
}

String _string(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('checkout_draft_$key');
  }
  return value;
}

String? _optionalString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! String || value.isEmpty) {
    throw FormatException('checkout_draft_$key');
  }
  return value;
}

int _integer(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int) throw FormatException('checkout_draft_$key');
  return value;
}

int? _optionalInteger(Map<String, Object?> map, String key) {
  if (map[key] == null) return null;
  return _integer(map, key);
}

DateTime _date(Map<String, Object?> map, String key) {
  final date = DateTime.tryParse(_string(map, key))?.toUtc();
  if (date == null) throw FormatException('checkout_draft_$key');
  return date;
}

void _validateDraft(CheckoutLocalDraft draft) {
  _validateContext(draft.ownerSubjectId, draft.shopSlug);
  final selection = draft.selection;
  if (selection.addressId != null) _requireUuid(selection.addressId!);
  if (selection.pickupPointId != null) _requireUuid(selection.pickupPointId!);
  if (selection.slotId != null) _requireUuid(selection.slotId!);
  if (draft.quoteId != null) _requireUuid(draft.quoteId!);
  if (draft.orderId != null) _requireUuid(draft.orderId!);
  final pending = draft.pendingOperation;
  if (pending != null) {
    _requireUuid(pending.idempotencyKey);
    if (pending.cartVersion < 0 ||
        (pending.kind == CheckoutPendingOperationKind.create &&
            (pending.quoteId != null ||
                pending.expectedQuoteVersion != null ||
                pending.paymentMethod != null)) ||
        (pending.kind == CheckoutPendingOperationKind.confirm &&
            (pending.quoteId == null ||
                pending.expectedQuoteVersion == null ||
                pending.expectedQuoteVersion! < 1 ||
                pending.paymentMethod != null)) ||
        (pending.kind == CheckoutPendingOperationKind.order &&
            (pending.quoteId == null ||
                pending.expectedQuoteVersion == null ||
                pending.expectedQuoteVersion! < 1 ||
                pending.paymentMethod == null ||
                pending.paymentMethod != selection.paymentMethod))) {
      throw const FormatException('checkout_draft_pending');
    }
    if (pending.quoteId != null) _requireUuid(pending.quoteId!);
  }
  if ((selection.mode == CheckoutFulfillmentMode.delivery &&
          selection.pickupPointId != null) ||
      (selection.mode != null &&
          selection.mode != CheckoutFulfillmentMode.delivery &&
          selection.addressId != null) ||
      (selection.paymentMethod != null && selection.mode == null)) {
    throw const FormatException('checkout_draft_selection');
  }
}

CheckoutPaymentMethod? _paymentMethod(Object? value) => switch (value) {
  null => null,
  'payAtPickup' => CheckoutPaymentMethod.payAtPickup,
  'cashOnDelivery' => CheckoutPaymentMethod.cashOnDelivery,
  'onlinePayment' => CheckoutPaymentMethod.onlinePayment,
  _ => throw const FormatException('checkout_draft_payment_method'),
};

void _validateContext(String ownerSubjectId, String shopSlug) {
  if (ownerSubjectId.isEmpty ||
      ownerSubjectId.length > 256 ||
      ownerSubjectId.runes.any((rune) => rune < 0x20) ||
      !RegExp(r'^[a-z0-9][a-z0-9-]{2,62}$').hasMatch(shopSlug)) {
    throw const FormatException('checkout_draft_context');
  }
}

void _requireUuid(String value) {
  if (!RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(value)) {
    throw const FormatException('checkout_draft_uuid');
  }
}
