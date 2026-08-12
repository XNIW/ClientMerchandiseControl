import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/domain/authenticated_customer.dart';
import '../data/supabase_customer_account_repository.dart';
import '../domain/customer_account_repository.dart';

typedef CustomerIdempotencyKeyFactory = String Function();

final customerAccountIdentityProvider = Provider<AuthenticatedCustomer?>((ref) {
  return switch (ref.watch(authControllerProvider)) {
    AuthAuthenticated(:final customer) => customer,
    _ => null,
  };
});

final customerAccountRepositoryProvider = Provider<CustomerAccountRepository>((
  ref,
) {
  return SupabaseCustomerAccountRepository(
    port: PlatformCustomerAccountPort(Supabase.instance.client),
  );
});

final customerIdempotencyKeyFactoryProvider =
    Provider<CustomerIdempotencyKeyFactory>((ref) {
      final random = Random.secure();
      return () {
        final bytes = List<int>.generate(16, (_) => random.nextInt(256));
        bytes[6] = (bytes[6] & 0x0f) | 0x40;
        bytes[8] = (bytes[8] & 0x3f) | 0x80;
        final hex = bytes
            .map((value) => value.toRadixString(16).padLeft(2, '0'))
            .join();
        return '${hex.substring(0, 8)}-'
            '${hex.substring(8, 12)}-'
            '${hex.substring(12, 16)}-'
            '${hex.substring(16, 20)}-'
            '${hex.substring(20)}';
      };
    });
