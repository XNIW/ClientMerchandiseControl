import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/client_merchandise_control_app.dart';
import 'core/config/app_config.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/customer_devices/application/customer_device_providers.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        authenticatedSignOutCleanupProvider.overrideWith((ref) {
          return (customer) => ref
              .read(customerDeviceSignOutCoordinatorProvider)
              .prepareForSignOut(customer.subjectId);
        }),
      ],
      child: const ClientMerchandiseControlApp(),
    ),
  );
}
