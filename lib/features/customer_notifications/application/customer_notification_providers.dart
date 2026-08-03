import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/domain/authenticated_customer.dart';
import '../data/supabase_customer_notification_repository.dart';
import '../domain/customer_notification_repository.dart';

final customerNotificationIdentityProvider = Provider<AuthenticatedCustomer?>(
  (ref) => switch (ref.watch(authControllerProvider)) {
    AuthAuthenticated(:final customer) => customer,
    _ => null,
  },
);

final customerNotificationRepositoryProvider =
    Provider<CustomerNotificationRepository>((ref) {
      return SupabaseCustomerNotificationRepository(
        port: PlatformCustomerNotificationPort(Supabase.instance.client),
      );
    });
