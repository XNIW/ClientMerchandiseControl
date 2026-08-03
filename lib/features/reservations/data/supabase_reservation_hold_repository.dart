import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/reservation_hold_failure.dart';
import '../domain/reservation_hold_models.dart';
import '../domain/reservation_hold_repository.dart';

abstract interface class ReservationHoldPort {
  Future<Object?> invoke(String function, Map<String, Object?> parameters);
}

final class PlatformReservationHoldPort implements ReservationHoldPort {
  PlatformReservationHoldPort(this._client);

  final SupabaseClient _client;

  @override
  Future<Object?> invoke(String function, Map<String, Object?> parameters) {
    return _client.rpc(function, params: parameters);
  }
}

final class SupabaseReservationHoldRepository
    implements ReservationHoldRepository {
  const SupabaseReservationHoldRepository(
    this._port, {
    this.requestTimeout = const Duration(seconds: 12),
  });

  final ReservationHoldPort _port;
  final Duration requestTimeout;

  @override
  Future<ReservationHoldRemoteResponse> create({
    required String shopSlug,
    required String publicationId,
    required int quantity,
    required String idempotencyKey,
  }) {
    return _guard(() async {
      _requireShopSlug(shopSlug);
      _requireUuid(publicationId);
      _requireQuantity(quantity);
      _requireUuid(idempotencyKey);
      return _parseResponse(
        await _port.invoke('customer_reservation_hold_create_v1', {
          'p_shop_slug': shopSlug,
          'p_publication_id': publicationId,
          'p_quantity': quantity,
          'p_idempotency_key': idempotencyKey,
        }),
      );
    });
  }

  @override
  Future<ReservationHoldRemoteResponse> read({required String holdId}) {
    return _guard(() async {
      _requireUuid(holdId);
      return _parseResponse(
        await _port.invoke('customer_reservation_hold_read_v1', {
          'p_hold_id': holdId,
        }),
      );
    });
  }

  @override
  Future<ReservationHoldRemoteResponse> release({
    required String holdId,
    required String idempotencyKey,
  }) {
    return _guard(() async {
      _requireUuid(holdId);
      _requireUuid(idempotencyKey);
      return _parseResponse(
        await _port.invoke('customer_reservation_hold_release_v1', {
          'p_hold_id': holdId,
          'p_idempotency_key': idempotencyKey,
        }),
      );
    });
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation().timeout(requestTimeout);
    } on ReservationHoldRepositoryException {
      rethrow;
    } on TimeoutException {
      throw const ReservationHoldRepositoryException(
        ReservationHoldFailureKind.timeout,
      );
    } on SocketException {
      throw const ReservationHoldRepositoryException(
        ReservationHoldFailureKind.offline,
      );
    } on AuthException {
      throw const ReservationHoldRepositoryException(
        ReservationHoldFailureKind.unauthorized,
      );
    } on PostgrestException catch (error) {
      throw ReservationHoldRepositoryException(_postgrestFailure(error.code));
    } on FormatException {
      throw const ReservationHoldRepositoryException(
        ReservationHoldFailureKind.unexpected,
      );
    } on Object {
      throw const ReservationHoldRepositoryException(
        ReservationHoldFailureKind.unexpected,
      );
    }
  }
}

const _responseKeys = <String>{
  'apiVersion',
  'status',
  'idempotent',
  'holdId',
  'shopSlug',
  'publicationId',
  'quantity',
  'holdStatus',
  'expiresAt',
  'terminalAt',
  'serverTime',
  'remainingSeconds',
};

ReservationHoldRemoteResponse _parseResponse(Object? raw) {
  final payload = _payload(raw);
  if (payload['apiVersion'] != 'customer-reservation-hold.v1' ||
      payload.keys.any((key) => !_responseKeys.contains(key))) {
    throw const FormatException('reservation_hold_response_shape');
  }
  final status = switch (_requiredString(payload, 'status')) {
    'ok' => ReservationHoldRemoteStatus.ok,
    'active_hold_exists' => ReservationHoldRemoteStatus.activeHoldExists,
    'terminal' => ReservationHoldRemoteStatus.terminal,
    'unavailable' => ReservationHoldRemoteStatus.unavailable,
    'hold_limit_reached' => ReservationHoldRemoteStatus.holdLimitReached,
    'idempotency_conflict' => ReservationHoldRemoteStatus.idempotencyConflict,
    'invalid' => ReservationHoldRemoteStatus.invalid,
    'not_found' => ReservationHoldRemoteStatus.notFound,
    _ => throw const FormatException('reservation_hold_status'),
  };
  final idempotent = payload['idempotent'];
  if (idempotent is! bool) {
    throw const FormatException('reservation_hold_idempotent');
  }
  final serverTime = _requiredDate(payload, 'serverTime');
  final requiresHold = switch (status) {
    ReservationHoldRemoteStatus.ok ||
    ReservationHoldRemoteStatus.activeHoldExists ||
    ReservationHoldRemoteStatus.terminal => true,
    _ => false,
  };
  if (!requiresHold) {
    if (payload.keys.any(
      (key) =>
          key != 'apiVersion' &&
          key != 'status' &&
          key != 'idempotent' &&
          key != 'serverTime',
    )) {
      throw const FormatException('reservation_hold_minimal_response');
    }
    return ReservationHoldRemoteResponse(
      status: status,
      idempotent: idempotent,
      serverTime: serverTime,
    );
  }

  const requiredHoldKeys = {
    'apiVersion',
    'status',
    'idempotent',
    'holdId',
    'shopSlug',
    'publicationId',
    'quantity',
    'holdStatus',
    'expiresAt',
    'serverTime',
    'remainingSeconds',
  };
  if (!payload.keys.toSet().containsAll(requiredHoldKeys)) {
    throw const FormatException('reservation_hold_missing_fields');
  }
  final holdId = _requiredString(payload, 'holdId');
  final shopSlug = _requiredString(payload, 'shopSlug');
  final publicationId = _requiredString(payload, 'publicationId');
  _requirePayloadUuid(holdId);
  _requirePayloadUuid(publicationId);
  _requirePayloadShopSlug(shopSlug);
  final quantity = _requiredInt(payload, 'quantity');
  _requirePayloadQuantity(quantity);
  final holdStatus = switch (_requiredString(payload, 'holdStatus')) {
    'active' => ReservationHoldServerStatus.active,
    'released' => ReservationHoldServerStatus.released,
    'expired' => ReservationHoldServerStatus.expired,
    'consumed' => ReservationHoldServerStatus.consumed,
    _ => throw const FormatException('reservation_hold_server_status'),
  };
  final expiresAt = _requiredDate(payload, 'expiresAt');
  final terminalAt = _optionalDate(payload, 'terminalAt');
  final remainingSeconds = _requiredInt(payload, 'remainingSeconds');
  if (remainingSeconds < 0 || remainingSeconds > 900) {
    throw const FormatException('reservation_hold_remaining');
  }
  if (holdStatus == ReservationHoldServerStatus.active) {
    if (terminalAt != null || !expiresAt.isAfter(serverTime)) {
      throw const FormatException('reservation_hold_active_timing');
    }
  } else if (terminalAt == null || remainingSeconds != 0) {
    throw const FormatException('reservation_hold_terminal_timing');
  }
  final hold = ReservationHoldSnapshot(
    holdId: holdId,
    shopSlug: shopSlug,
    publicationId: publicationId,
    quantity: quantity,
    status: holdStatus,
    expiresAt: expiresAt,
    terminalAt: terminalAt,
    serverTime: serverTime,
    remainingSeconds: remainingSeconds,
    idempotent: idempotent,
  );
  return ReservationHoldRemoteResponse(
    status: status,
    idempotent: idempotent,
    serverTime: serverTime,
    hold: hold,
  );
}

Map<String, Object?> _payload(Object? raw) {
  if (raw is! Map) throw const FormatException('reservation_hold_payload');
  return raw.map((key, value) => MapEntry(key.toString(), value));
}

String _requiredString(Map<String, Object?> payload, String key) {
  final value = payload[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('reservation_hold_$key');
  }
  return value;
}

int _requiredInt(Map<String, Object?> payload, String key) {
  final value = payload[key];
  if (value is! int) throw FormatException('reservation_hold_$key');
  return value;
}

DateTime _requiredDate(Map<String, Object?> payload, String key) {
  final value = _requiredString(payload, key);
  final date = DateTime.tryParse(value)?.toUtc();
  if (date == null) throw FormatException('reservation_hold_$key');
  return date;
}

DateTime? _optionalDate(Map<String, Object?> payload, String key) {
  final value = payload[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('reservation_hold_$key');
  final date = DateTime.tryParse(value)?.toUtc();
  if (date == null) throw FormatException('reservation_hold_$key');
  return date;
}

void _requireShopSlug(String value) {
  if (!isReservationHoldShopSlug(value)) {
    throw const ReservationHoldRepositoryException(
      ReservationHoldFailureKind.invalidInput,
    );
  }
}

void _requireUuid(String value) {
  if (!isReservationHoldUuid(value)) {
    throw const ReservationHoldRepositoryException(
      ReservationHoldFailureKind.invalidInput,
    );
  }
}

void _requireQuantity(int value) {
  if (value < 1 || value > reservationHoldMaximumQuantity) {
    throw const ReservationHoldRepositoryException(
      ReservationHoldFailureKind.invalidInput,
    );
  }
}

void _requirePayloadShopSlug(String value) {
  if (!isReservationHoldShopSlug(value)) {
    throw const FormatException('reservation_hold_shop_slug');
  }
}

void _requirePayloadUuid(String value) {
  if (!isReservationHoldUuid(value)) {
    throw const FormatException('reservation_hold_uuid');
  }
}

void _requirePayloadQuantity(int value) {
  if (value < 1 || value > reservationHoldMaximumQuantity) {
    throw const FormatException('reservation_hold_quantity');
  }
}

ReservationHoldFailureKind _postgrestFailure(String? code) => switch (code) {
  '401' ||
  '403' ||
  '42501' ||
  '28000' => ReservationHoldFailureKind.unauthorized,
  '23505' => ReservationHoldFailureKind.conflict,
  _ => ReservationHoldFailureKind.unexpected,
};
