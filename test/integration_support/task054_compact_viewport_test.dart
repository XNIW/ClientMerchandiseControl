import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/compact_viewport.dart';

void main() {
  // Geometria sintetica dichiarata: questi numeri non sono metriche IME iOS.
  final cases = [
    (
      name: 'intersezione tastiera con riquadro centrato',
      parent: const Size(400, 900),
      insets: const EdgeInsets.only(bottom: 300),
      viewPadding: const EdgeInsets.fromLTRB(30, 44, 16, 34),
      padding: const EdgeInsets.fromLTRB(30, 44, 16, 0),
      rect: const Rect.fromLTWH(40, 166, 320, 568),
      localInsets: const EdgeInsets.only(bottom: 134),
      localViewPadding: EdgeInsets.zero,
      localPadding: EdgeInsets.zero,
    ),
    (
      name: 'finestra compatta conserva tutto il suo inset',
      parent: const Size(320, 568),
      insets: const EdgeInsets.only(bottom: 300),
      viewPadding: const EdgeInsets.fromLTRB(30, 44, 16, 34),
      padding: const EdgeInsets.fromLTRB(30, 44, 16, 0),
      rect: const Rect.fromLTWH(0, 0, 320, 568),
      localInsets: const EdgeInsets.only(bottom: 300),
      localViewPadding: const EdgeInsets.fromLTRB(30, 44, 16, 34),
      localPadding: const EdgeInsets.fromLTRB(30, 44, 16, 0),
    ),
    (
      name: 'contrafattuale centrato conserva intersezione inset forte',
      parent: const Size(400, 900),
      insets: const EdgeInsets.only(bottom: 397),
      viewPadding: const EdgeInsets.fromLTRB(30, 44, 16, 34),
      padding: const EdgeInsets.fromLTRB(30, 44, 16, 0),
      rect: const Rect.fromLTWH(40, 166, 320, 568),
      localInsets: const EdgeInsets.only(bottom: 231),
      localViewPadding: EdgeInsets.zero,
      localPadding: EdgeInsets.zero,
    ),
    (
      name: 'stress fullscreen conserva anche inset forte non misurato',
      parent: const Size(320, 568),
      insets: const EdgeInsets.only(bottom: 397),
      viewPadding: const EdgeInsets.fromLTRB(30, 44, 16, 34),
      padding: const EdgeInsets.fromLTRB(30, 44, 16, 0),
      rect: const Rect.fromLTWH(0, 0, 320, 568),
      localInsets: const EdgeInsets.only(bottom: 397),
      localViewPadding: const EdgeInsets.fromLTRB(30, 44, 16, 34),
      localPadding: const EdgeInsets.fromLTRB(30, 44, 16, 0),
    ),
    (
      name: 'safe zone parziali proiettate sui quattro bordi',
      parent: const Size(360, 600),
      insets: const EdgeInsets.only(bottom: 80),
      viewPadding: const EdgeInsets.fromLTRB(30, 44, 26, 34),
      padding: const EdgeInsets.fromLTRB(30, 44, 26, 0),
      rect: const Rect.fromLTWH(20, 16, 320, 568),
      localInsets: const EdgeInsets.only(bottom: 64),
      localViewPadding: const EdgeInsets.fromLTRB(10, 28, 6, 18),
      localPadding: const EdgeInsets.fromLTRB(10, 28, 6, 0),
    ),
    (
      name: 'occlusione totale non inventa spazio utilizzabile',
      parent: const Size(400, 900),
      insets: const EdgeInsets.only(bottom: 800),
      viewPadding: const EdgeInsets.fromLTRB(30, 44, 16, 34),
      padding: const EdgeInsets.fromLTRB(30, 44, 16, 0),
      rect: const Rect.fromLTWH(40, 166, 320, 568),
      localInsets: const EdgeInsets.only(bottom: 568),
      localViewPadding: EdgeInsets.zero,
      localPadding: EdgeInsets.zero,
    ),
    (
      name: 'tastiera esterna al riquadro non lo occlude',
      parent: const Size(400, 900),
      insets: const EdgeInsets.only(bottom: 100),
      viewPadding: const EdgeInsets.fromLTRB(30, 44, 16, 34),
      padding: const EdgeInsets.fromLTRB(30, 44, 16, 0),
      rect: const Rect.fromLTWH(40, 166, 320, 568),
      localInsets: EdgeInsets.zero,
      localViewPadding: EdgeInsets.zero,
      localPadding: EdgeInsets.zero,
    ),
    (
      name: 'finestra minore usa la dimensione fisica disponibile',
      parent: const Size(280, 500),
      insets: const EdgeInsets.only(bottom: 220),
      viewPadding: const EdgeInsets.only(top: 20, bottom: 34),
      padding: const EdgeInsets.only(top: 20),
      rect: const Rect.fromLTWH(0, 0, 280, 500),
      localInsets: const EdgeInsets.only(bottom: 220),
      localViewPadding: const EdgeInsets.only(top: 20, bottom: 34),
      localPadding: const EdgeInsets.only(top: 20),
    ),
  ];
  for (final scenario in cases) {
    testWidgets(scenario.name, (tester) async {
      tester.view.physicalSize = scenario.parent;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      MediaQueryData? local;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: scenario.parent,
            devicePixelRatio: 1,
            viewInsets: scenario.insets,
            viewPadding: scenario.viewPadding,
            padding: scenario.padding,
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Task054CompactViewport(
              child: Builder(
                builder: (context) {
                  local = MediaQuery.of(context);
                  return const SizedBox.expand(
                    key: ValueKey('compact-child-probe'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const ValueKey('compact-child-probe'))),
        scenario.rect,
      );
      expect(local!.size, scenario.rect.size);
      expect(local!.viewInsets, scenario.localInsets);
      expect(local!.viewPadding, scenario.localViewPadding);
      expect(local!.padding, scenario.localPadding);
      expect(local!.textScaler.scale(12), 24);
      expect(tester.takeException(), isNull);
    });
  }
}
