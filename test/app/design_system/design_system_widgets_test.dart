import 'package:client_merchandise_control/app/design_system/theme/storefront_semantic_colors.dart';
import 'package:client_merchandise_control/app/design_system/tokens/app_sizes.dart';
import 'package:client_merchandise_control/app/design_system/tokens/app_spacing.dart';
import 'package:client_merchandise_control/app/design_system/widgets/storefront_page.dart';
import 'package:client_merchandise_control/app/design_system/widgets/storefront_status_banner.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StorefrontPage usa padding responsive e max width', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final testCase in [
      (size: const Size(390, 844), padding: AppSpacing.lg),
      (size: const Size(1024, 768), padding: AppSpacing.xxl),
    ]) {
      await tester.binding.setSurfaceSize(testCase.size);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: StorefrontPage(child: SizedBox(width: 200, height: 100)),
          ),
        ),
      );
      await tester.pump();

      final scroll = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      final constrained = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(StorefrontPage),
          matching: find.byType(ConstrainedBox),
        ),
      );

      expect(
        scroll.padding,
        EdgeInsets.symmetric(
          horizontal: testCase.padding,
          vertical: AppSpacing.xl,
        ),
      );
      expect(constrained.constraints.maxWidth, AppSizes.contentMaxWidth);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('status banner consuma i colori semantici iniettati', (
    tester,
  ) async {
    const injectedContainer = Color(0xFF112233);
    const injectedForeground = Color(0xFFF1F2F3);
    final baseTheme = AppTheme.light();
    final baseSemantic = baseTheme.extension<StorefrontSemanticColors>()!;
    final theme = baseTheme.copyWith(
      extensions: [
        baseSemantic.copyWith(
          informationContainer: injectedContainer,
          onInformationContainer: injectedForeground,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: StorefrontStatusBanner(
            message: 'Estado de prueba',
            icon: Icons.info_outline,
          ),
        ),
      ),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(StorefrontStatusBanner),
        matching: find.byType(Material),
      ),
    );
    final text = tester.widget<Text>(find.text('Estado de prueba'));

    expect(material.color, injectedContainer);
    expect(text.style?.color, injectedForeground);
  });

  testWidgets('status banner espone una live region senza icona duplicata', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: StorefrontStatusBanner(
            message: 'Sin conexión',
            icon: Icons.cloud_off_outlined,
          ),
        ),
      ),
    );

    final data = tester.semantics
        .find(find.byType(StorefrontStatusBanner))
        .getSemanticsData();

    expect(data.label, 'Sin conexión');
    expect(data.flagsCollection.isLiveRegion, isTrue);
    expect(data.label, isNot(contains('cloud_off')));
  });

  testWidgets('status banner non overflowa in landscape al 200%', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(568, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: StorefrontStatusBanner(
            message: 'Backend no configurado: modo de desarrollo sin conexión.',
            icon: Icons.cloud_off_outlined,
          ),
        ),
      ),
    );

    expect(find.textContaining('Backend no configurado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
