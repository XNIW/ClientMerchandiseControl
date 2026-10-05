import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_radii.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/config/app_config.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../account/application/customer_account_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../application/customer_review_providers.dart';
import '../domain/customer_review_models.dart';
import '../domain/customer_review_repository.dart';

final class StorefrontProductReviewsSection extends ConsumerStatefulWidget {
  const StorefrontProductReviewsSection({
    required this.publicationId,
    super.key,
  });

  final String publicationId;

  @override
  ConsumerState<StorefrontProductReviewsSection> createState() =>
      _StorefrontProductReviewsSectionState();
}

final class _StorefrontProductReviewsSectionState
    extends ConsumerState<StorefrontProductReviewsSection> {
  StorefrontProductReviews? _value;
  var _isLoading = false;
  var _hasFailure = false;
  var _generation = 0;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(() => _load(reset: true));
  }

  @override
  void didUpdateWidget(StorefrontProductReviewsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.publicationId != widget.publicationId) {
      _generation++;
      _value = null;
      _isLoading = false;
      _hasFailure = false;
      scheduleMicrotask(() => _load(reset: true));
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (!mounted || _isLoading) return;
    final current = _value;
    final cursor = reset ? null : current?.nextCursor;
    if (!reset && current != null && cursor == null) return;
    final shopSlug = ref.read(appConfigProvider).storefrontShopSlug;
    if (shopSlug == null) {
      if (mounted) setState(() => _hasFailure = true);
      return;
    }
    final generation = ++_generation;
    setState(() {
      _isLoading = true;
      _hasFailure = false;
    });
    try {
      final page = await ref
          .read(customerReviewRepositoryProvider)
          .listProduct(
            shopSlug: shopSlug,
            publicationId: widget.publicationId,
            cursor: cursor,
          );
      if (!mounted || generation != _generation) return;
      final combined = reset || current == null
          ? page.items
          : [
              ...current.items,
              ...page.items.where(
                (item) =>
                    current.items.every((existing) => existing.id != item.id),
              ),
            ];
      setState(() {
        _value = StorefrontProductReviews(
          averageRating: page.averageRating,
          publishedCount: page.publishedCount,
          distribution: page.distribution,
          items: combined,
          nextCursor: page.nextCursor,
          serverTime: page.serverTime,
        );
        _isLoading = false;
      });
    } on Object {
      if (mounted && generation == _generation) {
        setState(() {
          _isLoading = false;
          _hasFailure = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = _value;
    return Card.outlined(
      key: const ValueKey('product-reviews'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: value == null
            ? _hasFailure
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l10n.reviewsLoadFailure),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => _load(reset: true),
                          child: Text(l10n.backendRetry),
                        ),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            value.averageRating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      Text(l10n.reviewsCount(value.publishedCount)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (value.items.isEmpty)
                    Text(l10n.reviewsEmpty)
                  else
                    ...value.items.map(
                      (review) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _RatingStars(rating: review.rating),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadii.control,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_outlined, size: 16),
                                  const SizedBox(width: AppSpacing.xs),
                                  Flexible(
                                    child: Text(
                                      l10n.reviewsVerified,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelLarge,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        subtitle: review.comment == null
                            ? null
                            : Text(review.comment!),
                      ),
                    ),
                  if (_hasFailure) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Semantics(
                      liveRegion: true,
                      child: Text(l10n.reviewsLoadFailure),
                    ),
                  ],
                  if (value.nextCursor != null || _isLoading) ...[
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      key: const ValueKey('product-reviews-load-more'),
                      onPressed: _isLoading ? null : _load,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          AppSizes.minimumTouchTarget,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.reviewsLoadMore),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

final class CustomerReviewsScreen extends ConsumerStatefulWidget {
  const CustomerReviewsScreen({super.key});

  @override
  ConsumerState<CustomerReviewsScreen> createState() =>
      _CustomerReviewsScreenState();
}

final class _CustomerReviewsScreenState
    extends ConsumerState<CustomerReviewsScreen> {
  var _showEligible = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reviews = ref.watch(customerReviewsAccountProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reviewsTitle),
        leading: BackButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.accountLocation),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: true, label: Text(l10n.reviewsToReview)),
                  ButtonSegment(value: false, label: Text(l10n.reviewsMine)),
                ],
                selected: {_showEligible},
                onSelectionChanged: (value) =>
                    setState(() => _showEligible = value.single),
              ),
            ),
            Expanded(
              child: reviews.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(child: Text(l10n.reviewsLoadFailure)),
                data: (value) {
                  final empty = _showEligible
                      ? value.eligible.isEmpty
                      : value.items.isEmpty;
                  if (empty) return Center(child: Text(l10n.reviewsEmpty));
                  return RefreshIndicator.adaptive(
                    onRefresh: () =>
                        ref.refresh(customerReviewsAccountProvider.future),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: _showEligible
                          ? value.eligible
                                .map(
                                  (line) => Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.md,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            line.name,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          Text(l10n.reviewsVerified),
                                          const SizedBox(height: AppSpacing.md),
                                          FilledButton(
                                            onPressed: () =>
                                                showCustomerReviewDialog(
                                                  context,
                                                  ref,
                                                  eligible: line,
                                                ),
                                            child: Text(l10n.reviewsLeave),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList()
                          : value.items
                                .map(
                                  (review) => Card(
                                    child: ListTile(
                                      title: _RatingStars(
                                        rating: review.rating,
                                      ),
                                      subtitle: Text(
                                        [
                                          _reviewStatus(l10n, review.status),
                                          ?review.comment,
                                        ].join('\n'),
                                      ),
                                      trailing:
                                          review.status ==
                                              CustomerReviewStatus.withdrawn
                                          ? null
                                          : IconButton(
                                              tooltip: l10n.reviewsEdit,
                                              onPressed: () =>
                                                  showCustomerReviewDialog(
                                                    context,
                                                    ref,
                                                    review: review,
                                                  ),
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                              ),
                                            ),
                                    ),
                                  ),
                                )
                                .toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class CustomerOrderReviewsCard extends ConsumerWidget {
  const CustomerOrderReviewsCard({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final account = ref.watch(customerReviewsAccountProvider);
    return account.maybeWhen(
      data: (value) {
        final eligible = value.eligible
            .where((line) => line.orderId == orderId)
            .toList();
        final submitted = value.items
            .where((review) => review.orderId == orderId)
            .toList();
        if (eligible.isEmpty && submitted.isEmpty) {
          return const SizedBox.shrink();
        }
        return Card(
          key: const ValueKey('order-reviews'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.reviewsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ...eligible.map(
                  (line) => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          line.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          onPressed: () => showCustomerReviewDialog(
                            context,
                            ref,
                            eligible: line,
                          ),
                          child: Text(l10n.reviewsLeave),
                        ),
                      ],
                    ),
                  ),
                ),
                ...submitted.map(
                  (review) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(l10n.reviewsAlreadySubmitted),
                    subtitle: Text(_reviewStatus(l10n, review.status)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

Future<void> showCustomerReviewDialog(
  BuildContext context,
  WidgetRef ref, {
  CustomerReviewEligibleLine? eligible,
  CustomerReview? review,
}) async {
  assert((eligible == null) != (review == null));
  final subjectId = ref.read(customerAccountIdentityProvider)?.subjectId;
  if (subjectId == null) return;
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _CustomerReviewDialog(
      subjectId: subjectId,
      eligible: eligible,
      review: review,
    ),
  );
  if (result == true &&
      context.mounted &&
      ref.read(customerAccountIdentityProvider)?.subjectId == subjectId) {
    ref.invalidate(customerReviewsAccountProvider);
  }
}

final class _CustomerReviewDialog extends ConsumerStatefulWidget {
  const _CustomerReviewDialog({
    required this.subjectId,
    this.eligible,
    this.review,
  });

  final String subjectId;
  final CustomerReviewEligibleLine? eligible;
  final CustomerReview? review;

  @override
  ConsumerState<_CustomerReviewDialog> createState() =>
      _CustomerReviewDialogState();
}

final class _CustomerReviewDialogState
    extends ConsumerState<_CustomerReviewDialog> {
  late int _rating;
  late final TextEditingController _comment;
  final _failureKey = GlobalKey();
  var _busy = false;
  var _hasFailure = false;
  var _ownerInvalidated = false;
  PopupRoute<dynamic>? _ratingPopupRoute;

  bool get _ownerIsCurrent =>
      mounted &&
      !_ownerInvalidated &&
      ref.read(customerAccountIdentityProvider)?.subjectId == widget.subjectId;

  @override
  void initState() {
    super.initState();
    _rating = widget.review?.rating ?? 5;
    _comment = TextEditingController(text: widget.review?.comment);
    ref.listenManual(
      customerAccountIdentityProvider.select((identity) => identity?.subjectId),
      (_, subjectId) => _checkOwner(subjectId),
      fireImmediately: true,
    );
    ref.listenManual(authControllerProvider, (_, state) {
      _checkOwner(switch (state) {
        AuthAuthenticated(:final customer) => customer.subjectId,
        _ => null,
      });
    });
  }

  void _checkOwner(String? subjectId) {
    if (subjectId == widget.subjectId || _ownerInvalidated) return;
    _ownerInvalidated = true;
    scheduleMicrotask(() {
      if (!mounted) return;
      _comment.clear();
      _close(false);
    });
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save({bool withdraw = false}) async {
    if (_busy || !_ownerIsCurrent) return;
    setState(() {
      _busy = true;
      _hasFailure = false;
    });
    try {
      final comment = _comment.text.trim().isEmpty
          ? null
          : _comment.text.trim();
      final repository = ref.read(customerReviewRepositoryProvider);
      if (widget.eligible case final eligible?) {
        await repository.submit(
          orderItemId: eligible.orderItemId,
          rating: _rating,
          comment: comment,
        );
      } else {
        final review = widget.review!;
        await repository.update(
          reviewId: review.id,
          expectedVersion: review.version,
          rating: _rating,
          comment: comment,
          withdraw: withdraw,
        );
      }
      if (_ownerIsCurrent) _close(true);
    } on CustomerReviewException {
      if (_ownerIsCurrent) {
        setState(() => _hasFailure = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final failureContext = _failureKey.currentContext;
          if (_ownerIsCurrent && failureContext != null) {
            unawaited(Scrollable.ensureVisible(failureContext, alignment: 1));
          }
        });
      }
    } finally {
      if (_ownerIsCurrent) setState(() => _busy = false);
    }
  }

  void _close(bool result) {
    final route = ModalRoute.of(context);
    if (route == null || !route.isActive) return;
    final navigator = Navigator.of(context);
    final ratingPopup = _ratingPopupRoute;
    if (ratingPopup != null && ratingPopup.isActive) {
      navigator.removeRoute(ratingPopup);
    }
    _ratingPopupRoute = null;
    if (route.isCurrent) {
      navigator.pop(result);
    } else {
      navigator.removeRoute(route, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectId = ref.watch(
      customerAccountIdentityProvider.select((identity) => identity?.subjectId),
    );
    if (_ownerInvalidated || subjectId != widget.subjectId) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.reviewsLeave),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _rating,
              decoration: InputDecoration(labelText: l10n.reviewsRating),
              items: [1, 2, 3, 4, 5]
                  .map(
                    (rating) => DropdownMenuItem(
                      value: rating,
                      child: Builder(
                        builder: (itemContext) {
                          final itemRoute = ModalRoute.of(itemContext);
                          if (itemRoute is PopupRoute &&
                              itemRoute != ModalRoute.of(context)) {
                            _ratingPopupRoute = itemRoute;
                          }
                          return _RatingStars(rating: rating);
                        },
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _rating = value ?? _rating),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _comment,
              maxLength: 1000,
              maxLines: 4,
              enabled: !_busy,
              decoration: InputDecoration(labelText: l10n.reviewsComment),
            ),
            if (_hasFailure) ...[
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                key: _failureKey,
                liveRegion: true,
                child: Text(
                  l10n.reviewsFailure,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (widget.review != null)
          TextButton(
            onPressed: _busy ? null : () => _save(withdraw: true),
            child: Text(l10n.reviewsWithdraw),
          ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const ValueKey('review-submit'),
          onPressed: _busy ? null : _save,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, AppSizes.minimumTouchTarget),
          ),
          child: Text(l10n.reviewsSubmit),
        ),
      ],
    );
  }
}

final class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).reviewsRating,
    value: rating.toString(),
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          rating,
          (_) => const Icon(Icons.star, size: 18, color: Colors.amber),
        ),
      ),
    ),
  );
}

String _reviewStatus(AppLocalizations l10n, CustomerReviewStatus status) =>
    switch (status) {
      CustomerReviewStatus.pending => l10n.reviewsStatusPending,
      CustomerReviewStatus.published => l10n.reviewsStatusPublished,
      CustomerReviewStatus.rejected => l10n.reviewsStatusRejected,
      CustomerReviewStatus.withdrawn => l10n.reviewsStatusWithdrawn,
    };
