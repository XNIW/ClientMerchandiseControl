import 'package:client_merchandise_control/features/customer_devices/data/unconfigured_push_token_provider.dart';
import 'package:client_merchandise_control/features/customer_devices/domain/customer_device_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'adapter live fail-closed non genera token o permessi fittizi',
    () async {
      const provider = UnconfiguredPushTokenProvider();

      final current = await provider.currentCapability();
      final requested = await provider.requestAuthorization();

      for (final capability in [current, requested]) {
        expect(
          capability.availability,
          CustomerPushProviderAvailability.notConfigured,
        );
        expect(
          capability.permission,
          CustomerDevicePermissionStatus.notDetermined,
        );
        expect(capability.token, isNull);
      }
      await expectLater(provider.tokenChanges, emitsDone);
      await expectLater(provider.revokeLocalToken(), completes);
    },
  );
}
