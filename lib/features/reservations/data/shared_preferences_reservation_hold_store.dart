import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/reservation_hold_models.dart';
import '../domain/reservation_hold_repository.dart';

abstract interface class ReservationHoldPreferences {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);
}

final class PlatformReservationHoldPreferences
    implements ReservationHoldPreferences {
  PlatformReservationHoldPreferences([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> getString(String key) => _preferences.getString(key);

  @override
  Future<void> setString(String key, String value) {
    return _preferences.setString(key, value);
  }
}

final class SharedPreferencesReservationHoldStore
    implements ReservationHoldLocalStore {
  SharedPreferencesReservationHoldStore({
    ReservationHoldPreferences? preferences,
  }) : _preferences = preferences ?? PlatformReservationHoldPreferences();

  static const storageKey = 'cmc.reservation-holds.v1';
  static const _maximumContexts = 8;

  final ReservationHoldPreferences _preferences;
  Future<void> _tail = Future<void>.value();

  @override
  Future<List<ReservationHoldLocalEntry>> readContext({
    required String ownerSubjectId,
    required String shopSlug,
  }) {
    return _serialized(() async {
      _validateContext(ownerSubjectId, shopSlug);
      final records = await _readAll();
      return List.unmodifiable(
        records.where(
          (entry) =>
              entry.ownerSubjectId == ownerSubjectId &&
              entry.shopSlug == shopSlug,
        ),
      );
    });
  }

  @override
  Future<ReservationHoldLocalEntry?> readEntry({
    required String ownerSubjectId,
    required String shopSlug,
    required String publicationId,
  }) {
    return _serialized(() async {
      _validateContext(ownerSubjectId, shopSlug);
      _requireUuid(publicationId);
      final records = await _readAll();
      return records
          .where(
            (entry) =>
                entry.ownerSubjectId == ownerSubjectId &&
                entry.shopSlug == shopSlug &&
                entry.publicationId == publicationId,
          )
          .firstOrNull;
    });
  }

  @override
  Future<void> saveEntry(ReservationHoldLocalEntry entry) {
    return _serialized(() async {
      _validateEntry(entry);
      final records = await _readAll();
      final index = records.indexWhere(
        (candidate) =>
            candidate.ownerSubjectId == entry.ownerSubjectId &&
            candidate.shopSlug == entry.shopSlug &&
            candidate.publicationId == entry.publicationId,
      );
      if (index < 0) {
        records.add(entry);
      } else {
        records[index] = entry;
      }
      _prune(records, entry);
      await _writeAll(records);
    });
  }

  @override
  Future<void> removeEntry({
    required String ownerSubjectId,
    required String shopSlug,
    required String publicationId,
  }) {
    return _serialized(() async {
      _validateContext(ownerSubjectId, shopSlug);
      _requireUuid(publicationId);
      final records = await _readAll();
      records.removeWhere(
        (entry) =>
            entry.ownerSubjectId == ownerSubjectId &&
            entry.shopSlug == shopSlug &&
            entry.publicationId == publicationId,
      );
      await _writeAll(records);
    });
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final completer = _tail.then((_) => action());
    _tail = completer.then<void>((_) {}, onError: (_, _) {});
    return completer;
  }

  Future<List<ReservationHoldLocalEntry>> _readAll() async {
    final encoded = await _preferences.getString(storageKey);
    if (encoded == null) return <ReservationHoldLocalEntry>[];
    try {
      return _decode(encoded);
    } on Object {
      await _preferences.setString(storageKey, _encode(const []));
      return <ReservationHoldLocalEntry>[];
    }
  }

  Future<void> _writeAll(List<ReservationHoldLocalEntry> records) {
    return _preferences.setString(storageKey, _encode(records));
  }

  void _prune(
    List<ReservationHoldLocalEntry> records,
    ReservationHoldLocalEntry retained,
  ) {
    final contexts = <String>{
      for (final entry in records) '${entry.ownerSubjectId}|${entry.shopSlug}',
    };
    if (contexts.length > _maximumContexts) {
      final contextDates = <String, DateTime>{};
      for (final entry in records) {
        final key = '${entry.ownerSubjectId}|${entry.shopSlug}';
        final previous = contextDates[key];
        if (previous == null || entry.updatedAt.isAfter(previous)) {
          contextDates[key] = entry.updatedAt;
        }
      }
      final retainedKey = '${retained.ownerSubjectId}|${retained.shopSlug}';
      final oldest = contextDates.entries
          .where((entry) => entry.key != retainedKey)
          .reduce(
            (left, right) => left.value.isBefore(right.value) ? left : right,
          )
          .key;
      records.removeWhere(
        (entry) => '${entry.ownerSubjectId}|${entry.shopSlug}' == oldest,
      );
    }
    final contextRecords =
        records
            .where(
              (entry) =>
                  entry.ownerSubjectId == retained.ownerSubjectId &&
                  entry.shopSlug == retained.shopSlug,
            )
            .toList()
          ..sort((left, right) => left.updatedAt.compareTo(right.updatedAt));
    while (contextRecords.length > reservationHoldMaximumEntriesPerContext) {
      final removable = contextRecords.indexWhere(
        (entry) =>
            entry.pendingOperation == null && entry.hold?.isTerminal == true,
      );
      if (removable < 0) {
        throw const FormatException('reservation_hold_local_limit');
      }
      final removed = contextRecords.removeAt(removable);
      records.remove(removed);
    }
  }
}

String _encode(List<ReservationHoldLocalEntry> records) {
  for (final entry in records) {
    _validateEntry(entry);
  }
  final ordered = [...records]
    ..sort((left, right) {
      final owner = left.ownerSubjectId.compareTo(right.ownerSubjectId);
      if (owner != 0) return owner;
      final shop = left.shopSlug.compareTo(right.shopSlug);
      if (shop != 0) return shop;
      return left.publicationId.compareTo(right.publicationId);
    });
  return jsonEncode(<String, Object>{
    'version': 1,
    'entries': ordered.map(_encodeEntry).toList(growable: false),
  });
}

List<ReservationHoldLocalEntry> _decode(String encoded) {
  final decoded = jsonDecode(encoded);
  if (decoded is! Map) throw const FormatException('reservation_hold_local');
  final root = decoded.map((key, value) => MapEntry(key.toString(), value));
  if (root.length != 2 || root['version'] != 1 || root['entries'] is! List) {
    throw const FormatException('reservation_hold_local_shape');
  }
  final rawEntries = root['entries']! as List;
  if (rawEntries.length > 8 * reservationHoldMaximumEntriesPerContext) {
    throw const FormatException('reservation_hold_local_size');
  }
  final seen = <String>{};
  final entries = rawEntries.map(_decodeEntry).toList();
  for (final entry in entries) {
    final key =
        '${entry.ownerSubjectId}|${entry.shopSlug}|${entry.publicationId}';
    if (!seen.add(key)) {
      throw const FormatException('reservation_hold_local_duplicate');
    }
  }
  return entries;
}

Map<String, Object?> _encodeEntry(ReservationHoldLocalEntry entry) => {
  'ownerSubjectId': entry.ownerSubjectId,
  'shopSlug': entry.shopSlug,
  'publicationId': entry.publicationId,
  'quantity': entry.quantity,
  'hold': entry.hold == null ? null : _encodeHold(entry.hold!),
  'pendingOperation': entry.pendingOperation == null
      ? null
      : {
          'kind': entry.pendingOperation!.kind.name,
          'idempotencyKey': entry.pendingOperation!.idempotencyKey,
        },
  'updatedAt': entry.updatedAt.toUtc().toIso8601String(),
};

ReservationHoldLocalEntry _decodeEntry(Object? raw) {
  final map = _strictMap(raw, const {
    'ownerSubjectId',
    'shopSlug',
    'publicationId',
    'quantity',
    'hold',
    'pendingOperation',
    'updatedAt',
  });
  final owner = _string(map, 'ownerSubjectId');
  final shop = _string(map, 'shopSlug');
  final publication = _string(map, 'publicationId');
  final quantity = _integer(map, 'quantity');
  final updatedAt = _date(map, 'updatedAt');
  final hold = map['hold'] == null ? null : _decodeHold(map['hold']);
  final pending = map['pendingOperation'] == null
      ? null
      : _decodePending(map['pendingOperation']);
  final entry = ReservationHoldLocalEntry(
    ownerSubjectId: owner,
    shopSlug: shop,
    publicationId: publication,
    quantity: quantity,
    hold: hold,
    pendingOperation: pending,
    updatedAt: updatedAt,
  );
  _validateEntry(entry);
  return entry;
}

Map<String, Object?> _encodeHold(ReservationHoldSnapshot hold) => {
  'holdId': hold.holdId,
  'shopSlug': hold.shopSlug,
  'publicationId': hold.publicationId,
  'quantity': hold.quantity,
  'status': hold.status.name,
  'expiresAt': hold.expiresAt.toUtc().toIso8601String(),
  'terminalAt': hold.terminalAt?.toUtc().toIso8601String(),
  'serverTime': hold.serverTime.toUtc().toIso8601String(),
  'remainingSeconds': hold.remainingSeconds,
  'idempotent': hold.idempotent,
};

ReservationHoldSnapshot _decodeHold(Object? raw) {
  final map = _strictMap(raw, const {
    'holdId',
    'shopSlug',
    'publicationId',
    'quantity',
    'status',
    'expiresAt',
    'terminalAt',
    'serverTime',
    'remainingSeconds',
    'idempotent',
  });
  final terminalValue = map['terminalAt'];
  final status = switch (_string(map, 'status')) {
    'active' => ReservationHoldServerStatus.active,
    'released' => ReservationHoldServerStatus.released,
    'expired' => ReservationHoldServerStatus.expired,
    'consumed' => ReservationHoldServerStatus.consumed,
    _ => throw const FormatException('reservation_hold_local_status'),
  };
  final idempotent = map['idempotent'];
  if (idempotent is! bool) {
    throw const FormatException('reservation_hold_local_idempotent');
  }
  return ReservationHoldSnapshot(
    holdId: _string(map, 'holdId'),
    shopSlug: _string(map, 'shopSlug'),
    publicationId: _string(map, 'publicationId'),
    quantity: _integer(map, 'quantity'),
    status: status,
    expiresAt: _date(map, 'expiresAt'),
    terminalAt: terminalValue == null
        ? null
        : DateTime.tryParse(terminalValue as String)?.toUtc(),
    serverTime: _date(map, 'serverTime'),
    remainingSeconds: _integer(map, 'remainingSeconds'),
    idempotent: idempotent,
  );
}

ReservationHoldPendingOperation _decodePending(Object? raw) {
  final map = _strictMap(raw, const {'kind', 'idempotencyKey'});
  final kind = switch (_string(map, 'kind')) {
    'create' => ReservationHoldPendingOperationKind.create,
    'release' => ReservationHoldPendingOperationKind.release,
    _ => throw const FormatException('reservation_hold_local_pending_kind'),
  };
  return ReservationHoldPendingOperation(
    kind: kind,
    idempotencyKey: _string(map, 'idempotencyKey'),
  );
}

Map<String, Object?> _strictMap(Object? raw, Set<String> keys) {
  if (raw is! Map) throw const FormatException('reservation_hold_local_map');
  final map = raw.map((key, value) => MapEntry(key.toString(), value));
  if (map.length != keys.length || map.keys.any((key) => !keys.contains(key))) {
    throw const FormatException('reservation_hold_local_keys');
  }
  return map;
}

String _string(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('reservation_hold_local_$key');
  }
  return value;
}

int _integer(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int) throw FormatException('reservation_hold_local_$key');
  return value;
}

DateTime _date(Map<String, Object?> map, String key) {
  final value = _string(map, key);
  final date = DateTime.tryParse(value)?.toUtc();
  if (date == null) throw FormatException('reservation_hold_local_$key');
  return date;
}

void _validateContext(String ownerSubjectId, String shopSlug) {
  _requireUuid(ownerSubjectId);
  if (!isReservationHoldShopSlug(shopSlug)) {
    throw const FormatException('reservation_hold_local_shop');
  }
}

void _validateEntry(ReservationHoldLocalEntry entry) {
  _validateContext(entry.ownerSubjectId, entry.shopSlug);
  _requireUuid(entry.publicationId);
  if (entry.quantity < 1 ||
      entry.quantity > reservationHoldMaximumQuantity ||
      entry.updatedAt.year < 2020) {
    throw const FormatException('reservation_hold_local_entry');
  }
  final hold = entry.hold;
  final pending = entry.pendingOperation;
  if (hold != null) {
    _requireUuid(hold.holdId);
    _requireUuid(hold.publicationId);
    if (hold.shopSlug != entry.shopSlug ||
        hold.publicationId != entry.publicationId ||
        hold.quantity != entry.quantity ||
        hold.remainingSeconds < 0 ||
        hold.remainingSeconds > 900 ||
        (hold.isActive && hold.terminalAt != null) ||
        (hold.isTerminal && hold.terminalAt == null)) {
      throw const FormatException('reservation_hold_local_hold');
    }
  }
  if (pending != null) {
    _requireUuid(pending.idempotencyKey);
    if (pending.kind == ReservationHoldPendingOperationKind.release &&
        hold == null) {
      throw const FormatException('reservation_hold_local_release');
    }
  }
}

void _requireUuid(String value) {
  if (!isReservationHoldUuid(value)) {
    throw const FormatException('reservation_hold_local_uuid');
  }
}
