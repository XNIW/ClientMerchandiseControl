import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/delivery_tracking/application/delivery_tracking_providers.dart';
import 'package:client_merchandise_control/features/delivery_tracking/data/supabase_delivery_tracking_repository.dart';
import 'package:client_merchandise_control/features/delivery_tracking/domain/delivery_tracking_models.dart';
import 'package:client_merchandise_control/features/orders/presentation/customer_delivery_tracking_eta.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../delivery_tracking/delivery_tracking_test_support.dart';

void main() {
  testWidgets('ETA assente, superata e aggiornata resta server-side', (
    tester,
  ) async {
    var now = trackingTestNow;
    DateTime clock() => now;
    DeliveryTrackingSnapshot snapshot(
      DateTime? start,
      DateTime? end,
      int version,
    ) {
      final payload = trackingLivePayload(version: version)
        ..['etaStartsAt'] = start?.toIso8601String()
        ..['etaEndsAt'] = end?.toIso8601String();
      return parseDeliveryTrackingSnapshot(payload);
    }

    Future<void> pump(
      DeliveryTrackingSnapshot value, {
      bool terminal = false,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [deliveryTrackingClockProvider.overrideWithValue(clock)],
          child: MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('es', 'CL'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CustomerDeliveryTrackingEta(
                snapshot: value,
                timeZone: 'America/Santiago',
                orderTerminal: terminal,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    await pump(snapshot(null, null, 4));
    final l10n = AppLocalizations.of(
      tester.element(find.byType(CustomerDeliveryTrackingEta)),
    );
    expect(find.text(l10n.deliveryTrackingEtaUnavailable), findsOneWidget);
    await pump(
      snapshot(
        now.subtract(const Duration(minutes: 20)),
        now.subtract(const Duration(minutes: 1)),
        5,
      ),
    );
    expect(find.text(l10n.deliveryTrackingEtaExpired), findsOneWidget);
    final end = now.add(const Duration(minutes: 1));
    await pump(snapshot(now.add(const Duration(seconds: 10)), end, 6));
    expect(find.text(l10n.deliveryTrackingEtaExpired), findsNothing);
    expect(find.textContaining('Entrega estimada, no garantizada, entre'), findsOneWidget);
    now = end;
    await tester.pump(const Duration(minutes: 1));
    expect(find.text(l10n.deliveryTrackingEtaExpired), findsOneWidget);
    await pump(
      snapshot(
        now.add(const Duration(minutes: 5)),
        now.add(const Duration(minutes: 20)),
        7,
      ),
    );
    expect(find.text(l10n.deliveryTrackingEtaExpired), findsNothing);
    expect(find.textContaining('Entrega estimada, no garantizada, entre'), findsOneWidget);
    await pump(snapshot(null, null, 8), terminal: true);
    expect(find.byKey(const ValueKey('delivery-tracking-eta')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'ETA non mantiene deadline offstage o in background e riqualifica al resume',
    (tester) async {
      var now = trackingTestNow;
      DateTime clock() => now;
      final payload = trackingLivePayload()
        ..['etaStartsAt'] = now
            .add(const Duration(seconds: 10))
            .toIso8601String()
        ..['etaEndsAt'] = now.add(const Duration(minutes: 1)).toIso8601String();
      final snapshot = parseDeliveryTrackingSnapshot(payload);
      Future<void> pump({
        required bool ticking,
        required bool foreground,
      }) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [deliveryTrackingClockProvider.overrideWithValue(clock)],
            child: MaterialApp(
              locale: const Locale('es', 'CL'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: TickerMode(
                  enabled: ticking,
                  child: CustomerDeliveryTrackingEta(
                    snapshot: snapshot,
                    timeZone: 'America/Santiago',
                    orderTerminal: false,
                    isForeground: foreground,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
      }

      await pump(ticking: true, foreground: true);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(CustomerDeliveryTrackingEta)),
      );
      await pump(ticking: false, foreground: false);
      now = trackingTestNow.add(const Duration(minutes: 1));
      await tester.pump(const Duration(minutes: 1));
      expect(find.text(l10n.deliveryTrackingEtaExpired), findsNothing);
      await pump(ticking: true, foreground: true);
      expect(find.text(l10n.deliveryTrackingEtaExpired), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
