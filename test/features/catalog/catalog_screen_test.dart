import 'dart:async';

import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/core/backend/backend_health_service.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_repository.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/features/catalog/presentation/catalog_screen.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildCatalog({
    required BackendReadinessRepository repository,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return ProviderScope(
      overrides: [
        backendReadinessRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        locale: const Locale('es', 'CL'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: const Scaffold(body: SafeArea(child: CatalogScreen())),
      ),
    );
  }

  AppLocalizations l10n(WidgetTester tester) {
    return AppLocalizations.of(tester.element(find.byType(CatalogScreen)));
  }

  testWidgets('espone discovery visibile, disabilitata e spiegata', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildCatalog(
        repository: _CatalogRepository(
          initialState: BackendReadinessState.ready,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final strings = l10n(tester);
    final search = tester.widget<SearchBar>(
      find.byKey(const ValueKey('catalog-search')),
    );
    final filter = tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(const ValueKey('catalog-filter')),
        matching: find.byType(OutlinedButton),
      ),
    );
    final sort = tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(const ValueKey('catalog-sort')),
        matching: find.byType(OutlinedButton),
      ),
    );

    expect(search.enabled, isFalse);
    expect(find.text(strings.catalogSearchHint), findsOneWidget);
    expect(filter.onPressed, isNull);
    expect(sort.onPressed, isNull);
    expect(find.text(strings.catalogFilterLabel), findsOneWidget);
    expect(find.text(strings.catalogSortLabel), findsOneWidget);
    expect(find.text(strings.catalogControlsUnavailable), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.textField == true &&
            widget.properties.enabled == false &&
            widget.properties.label == strings.catalogSearchLabel &&
            widget.properties.hint == strings.catalogSearchHint,
      ),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('catalog-search'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('catalog-filter'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('catalog-sort'))).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('distingue tutti gli stati senza dati commerciali finti', (
    tester,
  ) async {
    final cases =
        <
          ({
            BackendReadinessState readiness,
            String key,
            String Function(AppLocalizations) title,
            String Function(AppLocalizations) message,
            bool progress,
            bool retry,
          })
        >[
          (
            readiness: BackendReadinessState.unconfigured,
            key: 'catalog-empty',
            title: (strings) => strings.catalogEmptyTitle,
            message: (strings) => strings.catalogEmptyMessage,
            progress: false,
            retry: false,
          ),
          (
            readiness: BackendReadinessState.ready,
            key: 'catalog-empty',
            title: (strings) => strings.catalogEmptyTitle,
            message: (strings) => strings.catalogEmptyMessage,
            progress: false,
            retry: false,
          ),
          (
            readiness: BackendReadinessState.initializing,
            key: 'catalog-connecting',
            title: (strings) => strings.catalogConnectingTitle,
            message: (strings) => strings.catalogConnectingMessage,
            progress: true,
            retry: false,
          ),
          (
            readiness: BackendReadinessState.offline,
            key: 'catalog-offline',
            title: (strings) => strings.catalogOfflineTitle,
            message: (strings) => strings.catalogOfflineMessage,
            progress: false,
            retry: true,
          ),
          (
            readiness: BackendReadinessState.misconfigured,
            key: 'catalog-unavailable',
            title: (strings) => strings.catalogUnavailableTitle,
            message: (strings) => strings.catalogUnavailableMessage,
            progress: false,
            retry: false,
          ),
          (
            readiness: BackendReadinessState.authenticationRequired,
            key: 'catalog-unavailable',
            title: (strings) => strings.catalogUnavailableTitle,
            message: (strings) => strings.catalogUnavailableMessage,
            progress: false,
            retry: false,
          ),
          (
            readiness: BackendReadinessState.recoverableError,
            key: 'catalog-retry',
            title: (strings) => strings.catalogRetryTitle,
            message: (strings) => strings.catalogRetryMessage,
            progress: false,
            retry: true,
          ),
        ];

    for (final testCase in cases) {
      final repository = _CatalogRepository(
        initialState: testCase.readiness,
        canCheck: false,
      );
      await tester.pumpWidget(buildCatalog(repository: repository));
      await tester.pump();

      final strings = l10n(tester);
      expect(repository.calls, 0, reason: testCase.readiness.name);
      expect(
        find.byKey(ValueKey(testCase.key)),
        findsOneWidget,
        reason: testCase.readiness.name,
      );
      expect(
        find.text(testCase.title(strings)),
        findsOneWidget,
        reason: testCase.readiness.name,
      );
      expect(
        find.text(testCase.message(strings)),
        findsOneWidget,
        reason: testCase.readiness.name,
      );
      expect(
        find.byKey(const ValueKey('catalog-progress')),
        testCase.progress ? findsOneWidget : findsNothing,
      );
      expect(
        find.byKey(const ValueKey('catalog-retry-action')),
        testCase.retry ? findsOneWidget : findsNothing,
      );
      expect(find.byType(Image), findsNothing);
      expect(find.textContaining(r'$'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('offline riusa il retry controller single-flight', (
    tester,
  ) async {
    final repository = _CatalogRepository(
      initialState: BackendReadinessState.offline,
    );

    await tester.pumpWidget(buildCatalog(repository: repository));
    await tester.pumpAndSettle();

    final retry = find.byKey(const ValueKey('catalog-retry-action'));
    expect(retry, findsOneWidget);

    await tester.tap(retry);
    await tester.tap(retry);

    expect(repository.calls, 1);
    await tester.pump();
    expect(find.byKey(const ValueKey('catalog-connecting')), findsOneWidget);
    expect(retry, findsNothing);

    repository.completeNext(BackendReadinessState.ready);
    await tester.pumpAndSettle();

    expect(repository.calls, 1);
    expect(find.byKey(const ValueKey('catalog-empty')), findsOneWidget);
    expect(retry, findsNothing);
  });

  testWidgets('errore recuperabile usa lo stesso retry e torna offline', (
    tester,
  ) async {
    final repository = _CatalogRepository(
      initialState: BackendReadinessState.recoverableError,
    );

    await tester.pumpWidget(buildCatalog(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('catalog-retry-action')));
    await tester.pump();
    expect(repository.calls, 1);
    expect(find.byKey(const ValueKey('catalog-connecting')), findsOneWidget);

    repository.completeNext(BackendReadinessState.offline);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('catalog-offline')), findsOneWidget);
    expect(find.byKey(const ValueKey('catalog-retry-action')), findsOneWidget);
  });

  testWidgets('retry e stato hanno Semantics e target accessibili', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildCatalog(
        repository: _CatalogRepository(
          initialState: BackendReadinessState.offline,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const ValueKey('catalog-retry-action'));
    final liveRegions = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where((widget) => widget.properties.liveRegion == true);
    final headings = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where((widget) => widget.properties.header == true);

    expect(liveRegions, hasLength(1));
    expect(headings, hasLength(1));
    expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
    expect(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(tester, meetsGuideline(androidTapTargetGuideline));
    expect(tester, meetsGuideline(iOSTapTargetGuideline));
  });

  testWidgets('resta raggiungibile a 200% su viewport compact e landscape', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final size in const [Size(320, 568), Size(568, 320)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        buildCatalog(
          repository: _CatalogRepository(
            initialState: BackendReadinessState.offline,
          ),
          themeMode: size.width > size.height
              ? ThemeMode.dark
              : ThemeMode.light,
        ),
      );
      await tester.pumpAndSettle();

      final retry = find.byKey(const ValueKey('catalog-retry-action'));
      await tester.ensureVisible(retry);
      await tester.pumpAndSettle();

      expect(retry, findsOneWidget, reason: '$size');
      expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });
}

final class _CatalogRepository implements BackendReadinessRepository {
  _CatalogRepository({required this.initialState, this.canCheck = true});

  @override
  final BackendReadinessState initialState;

  @override
  final bool canCheck;

  final List<Completer<BackendReadinessState>> _results = [];

  int get calls => _results.length;

  @override
  Future<BackendReadinessState> check({
    required BackendProbeCancellation cancellation,
  }) {
    final result = Completer<BackendReadinessState>();
    _results.add(result);
    return result.future;
  }

  void completeNext(BackendReadinessState state) {
    _results.firstWhere((result) => !result.isCompleted).complete(state);
  }
}
