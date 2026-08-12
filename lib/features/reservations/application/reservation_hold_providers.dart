import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../account/application/customer_account_providers.dart';
import '../data/shared_preferences_reservation_hold_store.dart';
import '../data/supabase_reservation_hold_repository.dart';
import '../domain/reservation_hold_repository.dart';
import 'reservation_hold_coordinator.dart';

final reservationHoldRepositoryProvider = Provider<ReservationHoldRepository>((
  ref,
) {
  return SupabaseReservationHoldRepository(
    PlatformReservationHoldPort(Supabase.instance.client),
  );
});

final reservationHoldLocalStoreProvider = Provider<ReservationHoldLocalStore>((
  ref,
) {
  return SharedPreferencesReservationHoldStore();
});

final reservationHoldClockProvider = Provider<ReservationHoldClock>((ref) {
  return () => DateTime.now().toUtc();
});

final reservationHoldCoordinatorProvider = Provider<ReservationHoldCoordinator>(
  (ref) {
    return ReservationHoldCoordinator(
      ref.watch(reservationHoldRepositoryProvider),
      ref.watch(reservationHoldLocalStoreProvider),
      ref.watch(customerIdempotencyKeyFactoryProvider),
      ref.watch(reservationHoldClockProvider),
    );
  },
);
