import 'dart:async';

import 'package:client_merchandise_control/features/delivery_context/domain/delivery_address_ports.dart';
import 'package:client_merchandise_control/features/delivery_context/domain/delivery_context_models.dart';
import 'package:client_merchandise_control/features/delivery_context/presentation/google_address_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  const coordinate = DeliveryCoordinate(latitude: 1, longitude: 1);
  for (final mode in ['false', 'throw', 'timeout', 'logout']) {
    testWidgets('native probe $mode non costruisce la mappa', (tester) async {
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(navigatorKey: key, home: const Scaffold()),
      );
      final pending = Completer<bool>();
      var current = true;
      final port = GoogleAddressMapPort(
        navigatorKey: key,
        enabled: true,
        isCurrent: () => current,
        probeTimeout: const Duration(milliseconds: 10),
        nativeConfigurationProbe: () {
          if (mode == 'throw') throw StateError('fixture');
          if (mode == 'false') return Future.value(false);
          return pending.future;
        },
      );
      final result = expectLater(
        port.previewAndAdjust(coordinate),
        throwsA(
          mode == 'logout'
              ? isA<AddressMapCancelledException>()
              : isA<AddressProviderNotConfiguredException>(),
        ),
      );
      if (mode == 'logout') {
        current = false;
        pending.complete(true);
      }
      await tester.pump(const Duration(milliseconds: 11));
      await result;
      expect(find.byType(GoogleMap), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      if (mode == 'timeout') pending.complete(true);
      await tester.pump();
      expect(find.byType(GoogleMap), findsNothing);
    });
  }
}
