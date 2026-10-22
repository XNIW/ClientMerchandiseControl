// Fixture nativa: controller/UI e SQLite di produzione, nessun backend/Auth.
// Il runner installa una volta, legge seed.json, termina il PID e riavvia
// lo stesso bundle/data container prima di leggere recover.json.
import 'dart:convert';
import 'dart:io';

import 'package:client_merchandise_control/app/router/app_routes.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/core/formatting/clp_currency_formatter.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/cart/application/cart_controller.dart';
import 'package:client_merchandise_control/features/cart/application/cart_providers.dart';
import 'package:client_merchandise_control/features/cart/application/cart_state.dart';
import 'package:client_merchandise_control/features/cart/data/drift_guest_cart_store.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_models.dart';
import 'package:client_merchandise_control/features/cart/presentation/cart_screen.dart';
import 'package:client_merchandise_control/features/delivery_context/application/delivery_context_controller.dart';
import 'package:client_merchandise_control/features/home/application/home_controller.dart';
import 'package:client_merchandise_control/features/storefront/application/storefront_providers.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_database.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/common.dart' as integration_results;
import 'package:integration_test/integration_test.dart';
// Il gate deve leggere anche gli errori postTest/tearDownAll del runner pinned.
// ignore: depend_on_referenced_packages, implementation_imports
import 'package:test_api/src/backend/invoker.dart' show Invoker;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

const _apiVersion = 'guest-cart-native-evidence.v1';
const _firstId = 'f0541000-0000-4000-8000-000000000001';
const _secondId = 'f0541000-0000-4000-8000-000000000002';
const _firstName = 'Café sintético';
const _secondName = 'Té sintético';

// Il processo seed deve conservare connessione/provider/router fino al kill
// esterno. Nessun teardown chiude SQLite o svuota il carrello prima del kill.
final _nativeResources = <Object>[];

void main() {
  final publisher = _NativeCartTerminalPublisher(
    const String.fromEnvironment('CMC_GUEST_CART_RUN_ID'),
  );
  late final _NativeCartTestBinding binding;
  // test_api esegue tearDownAll LIFO. Registrato prima del costruttore SDK,
  // questo Future atteso parte dopo postTest e dopo cleanup/report native SDK.
  tearDownAll(() => publisher.publish(binding));
  binding = _NativeCartTestBinding();
  testWidgets('carrello guest recuperato dopo processo nativo terminato', (
    tester,
  ) async {
    const runId = String.fromEnvironment('CMC_GUEST_CART_RUN_ID');
    var phase = 'seed';
    Directory? runDirectory;
    try {
      expect(Platform.isAndroid || Platform.isIOS, isTrue);
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        ).hasMatch(runId),
        isTrue,
        reason: 'Occorre un UUID fixture nuovo assegnato dal runner.',
      );
      final shopSlug = 'cmc-cart-$runId';
      final support = await getApplicationSupportDirectory();
      runDirectory = Directory(
        path.join(support.path, 'task054-guest-cart-$runId'),
      );
      await runDirectory.create(recursive: true);
      publisher.directory = runDirectory;
      final marker = File(path.join(runDirectory.path, 'marker.json'));
      final seedReceipt = File(path.join(runDirectory.path, 'seed.json'));
      final recoverReceipt = File(path.join(runDirectory.path, 'recover.json'));
      final int seedProcessId;
      if (await marker.exists()) {
        phase = 'recover';
        publisher.phase = phase;
        seedProcessId = await _readMarker(marker, runId, shopSlug);
        expect(pid, isNot(seedProcessId), reason: 'Serve un nuovo processo.');
        expect(await seedReceipt.exists(), isTrue);
        expect(await recoverReceipt.exists(), isFalse);
      } else {
        // Una receipt precedente senza marker non autorizza una nuova seed.
        expect(await seedReceipt.exists(), isFalse);
        expect(await recoverReceipt.exists(), isFalse);
        seedProcessId = pid;
      }

      final database = StorefrontCacheDatabase.defaults();
      final store = DriftGuestCartStore(database);
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(_config(shopSlug)),
          customerAccountIdentityProvider.overrideWithValue(null),
          storefrontCacheDatabaseProvider.overrideWithValue(database),
          // CartController e guestCartStoreProvider restano di produzione.
          // L'accesso al repository account è un errore della fixture guest.
          customerCartRepositoryProvider.overrideWith((ref) {
            throw StateError('La fixture guest non ammette backend.');
          }),
          homeControllerProvider.overrideWith(_FixtureHomeController.new),
          cartDeliveryContextStateProvider.overrideWithValue(
            const DeliveryContextState(
              status: DeliveryContextViewStatus.ready,
              authenticated: false,
            ),
          ),
        ],
      );
      final router = _router();
      _nativeResources.addAll([database, container, router]);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            locale: const Locale('es', 'CL'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await _waitForReady(tester, container);

      if (phase == 'seed') {
        // Shop fresco: mai cancellare una fixture precedente per farla passare.
        expect((await store.read(shopSlug: shopSlug)).items, isEmpty);
        expect(container.read(cartControllerProvider).snapshot!.items, isEmpty);
        await container
            .read(cartControllerProvider.notifier)
            .addProduct(_product(_firstId, _firstName, 1200), quantity: 2);
        await container
            .read(cartControllerProvider.notifier)
            .addProduct(_product(_secondId, _secondName, 800), quantity: 1);
        _assertSnapshot(await store.read(shopSlug: shopSlug), shopSlug);
        _assertSnapshot(
          container.read(cartControllerProvider).snapshot!,
          shopSlug,
        );
        // Scrittura dopo gli await delle transazioni SQLite/read. Il marker
        // non sostituisce il contenuto carrello e non viene mai sovrascritto.
        await _writeNewJson(marker, {
          'runId': runId,
          'seedProcessId': seedProcessId,
          'shopSlug': shopSlug,
        });
      } else {
        // Recover non contiene addProduct/setProduct o riparazioni del seed.
        _assertSnapshot(await store.read(shopSlug: shopSlug), shopSlug);
        _assertSnapshot(
          container.read(cartControllerProvider).snapshot!,
          shopSlug,
        );
        await _assertRestoredCartUi(tester);
        expect(tester.takeException(), isNull);
        await container.read(cartControllerProvider.notifier).clear();
        expect((await store.read(shopSlug: shopSlug)).items, isEmpty);
        expect(container.read(cartControllerProvider).snapshot!.items, isEmpty);
        await marker.delete();
        expect(await marker.exists(), isFalse);
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
        router.dispose();
        await database.close();
        _nativeResources.clear();
      }
      expect(tester.takeException(), isNull);
      final receipt = <String, Object?>{
        'apiVersion': _apiVersion,
        'phase': phase,
        'runId': runId,
        'processId': pid,
        'seedProcessId': seedProcessId,
        'shopSlug': shopSlug,
        'nativeWriteRead': phase == 'seed' ? 'PASS' : 'NOT_RUN',
        'processRestartRead': phase == 'recover' ? 'PASS' : 'NOT_RUN',
        'cartUiRestored': phase == 'recover' ? 'PASS' : 'NOT_RUN',
        'cleanup': phase == 'recover' ? 'PASS' : 'NOT_RUN',
        'backend': 'NOT_RUN',
      };
      // Il body conserva soltanto la candidate; nessun successJSON è visibile.
      publisher.successCandidate = Map<String, Object?>.unmodifiable(receipt);
    } catch (error) {
      publisher.errorType = error is TestFailure
          ? 'assertion'
          : error is FileSystemException
          ? 'filesystem'
          : 'unexpected';
      rethrow;
    }
  });
}

// allTestsPassed SDK viene completato prima del report native e non cambia
// dopo un errore di postTest. Il binding registra quel ramo come Failure prima
// della closure SDK; il publisher controlla anche il risultato del tearDownAll.
class _NativeCartTestBinding extends IntegrationTestWidgetsFlutterBinding {
  bool postTestCompleted = false;
  bool postTestFailed = false;

  void _recordPostTestFailure() {
    postTestFailed = true;
    results['guest-cart-postTest'] = integration_results.Failure(
      'guest-cart-postTest',
      'sanitized_post_test_failure',
    );
  }

  @override
  void postTest() {
    if (Invoker.current?.liveTest.state.result.isFailing ?? true) {
      _recordPostTestFailure();
    }
    try {
      super.postTest();
    } catch (_) {
      _recordPostTestFailure();
      rethrow;
    } finally {
      postTestCompleted = true;
    }
  }
}

class _NativeCartTerminalPublisher {
  _NativeCartTerminalPublisher(this.runId);

  final String runId;
  Directory? directory;
  String phase = 'seed';
  String? errorType;
  Map<String, Object?>? successCandidate;
  bool _started = false;

  Future<void> publish(_NativeCartTestBinding binding) async {
    if (_started) {
      throw StateError('Publisher terminale già avviato.');
    }
    _started = true;
    // Nessuna .then scartata: il test runner attende questo callback completo.
    final sdkPassed = await binding.allTestsPassed.future;
    // Il loop LIFO SDK usa whenComplete: prima della lettura del risultato,
    // lascia propagare le failure microtask della precedente callback.
    await Future<void>.delayed(Duration.zero);
    final teardownFailed =
        Invoker.current?.liveTest.state.result.isFailing ?? true;
    final terminalPassed =
        sdkPassed &&
        binding.postTestCompleted &&
        !binding.postTestFailed &&
        !teardownFailed &&
        binding.failureMethodsDetails.isEmpty &&
        errorType == null &&
        successCandidate != null;
    final targetDirectory = directory;
    if (targetDirectory == null) {
      // Setup senza sandbox attestato: nessun file success, runner FAIL/timeout.
      return;
    }
    final result = terminalPassed
        ? successCandidate!
        : <String, Object?>{
            'apiVersion': _apiVersion,
            'phase': phase,
            'runId': runId,
            'processId': pid,
            'status': 'FAIL',
            'errorType': errorType ?? 'assertion',
          };
    binding.reportData = result;
    await _publishTerminalJson(
      File(path.join(targetDirectory.path, '$phase.json')),
      result,
    );
  }
}

Future<void> _publishTerminalJson(
  File target,
  Map<String, Object?> value,
) async {
  // Unico publisher nel sandbox/run proprio. Prima si chiude il record completo;
  // il rename finale lo rende osservabile. Un record precedente è preservato.
  final pending = File('${target.path}.pending-$pid');
  if (await target.exists()) {
    throw StateError('Record terminale già presente.');
  }
  await _writeNewJson(pending, value);
  if (await target.exists()) {
    throw StateError('Record terminale già presente.');
  }
  await pending.rename(target.path);
}

Future<int> _readMarker(File marker, String runId, String shopSlug) async {
  expect(await marker.length(), lessThanOrEqualTo(1024));
  final decoded = jsonDecode(await marker.readAsString());
  expect(decoded, isA<Map<String, dynamic>>());
  final value = decoded as Map<String, dynamic>;
  expect(value.keys, unorderedEquals(['runId', 'seedProcessId', 'shopSlug']));
  expect(value['runId'], runId);
  expect(value['shopSlug'], shopSlug);
  expect(value['seedProcessId'], isA<int>());
  final seedProcessId = value['seedProcessId'] as int;
  expect(seedProcessId, greaterThan(0));
  return seedProcessId;
}

Future<void> _writeNewJson(File file, Map<String, Object?> value) async {
  // dart:io non espone O_EXCL portabile. Lock esclusivo, verifica length==0
  // e append evitano truncate/sovrascrittura; il runner possiede l'unico bundle.
  if (await file.exists()) {
    throw StateError('Record fixture già presente.');
  }
  final output = await file.open(mode: FileMode.append);
  var locked = false;
  try {
    await output.lock(FileLock.exclusive);
    locked = true;
    if (await output.length() != 0) {
      throw StateError('Record fixture già presente.');
    }
    await output.writeString(jsonEncode(value));
    await output.flush();
  } finally {
    if (locked) await output.unlock();
    await output.close();
  }
}

Future<void> _waitForReady(
  WidgetTester tester,
  ProviderContainer container,
) async {
  for (var attempt = 0; attempt < 500; attempt++) {
    final state = container.read(cartControllerProvider);
    if (state.status == CartViewStatus.ready && state.snapshot != null) {
      expect(state.isAuthenticated, isFalse);
      expect(state.failureKind, isNull);
      return;
    }
    await tester.pump(const Duration(milliseconds: 20));
  }
  fail('Il controller guest non ha raggiunto lo stato ready.');
}

void _assertSnapshot(CustomerCartSnapshot value, String shopSlug) {
  expect(value.shopSlug, shopSlug);
  expect(value.source, CartSource.guest);
  expect(value.version, 0);
  expect(value.quoteStatus, CartQuoteStatus.indicative);
  expect(value.items, hasLength(2));
  expect(value.totalQuantity, 3);
  expect(value.subtotalClp, 3200);
  final lines = {for (final item in value.items) item.publicationId: item};
  expect(lines.keys, unorderedEquals([_firstId, _secondId]));
  expect(lines[_firstId]!.publicName, _firstName);
  expect(lines[_firstId]!.quantity, 2);
  expect(lines[_firstId]!.priceClp, 1200);
  expect(lines[_secondId]!.publicName, _secondName);
  expect(lines[_secondId]!.quantity, 1);
  expect(lines[_secondId]!.priceClp, 800);
  for (final line in value.items) {
    expect(line.isGuest, isTrue);
    expect(line.isAvailable, isTrue);
    expect(line.imageUrl, isNull);
  }
}

Future<void> _assertRestoredCartUi(WidgetTester tester) async {
  await tester.pumpAndSettle();
  expect(find.byType(CartScreen), findsOneWidget);
  final context = tester.element(find.byType(CartScreen));
  final l10n = AppLocalizations.of(context);
  for (final expected in [
    (_firstId, _firstName, 2),
    (_secondId, _secondName, 1),
  ]) {
    expect(find.byKey(ValueKey('cart-line-${expected.$1}')), findsOneWidget);
    expect(find.text(expected.$2), findsOneWidget);
    final quantity = find.byKey(ValueKey('cart-quantity-${expected.$1}'));
    await tester.ensureVisible(quantity);
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(quantity).data,
      l10n.cartQuantityLabel(expected.$3),
    );
    final viewport =
        Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(tester.getRect(quantity).overlaps(viewport), isTrue);
  }
  final subtotal = find.byKey(const ValueKey('cart-subtotal'));
  await tester.ensureVisible(subtotal);
  await tester.pumpAndSettle();
  expect(
    find.descendant(
      of: subtotal,
      matching: find.text(ClpCurrencyFormatter().format(3200)),
    ),
    findsOneWidget,
  );
  expect(find.textContaining(_firstId), findsNothing);
  expect(find.textContaining(_secondId), findsNothing);
}

GoRouter _router() => GoRouter(
  initialLocation: AppRoutes.cartLocation,
  routes: [
    GoRoute(
      path: AppRoutes.cartLocation,
      builder: (_, _) => const Scaffold(body: CartScreen()),
    ),
    for (final destination in [
      AppRoutes.catalogLocation,
      AppRoutes.accountLocation,
      AppRoutes.checkoutLocation,
      AppRoutes.deliveryContextLocation,
    ])
      GoRoute(
        path: destination,
        builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
      ),
  ],
);

AppConfig _config(String shopSlug) => AppConfig.fromValues(
  appEnvironment: 'staging',
  supabaseUrl: 'https://guest-cart.example.invalid',
  supabasePublishableKey: 'sb_publishable_fixture',
  authRedirectUri: AppConfig.allowedAuthRedirectUri,
  googleAuthEnabled: 'false',
  storefrontShopSlug: shopSlug,
);

StorefrontProductSummary _product(String id, String name, int priceClp) =>
    StorefrontProductSummary(
      id: id,
      category: const StorefrontCategory(
        id: 'f0542000-0000-4000-8000-000000000001',
        slug: 'synthetic',
        name: 'Sintético',
        sortRank: 1,
      ),
      name: name,
      priceClp: priceClp,
      featured: false,
      sortRank: 1,
      availability: StorefrontAvailability.available,
      fulfillment: const StorefrontFulfillment(
        pickup: true,
        delivery: false,
        reservation: false,
      ),
      catalogVersion: 1,
      publishedAt: DateTime.utc(2026, 10, 12),
      updatedAt: DateTime.utc(2026, 10, 12),
    );

final class _FixtureHomeController extends HomeController {
  @override
  HomeState build() => const HomeState.empty();
}
