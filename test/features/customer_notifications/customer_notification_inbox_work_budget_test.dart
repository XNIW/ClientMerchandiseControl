import 'dart:collection';

import 'package:client_merchandise_control/features/customer_notifications/application/customer_notification_inbox_controller.dart';
import 'package:client_merchandise_control/features/customer_notifications/presentation/customer_notification_inbox_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'customer_notification_screen_test_support.dart';

void main() {
  testWidgets(
    'inbox molte pagine: lavoro widget limitato al viewport',
    (tester) async {
      // Budget definito prima del fix, non un budget di latenza su telefono:
      // 20 tile coprono oltre due viewport 390x844 con le righe correnti (>=96px)
      // e la cache del viewport. Da 25 a 500 notifiche: crescita <= 2x.
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final measurements = <int, List<({int configurations, int builds})>>{};
      for (final count in [25, 500]) {
        final repository = PagedInboxTestRepository(totalItems: count);
        final container = inboxTestContainer(repository);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: inboxTestApp(const CustomerNotificationInboxScreen()),
          ),
        );
        await tester.pumpAndSettle();
        final controller = container.read(
          customerNotificationInboxControllerProvider.notifier,
        );
        while (container
            .read(customerNotificationInboxControllerProvider)
            .hasMore) {
          await controller.loadMore();
          await tester.pumpAndSettle();
        }
        expect(repository.listCalls, hasLength(count ~/ 25));
        expect(
          container.read(customerNotificationInboxControllerProvider).items,
          hasLength(count),
        );
        final samples = <({int configurations, int builds})>[];
        final previousObserver = debugOnRebuildDirtyWidget;
        try {
          for (var sample = 0; sample < 5; sample++) {
            var builds = 0;
            debugOnRebuildDirtyWidget = (element, builtOnce) {
              previousObserver?.call(element, builtOnce);
              if (_isTile(element.widget)) builds++;
            };
            // Dataset interamente unread: commutare il filtro genera un rebuild
            // senza cambiare righe, viewport o richieste.
            controller.selectUnreadOnly(sample.isEven);
            await tester.pumpAndSettle();
            samples.add((
              configurations: _tileConfigurations(tester),
              builds: builds,
            ));
          }
        } finally {
          debugOnRebuildDirtyWidget = previousObserver;
        }
        measurements[count] = samples;
        debugPrint(
          'INBOX_WORK rows=$count samples=$samples requests=${repository.listCalls.length}',
        );
        expect(repository.listCalls, hasLength(count ~/ 25));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
      }
      for (final sample in measurements[500]!) {
        expect(sample.configurations, lessThanOrEqualTo(20));
        expect(sample.builds, lessThanOrEqualTo(20));
      }
      expect(
        measurements[500]!
            .map((sample) => sample.configurations)
            .reduce((a, b) => a > b ? a : b),
        lessThanOrEqualTo(measurements[25]!.first.configurations * 2),
      );
    },
    tags: const ['performance'],
  );
}

bool _isTile(Widget widget) =>
    widget.runtimeType.toString() == '_NotificationTile';

int _tileConfigurations(WidgetTester tester) {
  // Conta configurazioni di riga trattenute dal delegate oltre a quelle montate.
  // ListView(children:) dispone già i render object in modo lazy, ma conserva
  // anche i widget creati eager da visibleItems.map fuori viewport.
  final tiles = HashSet<Widget>.identity();
  for (final widget in tester.allWidgets) {
    if (_isTile(widget)) tiles.add(widget);
    if (widget is SliverMultiBoxAdaptorWidget) {
      final delegate = widget.delegate;
      if (delegate is SliverChildListDelegate) {
        tiles.addAll(delegate.children.where(_isTile));
      }
    }
  }
  return tiles.length;
}
