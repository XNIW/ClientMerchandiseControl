import 'package:flutter/foundation.dart';

import '../domain/customer_device_models.dart';
import '../domain/customer_device_repository.dart';

/// Adapter fail-closed usato finché APNs/FCM non sono configurati nella build.
/// Non genera token fittizi e non dichiara autorizzazioni inesistenti.
final class UnconfiguredPushTokenProvider implements CustomerPushTokenProvider {
  const UnconfiguredPushTokenProvider();

  @override
  CustomerDevicePlatform get platform => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => CustomerDevicePlatform.ios,
    _ => CustomerDevicePlatform.android,
  };

  @override
  Stream<String> get tokenChanges => const Stream<String>.empty();

  @override
  Future<CustomerPushCapability> currentCapability() async {
    return const CustomerPushCapability(
      availability: CustomerPushProviderAvailability.notConfigured,
      permission: CustomerDevicePermissionStatus.notDetermined,
      token: null,
    );
  }

  @override
  Future<CustomerPushCapability> requestAuthorization() => currentCapability();

  @override
  Future<void> revokeLocalToken() async {}
}
