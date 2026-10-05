// Regressioni della route pubblica: app, router, AuthController e identity reali.
// Le sole porte remote/callback e la configurazione usano dati sintetici.
import 'dart:async';

import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
import 'package:client_merchandise_control/app/router/app_router.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/auth/application/auth_controller.dart';
import 'package:client_merchandise_control/features/auth/application/auth_providers.dart';
import 'package:client_merchandise_control/features/auth/data/auth_callback_source.dart';
import 'package:client_merchandise_control/features/auth/domain/auth_repository.dart';
import 'package:client_merchandise_control/features/auth/domain/auth_state.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/reviews/application/customer_review_providers.dart';
import 'package:client_merchandise_control/features/reviews/domain/customer_review_models.dart';
import 'package:client_merchandise_control/features/reviews/domain/customer_review_repository.dart';
import 'package:client_merchandise_control/features/reviews/presentation/customer_reviews.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../account/customer_account_test_support.dart';
import '../../support/commerce_surface_fixtures.dart';

const _ownerA = '00000000-0000-4000-8000-000000021001';
const _ownerB = '00000000-0000-4000-8000-000000021002';
const _draft = 'Bozza sintetica privata del primo owner';
const _ack = CustomerReviewMutation(
  reviewId: task054VisualReview,
  status: CustomerReviewStatus.pending,
  version: 1,
);

void main() {
  testWidgets('route /reviews expiry reale elimina dialog prima di ACK tardivo', (
    tester,
  ) async {
    final rig = await _openPublicRoute(tester);
    await _beginMutation(tester, rig.l10n);
    expect(rig.reviews.attempts, hasLength(1));

    rig.auth.expire();
    await tester.pumpAndSettle();
    expect(rig.container.read(authControllerProvider), isA<AuthGuest>());
    expect(rig.container.read(customerAccountIdentityProvider), isNull);
    final modalSurvivedExpiry = find.byType(AlertDialog).evaluate().isNotEmpty;
    final oldDraftSurvivedExpiry = _visibleDraft(tester) == _draft;

    // La risposta è risolta prima degli assert del finding: nessun future pendente.
    rig.reviews.attempts.single.complete(_ack);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      modalSurvivedExpiry,
      isFalse,
      reason:
          'AuthController=AuthGuest e identity=null nella route pubblica; '
          'dialog precedente ancora montato=$modalSurvivedExpiry, '
          'bozza precedente ancora presente=$oldDraftSurvivedExpiry; '
          'ACK tardivo già risolto.',
    );
  });

  testWidgets('route /reviews cambio owner reale isola failure tardiva', (
    tester,
  ) async {
    final rig = await _openPublicRoute(tester);
    await _beginMutation(tester, rig.l10n);
    expect(rig.reviews.attempts, hasLength(1));
    rig.auth.signIn(_customer(_ownerB));
    await tester.pumpAndSettle();
    expect(
      (rig.container.read(authControllerProvider) as AuthAuthenticated)
          .customer
          .subjectId,
      _ownerB,
    );
    expect(
      rig.container.read(customerAccountIdentityProvider)?.subjectId,
      _ownerB,
    );
    final modalSurvivedOwnerChange = find
        .byType(AlertDialog)
        .evaluate()
        .isNotEmpty;
    rig.reviews.attempts.single.completeError(
      const CustomerReviewException('unavailable'),
    );
    await tester.pumpAndSettle();
    final oldDraftStillVisible = _visibleDraft(tester) == _draft;
    final oldFailureStillVisible = find
        .descendant(
          of: find.byType(AlertDialog),
          matching: find.text(rig.l10n.reviewsFailure),
        )
        .evaluate()
        .isNotEmpty;
    expect(tester.takeException(), isNull);
    expect(
      modalSurvivedOwnerChange,
      isFalse,
      reason:
          'AuthController/identity sono passati realmente a ownerB; '
          'dialog ownerA ancora montato=$modalSurvivedOwnerChange, '
          'bozza ownerA visibile=$oldDraftStillVisible, '
          'failure ownerA locale visibile=$oldFailureStillVisible; '
          'callback tardivo già risolto.',
    );
  });

  for (final lateFailure in [false, true]) {
    testWidgets('route /reviews A-B-A invalida editor failure=$lateFailure', (
      tester,
    ) async {
      final rig = await _openPublicRoute(tester);
      await _beginMutation(tester, rig.l10n);
      rig.auth.signIn(_customer(_ownerB));
      rig.auth.signIn(_customer(_ownerA));
      await tester.pumpAndSettle();
      expect(
        rig.container.read(customerAccountIdentityProvider)?.subjectId,
        _ownerA,
      );
      expect(find.byType(AlertDialog), findsNothing);
      await _openEditor(tester, rig.l10n, draft: 'Nuova bozza sintetica');
      final readsBeforeResponse = rig.reviews.listCalls;
      if (lateFailure) {
        rig.reviews.attempts.single.completeError(
          const CustomerReviewException('unavailable'),
        );
      } else {
        rig.reviews.attempts.single.complete(_ack);
      }
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(_visibleDraft(tester), 'Nuova bozza sintetica');
      expect(find.text(rig.l10n.reviewsFailure), findsNothing);
      expect(rig.reviews.listCalls, readsBeforeResponse);
      expect(rig.reviews.attempts, hasLength(1));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('route /reviews cambio owner elimina anche bozza non inviata', (
    tester,
  ) async {
    final rig = await _openPublicRoute(tester);
    await _openEditor(tester, rig.l10n);
    rig.auth.signIn(_customer(_ownerB));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(_visibleDraft(tester), isNull);
    expect(rig.reviews.attempts, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('route /reviews cambio owner prima del primo frame del dialog', (
    tester,
  ) async {
    final rig = await _openPublicRoute(tester);
    final leave = find.text(rig.l10n.reviewsLeave);
    await tester.ensureVisible(leave);
    await tester.pumpAndSettle();
    await tester.tap(leave);
    rig.auth.signIn(_customer(_ownerB));
    await tester.pumpAndSettle();
    expect(
      rig.container.read(customerAccountIdentityProvider)?.subjectId,
      _ownerB,
    );
    expect(find.byType(AlertDialog), findsNothing);
    expect(rig.reviews.attempts, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('route /reviews stesso subject conserva editor e bozza', (
    tester,
  ) async {
    final rig = await _openPublicRoute(tester);
    await _openEditor(tester, rig.l10n);
    rig.auth.signIn(
      AuthenticatedCustomer.fromUntrustedIdentity(
        subjectId: _ownerA,
        email: null,
        metadata: const {'full_name': 'Nome sintetico aggiornato'},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(_visibleDraft(tester), _draft);
    expect(rig.reviews.attempts, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('route /reviews invalidazione rimuove solo il proprio dialog', (
    tester,
  ) async {
    final rig = await _openPublicRoute(tester);
    await _beginMutation(tester, rig.l10n);
    final secondary = showDialog<void>(
      context: tester.element(find.byType(AlertDialog)),
      builder: (_) =>
          const AlertDialog(title: Text('Dialog sintetico successivo')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNWidgets(2));
    rig.auth.signIn(_customer(_ownerB));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Dialog sintetico successivo'), findsOneWidget);
    final readsBeforeResponse = rig.reviews.listCalls;
    rig.reviews.attempts.single.complete(_ack);
    await tester.pumpAndSettle();
    expect(find.text('Dialog sintetico successivo'), findsOneWidget);
    expect(rig.reviews.listCalls, readsBeforeResponse);
    expect(_visibleDraft(tester), isNull);
    Navigator.of(tester.element(find.byType(AlertDialog))).pop();
    await tester.pumpAndSettle();
    await secondary;
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'route /reviews cambio owner elimina anche popup rating proprio',
    (tester) async {
      final rig = await _openPublicRoute(tester);
      await _openEditor(tester, rig.l10n);
      final dropdown = find.byType(DropdownButton<int>);
      await tester.ensureVisible(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      expect(find.byType(DropdownMenuItem<int>), findsWidgets);
      rig.auth.signIn(_customer(_ownerB));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(DropdownMenuItem<int>), findsNothing);
      expect(rig.reviews.attempts, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}

Finder get _field => find.descendant(
  of: find.byType(AlertDialog),
  matching: find.byType(TextField),
);

String? _visibleDraft(WidgetTester tester) => _field.evaluate().isEmpty
    ? null
    : tester.widget<TextField>(_field).controller?.text;

Future<void> _beginMutation(WidgetTester tester, AppLocalizations l10n) async {
  await _openEditor(tester, l10n);
  final submit = find.byKey(const ValueKey('review-submit'));
  await tester.ensureVisible(submit);
  await tester.pumpAndSettle();
  expect(submit.hitTestable(), findsOneWidget);
  await tester.tap(submit);
  await tester.pumpAndSettle();
}

Future<void> _openEditor(
  WidgetTester tester,
  AppLocalizations l10n, {
  String draft = _draft,
}) async {
  final leave = find.text(l10n.reviewsLeave);
  await tester.ensureVisible(leave);
  await tester.pumpAndSettle();
  await tester.tap(leave);
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsOneWidget);
  await tester.enterText(_field, draft);
  await tester.pumpAndSettle();
}

Future<_Rig> _openPublicRoute(WidgetTester tester) async {
  final auth = _SessionRepository(_customer(_ownerA));
  final source = _CallbackSource();
  final reviews = _PendingReviews();
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.authFlowTest()),
      authRepositoryFactoryProvider.overrideWithValue((_) async => auth),
      authCallbackSourceProvider.overrideWithValue(source),
      customerAccountRepositoryProvider.overrideWithValue(
        FakeCustomerAccountRepository(),
      ),
      customerReviewRepositoryProvider.overrideWithValue(reviews),
    ],
  );
  addTearDown(() async {
    for (final pending in reviews.attempts) {
      if (!pending.isCompleted) {
        pending.completeError(const CustomerReviewException('unavailable'));
      }
    }
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    container.dispose();
    await auth.dispose();
    await source.dispose();
  });
  container.read(authControllerProvider);
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump(const Duration(milliseconds: 10));
    if (container.read(authControllerProvider) is AuthAuthenticated) break;
  }
  expect(container.read(authControllerProvider), isA<AuthAuthenticated>());
  expect(container.read(customerAccountIdentityProvider)?.subjectId, _ownerA);
  final router = container.read(appRouterProvider);
  router.go(AppRoutes.reviewsLocation);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const ClientMerchandiseControlApp(locale: Locale('es', 'CL')),
    ),
  );
  await tester.pumpAndSettle();
  expect(router.state.uri.path, AppRoutes.reviewsLocation);
  expect(find.byType(CustomerReviewsScreen), findsOneWidget);
  expect(reviews.listCalls, 1);
  return _Rig(
    container,
    router,
    auth,
    reviews,
    AppLocalizations.of(tester.element(find.byType(CustomerReviewsScreen))),
  );
}

final class _Rig {
  const _Rig(this.container, this.router, this.auth, this.reviews, this.l10n);
  final ProviderContainer container;
  final GoRouter router;
  final _SessionRepository auth;
  final _PendingReviews reviews;
  final AppLocalizations l10n;
}

AuthenticatedCustomer _customer(String subjectId) =>
    AuthenticatedCustomer.fromUntrustedIdentity(
      subjectId: subjectId,
      email: null,
      metadata: const {},
    );

final class _CallbackSource implements AuthCallbackSource {
  final _events = StreamController<Uri>.broadcast();
  @override
  Stream<Uri> get callbacks => _events.stream;
  @override
  Future<void> dispose() => _events.close();
}

final class _SessionRepository implements AuthRepository {
  _SessionRepository(this.currentCustomer);
  final _events = StreamController<AuthSessionEvent>.broadcast();
  @override
  AuthenticatedCustomer? currentCustomer;
  @override
  Stream<AuthSessionEvent> get sessionChanges => _events.stream;
  void expire() {
    currentCustomer = null;
    _events.add(
      const AuthSessionEvent(
        type: AuthSessionEventType.signedOut,
        customer: null,
        signOutReason: AuthSignOutReason.sessionExpired,
      ),
    );
  }

  void signIn(AuthenticatedCustomer customer) {
    currentCustomer = customer;
    _events.add(
      AuthSessionEvent(type: AuthSessionEventType.signedIn, customer: customer),
    );
  }

  @override
  Future<void> beginSignOut() async {}
  @override
  Future<void> completeSignOut() => signOutLocal();
  @override
  Future<void> signOutLocal() async {
    currentCustomer = null;
  }

  @override
  Future<void> retryPendingRemoteRevocations() async {}
  @override
  Future<void> clearPendingOAuth() async {}
  @override
  Future<bool> launchGoogleSignIn() async => true;
  @override
  Future<AuthenticatedCustomer> exchangeCodeForSession(String _) async =>
      currentCustomer ?? _customer(_ownerB);
  Future<void> dispose() => _events.close();
}

final class _PendingReviews implements CustomerReviewRepository {
  final delegate = Task054ReviewRepository(Task054VisualState.loaded);
  final attempts = <Completer<CustomerReviewMutation>>[];
  int listCalls = 0;
  @override
  Future<CustomerReviewsAccount> listMine({required String shopSlug}) {
    listCalls++;
    return delegate.listMine(shopSlug: shopSlug);
  }

  Future<CustomerReviewMutation> _pending() {
    final value = Completer<CustomerReviewMutation>();
    attempts.add(value);
    return value.future;
  }

  @override
  Future<CustomerReviewMutation> submit({
    required String orderItemId,
    required int rating,
    required String? comment,
  }) => _pending();
  @override
  Future<CustomerReviewMutation> update({
    required String reviewId,
    required int expectedVersion,
    required int rating,
    required String? comment,
    required bool withdraw,
  }) => _pending();
  @override
  Future<StorefrontProductReviews> listProduct({
    required String shopSlug,
    required String publicationId,
    StorefrontReviewCursor? cursor,
    int pageSize = 20,
  }) => delegate.listProduct(
    shopSlug: shopSlug,
    publicationId: publicationId,
    cursor: cursor,
    pageSize: pageSize,
  );
}
