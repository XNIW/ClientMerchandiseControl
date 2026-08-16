import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/client_merchandise_control_app.dart';
import 'core/config/app_config.dart';
import 'core/observability/observability_event.dart';
import 'core/observability/observability_providers.dart';
import 'core/time/app_scheduler.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/customer_devices/application/customer_device_providers.dart';
import 'features/orders/application/customer_order_providers.dart';
import 'features/reservations/application/reservation_hold_providers.dart';
import 'features/reservations/domain/reservation_hold_models.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  DateTime clock() => DateTime.now().toUtc();
  final observability = defaultObservability(
    environment: config.environment,
    clock: clock,
  );
  ObservabilityCrashBoundary.install(observability);
  observability.record(
    ObservabilityEvent.appStart(occurredAt: clock(), kind: AppStartKind.cold),
  );

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        appClockProvider.overrideWithValue(clock),
        observabilityProvider.overrideWithValue(observability),
        authenticatedSignOutCleanupProvider.overrideWith((ref) {
          return (customer) async {
            Object? firstError;
            StackTrace? firstStackTrace;
            final shopSlug = ref.read(appConfigProvider).storefrontShopSlug;
            if (shopSlug != null && isReservationHoldShopSlug(shopSlug)) {
              try {
                await ref
                    .read(reservationHoldCoordinatorProvider)
                    .prepareForSignOut(
                      ownerSubjectId: customer.subjectId,
                      shopSlug: shopSlug,
                    );
              } on Object catch (error, stackTrace) {
                firstError = error;
                firstStackTrace = stackTrace;
              }
            }
            if (shopSlug != null) {
              try {
                await ref
                    .read(customerOrderCacheStoreProvider)
                    .clear(
                      ownerSubjectId: customer.subjectId,
                      shopSlug: shopSlug,
                    );
              } on Object catch (error, stackTrace) {
                firstError ??= error;
                firstStackTrace ??= stackTrace;
              }
            }
            try {
              await ref
                  .read(customerDeviceSignOutCoordinatorProvider)
                  .prepareForSignOut(customer.subjectId);
            } on Object catch (error, stackTrace) {
              firstError ??= error;
              firstStackTrace ??= stackTrace;
            }
            if (firstError case final error?) {
              Error.throwWithStackTrace(error, firstStackTrace!);
            }
          };
        }),
      ],
      child: ObservabilityLifecycle(
        observability: observability,
        clock: clock,
        child: const ClientMerchandiseControlApp(),
      ),
    ),
  );
}
