import 'dart:io';

import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/app/router/app_routes.dart';
import 'package:client_merchandise_control/features/after_sales/application/customer_after_sales_controller.dart';
import 'package:client_merchandise_control/features/after_sales/domain/customer_after_sales_models.dart';
import 'package:client_merchandise_control/features/after_sales/domain/customer_after_sales_repository.dart';
import 'package:client_merchandise_control/features/after_sales/presentation/customer_after_sales_screen.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/commerce_surface_fixtures.dart';

void main() {
  for (final lostFile in [false, true]) {
    testWidgets(
      'recupero stessa pratica, confermati conservati lostFile=$lostFile',
      (tester) async {
        final directory = Directory.systemTemp.createTempSync(
          'cmc-evidence-recovery-',
        );
        addTearDown(() => directory.deleteSync(recursive: true));
        final files = List.generate(
          3,
          (index) =>
              File('${directory.path}/originale-$index.png')
                ..writeAsBytesSync([index + 1]),
        );
        var picks = 0;
        List<String> selection() =>
            (++picks == 1 ? files : [files[1]]).map((f) => f.path).toList();
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        const channel = MethodChannel('plugins.flutter.io/image_picker');
        messenger.setMockMethodCallHandler(channel, (_) async => selection());
        addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
        for (final name in [
          'dev.flutter.pigeon.image_picker_android.ImagePickerApi.pickImages',
          'dev.flutter.pigeon.image_picker_ios.ImagePickerApi.pickMultiImage',
        ]) {
          messenger.setMockMessageHandler(
            name,
            (_) async =>
                const StandardMessageCodec().encodeMessage([selection()]),
          );
          addTearDown(() => messenger.setMockMessageHandler(name, null));
        }
        final fixture = Task054VisualFixtures();
        final repository = _RecoveryRepository(
          fixture.afterSales,
          lostFile ? files[1] : null,
        );
        final router = GoRouter(
          initialLocation: '/new',
          routes: [
            GoRoute(
              path: '/new',
              builder: (_, _) =>
                  const CustomerAfterSalesScreen(orderId: task054VisualOrder),
            ),
            GoRoute(
              path: AppRoutes.afterSalesBaseLocation,
              builder: (_, _) => const CustomerAfterSalesScreen(),
              routes: [
                GoRoute(
                  path: ':caseId',
                  builder: (_, state) => CustomerAfterSalesScreen(
                    caseId: state.pathParameters['caseId'],
                  ),
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          fixture.wrap(
            MaterialApp.router(
              routerConfig: router,
              theme: AppTheme.light(),
              locale: const Locale('es', 'CL'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
            additionalOverrides: [
              customerAfterSalesRepositoryProvider.overrideWithValue(
                repository,
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Checkbox).first);
        await _tap(
          tester,
          find.byKey(const ValueKey('after-sales-evidence-picker')),
        );
        await _tap(tester, find.byKey(const ValueKey('after-sales-submit')));
        expect(repository.createCalls, 1);
        expect(
          tester.takeException(),
          isNull,
          reason:
              'Il fallimento locale diventa recuperabile, senza eccezione grezza',
        );
        expect(repository.uploaded, [1, if (!lostFile) 2, 3]);
        router.go(AppRoutes.afterSalesLocation(task054VisualCase));
        await tester.pumpAndSettle();
        // Il checkpoint segue la pratica anche su una nuova route.
        final retry = find.byKey(const ValueKey('after-sales-evidence-retry'));
        expect(
          retry,
          findsOneWidget,
          reason: 'Azione persistente dopo il successo parziale',
        );
        if (lostFile) {
          files[1].writeAsBytesSync([2]);
          await _tap(
            tester,
            find.byKey(const ValueKey('after-sales-evidence-replace-1')),
          );
        }
        await _tap(tester, retry);
        expect(
          repository.createCalls,
          1,
          reason: 'Il recupero non crea una seconda pratica',
        );
        expect(repository.uploaded.where((byte) => byte == 1), hasLength(1));
        expect(repository.uploaded.where((byte) => byte == 3), hasLength(1));
        expect(
          repository.uploaded.where((byte) => byte == 2),
          hasLength(lostFile ? 1 : 2),
        );
        expect(repository.caseIds.toSet(), {task054VisualCase});
        router.go('/new');
        await tester.pumpAndSettle();
        expect(
          find.byType(Checkbox),
          findsWidgets,
          reason: 'Nuova richiesta legittima dopo completamento',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    await tester.tap(finder);
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pumpAndSettle();
}

class _RecoveryRepository implements CustomerAfterSalesRepository {
  _RecoveryRepository(this.delegate, this.lostFile);
  final Task054AfterSalesRepository delegate;
  final File? lostFile;
  int createCalls = 0;
  bool failed = false;
  final uploaded = <int>[];
  final caseIds = <String>[];
  @override
  Future<List<CustomerAfterSalesCase>> list({required String shopSlug}) =>
      delegate.list(shopSlug: shopSlug);
  @override
  Future<CustomerAfterSalesOrderLines> listOrderLines(String orderId) =>
      delegate.listOrderLines(orderId);
  @override
  Future<CustomerAfterSalesCase> create({
    required CustomerAfterSalesDraft draft,
    required String idempotencyKey,
  }) async {
    createCalls++;
    lostFile?.deleteSync();
    return delegate.create(draft: draft, idempotencyKey: idempotencyKey);
  }

  @override
  Future<CustomerAfterSalesCase> cancel({
    required String caseId,
    required int expectedVersion,
  }) => delegate.cancel(caseId: caseId, expectedVersion: expectedVersion);
  @override
  Future<String> uploadEvidence({
    required String caseId,
    required CustomerAfterSalesEvidenceInput input,
  }) async {
    expect(input.bytes, isA<Uint8List>());
    uploaded.add(input.bytes.first);
    caseIds.add(caseId);
    if (lostFile == null && input.bytes.first == 2 && !failed) {
      failed = true;
      throw const CustomerAfterSalesException('unavailable');
    }
    return '89000000-0000-4000-8000-00000000000${input.bytes.first}';
  }
}
