import 'dart:async';

import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/reservations/domain/reservation_hold_models.dart';
import 'package:client_merchandise_control/features/reservations/domain/reservation_hold_repository.dart';

const reservationTestOwner = '10000000-0000-4000-8000-000000000001';
const reservationSecondOwner = '10000000-0000-4000-8000-000000000002';
const reservationTestPublication = '50000000-0000-4000-8000-000000000001';
const reservationSecondPublication = '50000000-0000-4000-8000-000000000002';
const reservationTestHold = '70000000-0000-4000-8000-000000000001';
const reservationTestKey = '60000000-0000-4000-8000-000000000001';
const reservationSecondKey = '60000000-0000-4000-8000-000000000002';
const reservationTestShop = 'storefront-test';

final reservationTestServerTime = DateTime.utc(2026, 8, 3, 12);

AppConfig reservationTestConfig() => AppConfig.fromValues(
  appEnvironment: 'staging',
  supabaseUrl: 'https://staging.example.invalid',
  supabasePublishableKey: 'sb_publishable_staging',
  authRedirectUri: AppConfig.allowedAuthRedirectUri,
  googleAuthEnabled: 'false',
  storefrontShopSlug: reservationTestShop,
);

AuthenticatedCustomer reservationIdentity([
  String subjectId = reservationTestOwner,
]) => AuthenticatedCustomer.fromUntrustedIdentity(
  subjectId: subjectId,
  email: 'customer@example.invalid',
  metadata: const {'name': 'Cliente'},
);

ReservationHoldSnapshot reservationSnapshot({
  String holdId = reservationTestHold,
  String publicationId = reservationTestPublication,
  int quantity = 2,
  ReservationHoldServerStatus status = ReservationHoldServerStatus.active,
  int remainingSeconds = 600,
  bool idempotent = false,
}) {
  final terminal = status != ReservationHoldServerStatus.active;
  return ReservationHoldSnapshot(
    holdId: holdId,
    shopSlug: reservationTestShop,
    publicationId: publicationId,
    quantity: quantity,
    status: status,
    expiresAt: reservationTestServerTime.add(const Duration(minutes: 15)),
    terminalAt: terminal ? reservationTestServerTime : null,
    serverTime: reservationTestServerTime,
    remainingSeconds: terminal ? 0 : remainingSeconds,
    idempotent: idempotent,
  );
}

ReservationHoldRemoteResponse reservationResponse({
  ReservationHoldRemoteStatus status = ReservationHoldRemoteStatus.ok,
  ReservationHoldSnapshot? hold,
  bool idempotent = false,
}) => ReservationHoldRemoteResponse(
  status: status,
  idempotent: idempotent,
  serverTime: reservationTestServerTime,
  hold: hold,
);

ReservationHoldLocalEntry reservationEntry({
  String ownerSubjectId = reservationTestOwner,
  String publicationId = reservationTestPublication,
  int quantity = 2,
  ReservationHoldSnapshot? hold,
  ReservationHoldPendingOperation? pending,
}) => ReservationHoldLocalEntry(
  ownerSubjectId: ownerSubjectId,
  shopSlug: reservationTestShop,
  publicationId: publicationId,
  quantity: quantity,
  hold: hold,
  pendingOperation: pending,
  updatedAt: reservationTestServerTime,
);

final class MemoryReservationHoldStore implements ReservationHoldLocalStore {
  final Map<String, ReservationHoldLocalEntry> entries = {};

  String _key(String owner, String shop, String publication) =>
      '$owner|$shop|$publication';

  @override
  Future<List<ReservationHoldLocalEntry>> readContext({
    required String ownerSubjectId,
    required String shopSlug,
  }) async => entries.values
      .where(
        (entry) =>
            entry.ownerSubjectId == ownerSubjectId &&
            entry.shopSlug == shopSlug,
      )
      .toList(growable: false);

  @override
  Future<ReservationHoldLocalEntry?> readEntry({
    required String ownerSubjectId,
    required String shopSlug,
    required String publicationId,
  }) async => entries[_key(ownerSubjectId, shopSlug, publicationId)];

  @override
  Future<void> removeEntry({
    required String ownerSubjectId,
    required String shopSlug,
    required String publicationId,
  }) async {
    entries.remove(_key(ownerSubjectId, shopSlug, publicationId));
  }

  @override
  Future<void> saveEntry(ReservationHoldLocalEntry entry) async {
    entries[_key(entry.ownerSubjectId, entry.shopSlug, entry.publicationId)] =
        entry;
  }
}

final class FakeReservationHoldRepository implements ReservationHoldRepository {
  final List<Object> createOutcomes = [];
  final List<Object> readOutcomes = [];
  final List<Object> releaseOutcomes = [];
  final List<
    ({
      String shopSlug,
      String publicationId,
      int quantity,
      String idempotencyKey,
    })
  >
  createCalls = [];
  final List<String> readCalls = [];
  final List<({String holdId, String idempotencyKey})> releaseCalls = [];

  @override
  Future<ReservationHoldRemoteResponse> create({
    required String shopSlug,
    required String publicationId,
    required int quantity,
    required String idempotencyKey,
  }) async {
    createCalls.add((
      shopSlug: shopSlug,
      publicationId: publicationId,
      quantity: quantity,
      idempotencyKey: idempotencyKey,
    ));
    return _next(createOutcomes);
  }

  @override
  Future<ReservationHoldRemoteResponse> read({required String holdId}) async {
    readCalls.add(holdId);
    return _next(readOutcomes);
  }

  @override
  Future<ReservationHoldRemoteResponse> release({
    required String holdId,
    required String idempotencyKey,
  }) async {
    releaseCalls.add((holdId: holdId, idempotencyKey: idempotencyKey));
    return _next(releaseOutcomes);
  }

  Future<ReservationHoldRemoteResponse> _next(List<Object> outcomes) async {
    if (outcomes.isEmpty) throw StateError('missing reservation fake outcome');
    final outcome = outcomes.removeAt(0);
    if (outcome is Exception) throw outcome;
    if (outcome is Future<ReservationHoldRemoteResponse>) return outcome;
    return outcome as ReservationHoldRemoteResponse;
  }
}
