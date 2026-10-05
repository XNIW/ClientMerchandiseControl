import 'dart:async';

import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/reviews/application/customer_review_providers.dart';
import 'package:client_merchandise_control/features/reviews/domain/customer_review_models.dart';
import 'package:client_merchandise_control/features/reviews/domain/customer_review_repository.dart';
import 'package:client_merchandise_control/features/reviews/presentation/customer_reviews.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/commerce_surface_fixtures.dart';

const _draft = 'Comentario sintético conservado después de un error de envío.';

void main() {
  for (final action in ['submit', 'edit', 'withdraw']) {
    testWidgets('$action conserva bozza, errore locale e retry fino ad ACK', (
      tester,
    ) async {
      final repository = _ControlledReviews();
      final l10n = await _pump(tester, repository);
      await _open(tester, l10n, edit: action != 'submit');
      await _tap(tester, find.byType(DropdownButton<int>));
      await _tap(
        tester,
        find
            .ancestor(
              of: find
                  .byWidgetPredicate(
                    (widget) =>
                        widget is DropdownMenuItem<int> && widget.value == 3,
                  )
                  .last,
              matching: find.byType(InkWell),
            )
            .first,
      );
      await tester.enterText(_comment, _draft);
      final actionButton = action == 'withdraw'
          ? find.widgetWithText(TextButton, l10n.reviewsWithdraw)
          : _submit;
      await _tap(tester, actionButton);

      expect(repository.attempts, hasLength(1));
      expect(tester.widget<TextField>(_comment).enabled, isFalse);
      expect(tester.widget<FilledButton>(_submit).onPressed, isNull);
      await tester.tap(actionButton);
      await tester.pump();
      expect(
        repository.attempts,
        hasLength(1),
        reason: 'Nessuna write duplicata',
      );
      expect(repository.attempts.single.comment, _draft);
      expect(repository.attempts.single.rating, 3);
      expect(repository.attempts.single.withdraw, action == 'withdraw');
      if (action != 'submit') {
        expect(repository.attempts.single.expectedVersion, 1);
      }

      repository.attempts.single.result.completeError(
        const CustomerReviewException('unavailable'),
      );
      await tester.pumpAndSettle();
      _expectFailureInDialog(tester, l10n);
      expect(tester.widget<TextField>(_comment).controller!.text, _draft);
      expect(tester.widget<TextField>(_comment).enabled, isTrue);
      expect(tester.widget<FilledButton>(_submit).onPressed, isNotNull);

      await _tap(tester, actionButton);
      expect(repository.attempts, hasLength(2));
      expect(find.text(l10n.reviewsFailure), findsNothing);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(repository.attempts.last.comment, _draft);
      expect(repository.attempts.last.rating, repository.attempts.first.rating);
      expect(
        repository.attempts.last.expectedVersion,
        repository.attempts.first.expectedVersion,
      );
      repository.attempts.last.result.complete(_ack);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(repository.listCalls, 2, reason: 'Readback solo dopo ACK');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('readback fallita dopo ACK non riapre la write', (tester) async {
    final repository = _ControlledReviews()..failReadback = true;
    final l10n = await _pump(tester, repository);
    await _open(tester, l10n);
    await tester.enterText(_comment, _draft);
    await _tap(tester, _submit);
    repository.attempts.single.result.complete(_ack);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text(l10n.reviewsLoadFailure), findsOneWidget);
    expect(repository.attempts, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  for (final lateFailure in [false, true]) {
    testWidgets(
      'risposta tardiva del dialog chiuso isolata failure=$lateFailure',
      (tester) async {
        final repository = _ControlledReviews();
        final l10n = await _pump(tester, repository);
        await _open(tester, l10n);
        await tester.enterText(_comment, _draft);
        await _tap(tester, _submit);
        Navigator.of(tester.element(find.byType(AlertDialog))).pop(false);
        await tester.pumpAndSettle();
        await _open(tester, l10n);
        await tester.enterText(_comment, 'Nuova bozza sintetica');
        if (lateFailure) {
          repository.attempts.single.result.completeError(
            const CustomerReviewException('unavailable'),
          );
        } else {
          repository.attempts.single.result.complete(_ack);
        }
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          tester.widget<TextField>(_comment).controller!.text,
          'Nuova bozza sintetica',
        );
        expect(repository.listCalls, 1);
        expect(find.text(l10n.reviewsFailure), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final locale in const [
    Locale('es', 'CL'),
    Locale('it'),
    Locale('en'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ]) {
    for (final dark in [false, true]) {
      testWidgets(
        'errore modal leggibile compact200 ${locale.toLanguageTag()} dark=$dark',
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            final repository = _ControlledReviews();
            final l10n = await _pump(
              tester,
              repository,
              locale: locale,
              dark: dark,
              scale: 2,
            );
            await _open(tester, l10n);
            await tester.enterText(_comment, _draft);
            await _tap(tester, _submit);
            repository.attempts.single.result.completeError(
              const CustomerReviewException('unavailable'),
            );
            await tester.pumpAndSettle();
            _expectFailureInDialog(tester, l10n);
            final error = find.text(l10n.reviewsFailure);
            expect(error.hitTestable(), findsOneWidget);
            expect(
              tester.getSemantics(error).flagsCollection.isLiveRegion,
              isTrue,
            );
            final material = find
                .ancestor(of: error, matching: find.byType(Material))
                .first;
            expect(
              tester.getRect(material).contains(tester.getRect(error).center),
              isTrue,
              reason: 'Il messaggio resta sulla superficie visibile del dialog',
            );
            await tester.ensureVisible(_comment);
            await tester.pumpAndSettle();
            expect(tester.widget<TextField>(_comment).controller!.text, _draft);
            await tester.ensureVisible(_submit);
            await tester.pumpAndSettle();
            expect(_submit.hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }
}

Finder get _comment => find.descendant(
  of: find.byType(AlertDialog),
  matching: find.byType(TextField),
);

Finder get _submit => find.byKey(const ValueKey('review-submit'));

Future<AppLocalizations> _pump(
  WidgetTester tester,
  _ControlledReviews repository, {
  Locale locale = const Locale('es', 'CL'),
  bool dark = false,
  double scale = 1,
}) async {
  await tester.binding.setSurfaceSize(const Size(320, 568));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.binding.setSurfaceSize(null);
  });
  await tester.pumpWidget(
    Task054VisualFixtures().wrap(
      MaterialApp(
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const CustomerReviewsScreen(),
      ),
      additionalOverrides: [
        customerReviewRepositoryProvider.overrideWithValue(repository),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(
    tester.element(find.byType(CustomerReviewsScreen)),
  );
}

Future<void> _open(
  WidgetTester tester,
  AppLocalizations l10n, {
  bool edit = false,
}) async {
  if (edit) {
    await _tap(tester, find.text(l10n.reviewsMine));
    await _tap(tester, find.byTooltip(l10n.reviewsEdit));
  } else {
    await _tap(tester, find.text(l10n.reviewsLeave));
  }
  expect(find.byType(AlertDialog), findsOneWidget);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void _expectFailureInDialog(WidgetTester tester, AppLocalizations l10n) {
  expect(find.byType(AlertDialog), findsOneWidget);
  expect(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text(l10n.reviewsFailure),
    ),
    findsOneWidget,
  );
  expect(find.byType(SnackBar), findsNothing);
}

const _ack = CustomerReviewMutation(
  reviewId: task054VisualReview,
  status: CustomerReviewStatus.pending,
  version: 2,
);

final class _Attempt {
  _Attempt({
    required this.comment,
    required this.rating,
    required this.withdraw,
    this.expectedVersion,
  });

  final String? comment;
  final int rating;
  final bool withdraw;
  final int? expectedVersion;
  final result = Completer<CustomerReviewMutation>();
}

final class _ControlledReviews implements CustomerReviewRepository {
  final delegate = Task054ReviewRepository(Task054VisualState.loaded);
  final attempts = <_Attempt>[];
  int listCalls = 0;
  bool failReadback = false;

  @override
  Future<CustomerReviewsAccount> listMine({required String shopSlug}) {
    listCalls++;
    if (failReadback && listCalls > 1) {
      throw const CustomerReviewException('unavailable');
    }
    return delegate.listMine(shopSlug: shopSlug);
  }

  @override
  Future<CustomerReviewMutation> submit({
    required String orderItemId,
    required int rating,
    required String? comment,
  }) {
    final attempt = _Attempt(comment: comment, rating: rating, withdraw: false);
    attempts.add(attempt);
    return attempt.result.future;
  }

  @override
  Future<CustomerReviewMutation> update({
    required String reviewId,
    required int expectedVersion,
    required int rating,
    required String? comment,
    required bool withdraw,
  }) {
    final attempt = _Attempt(
      comment: comment,
      rating: rating,
      withdraw: withdraw,
      expectedVersion: expectedVersion,
    );
    attempts.add(attempt);
    return attempt.result.future;
  }

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
