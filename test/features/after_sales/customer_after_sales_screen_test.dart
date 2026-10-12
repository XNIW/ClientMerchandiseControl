import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_merchandise_control/features/after_sales/application/customer_after_sales_controller.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/after_sales/presentation/customer_after_sales_screen.dart';
import 'package:client_merchandise_control/features/after_sales/domain/customer_after_sales_models.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/commerce_surface_fixtures.dart';
import '../../support/client_host_visual_fonts.dart';

void main() {
  setUpAll(loadClientHostVisualFonts);
  for (final locale in const [
    Locale('es', 'CL'),
    Locale('it'),
    Locale('en'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ]) {
    for (final dark in [false, true]) {
      testWidgets(
        'recupero allegati leggibile compact200 ${locale.toLanguageTag()} dark=$dark',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 568));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final semantics = tester.ensureSemantics();
          try {
            final fixture = Task054VisualFixtures();
            await tester.pumpWidget(
              fixture.wrap(
                MaterialApp(
                  theme: clientHostVisualTheme(dark ? AppTheme.dark() : AppTheme.light()),
                  locale: locale,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: const TextScaler.linear(2)),
                    child: RepaintBoundary(
                      key: const ValueKey('after-sales-capture'),
                      child: child!,
                    ),
                  ),
                  home: const CustomerAfterSalesScreen(
                    caseId: task054VisualCase,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final container = ProviderScope.containerOf(
              tester.element(find.byType(CustomerAfterSalesScreen)),
            );
            final controller = container.read(
              customerAfterSalesControllerProvider.notifier,
            );
            await controller.submitWithEvidence(
              draft: CustomerAfterSalesDraft(
                orderId: task054VisualOrder,
                type: CustomerAfterSalesType.orderProblem,
                reason: CustomerAfterSalesReason.damaged,
                note: null,
                lines: const [
                  CustomerAfterSalesLineDraft(
                    orderItemId: task054VisualOrderItem,
                    quantity: 1,
                  ),
                ],
              ),
              attachments: List.generate(
                3,
                (index) => CustomerAfterSalesLocalAttachment(
                  name: 'nombre-original-muy-largo-${index + 1}.png',
                  extension: 'png',
                  mimeType: 'image/png',
                  readBytes: () async {
                    if (index == 1) throw StateError('File sintetico perso');
                    return Uint8List.fromList([index + 1]);
                  },
                ),
              ),
              canContinue: () => true,
            );
            await tester.pumpAndSettle();
            final l10n = AppLocalizations.of(
              tester.element(find.byType(CustomerAfterSalesScreen)),
            );
            expect(find.text('pending_scan'), findsNothing);
            await tester.scrollUntilVisible(
              find.text(l10n.afterSalesCaseOpened),
              200,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.pumpAndSettle();
            expect(find.text(l10n.afterSalesCaseOpened), findsOneWidget);
            final replace = find.byKey(const ValueKey('after-sales-evidence-replace-1'));
            if (locale.languageCode == 'es' && Platform.environment['CMC_CLIENT_CAPTURE_DIR'] != null) {
              await tester.scrollUntilVisible(replace,200,scrollable:find.byType(Scrollable).first);
              await tester.ensureVisible(replace);
              await tester.pumpAndSettle();
              await tester.runAsync(()async {
                final boundary=tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('after-sales-capture')));
                final image=await boundary.toImage();
                final bytes=await image.toByteData(format:ui.ImageByteFormat.png);
                final directory=Platform.environment['CMC_CLIENT_CAPTURE_DIR']!;
                await Directory(directory).create(recursive:true);
                await File('$directory/after-sales-file-unavailable-es-CL-$dark.png').writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
            final retry = find.byKey(
              const ValueKey('after-sales-evidence-retry'),
            );
            await tester.scrollUntilVisible(
              retry,
              200,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.ensureVisible(retry);
            await tester.pumpAndSettle();
            expect(retry.hitTestable(), findsOneWidget);
            expect(
              find.byKey(const ValueKey('after-sales-evidence-replace-1')),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
            final directory = Platform.environment['CMC_CLIENT_CAPTURE_DIR'];
            if (directory != null)
              await tester.runAsync(() async {
                final boundary = tester.renderObject<RenderRepaintBoundary>(
                  find.byKey(const ValueKey('after-sales-capture')),
                );
                final image = await boundary.toImage();
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await Directory(directory).create(recursive: true);
                await File(
                  '$directory/after-sales-recovery-${locale.toLanguageTag()}-$dark.png',
                ).writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }

  for (final locale in const [
    Locale('es', 'CL'),
    Locale('it'),
    Locale('en'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ]) {
    testWidgets(
      'motivo, eleggibilità e validazione compact 200% ${locale.toLanguageTag()}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 568));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final fixtures = Task054VisualFixtures();
        await tester.pumpWidget(
          fixtures.wrap(
            MaterialApp(
              theme: AppTheme.light(),
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: const CustomerAfterSalesScreen(orderId: task054VisualOrder),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(CustomerAfterSalesScreen)),
        );
        final reason = tester
            .widget<DropdownButtonFormField<CustomerAfterSalesReason>>(
              find.byType(DropdownButtonFormField<CustomerAfterSalesReason>),
            );
        expect(reason.decoration.labelText, l10n.afterSalesReason);
        await tester.scrollUntilVisible(
          find.text('Producto sintético de prueba con descripción larga'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        final checks = tester
            .widgetList<Checkbox>(find.byType(Checkbox))
            .toList();
        expect(checks.first.onChanged, isNotNull);
        final ineligible = find.text(
          'Producto sintético sin unidades elegibles',
        );
        await tester.scrollUntilVisible(
          ineligible,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        final row = find.ancestor(
          of: ineligible,
          matching: find.byType(ListTile),
        );
        expect(
          tester
              .widget<Checkbox>(
                find.descendant(of: row, matching: find.byType(Checkbox)),
              )
              .onChanged,
          isNull,
        );
        final submit = find.byKey(const ValueKey('after-sales-submit'));
        await tester.scrollUntilVisible(
          submit,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(submit);
        await tester.pumpAndSettle();
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(fixtures.afterSales.createCalls, 0);
        expect(find.text(l10n.afterSalesSelectItem), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
