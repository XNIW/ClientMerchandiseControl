import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/config/app_config.dart';
import '../../../l10n/generated/app_localizations.dart';
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
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        value.averageRating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(width: AppSpacing.sm),
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
                        title: Row(
                          children: [
                            _RatingStars(rating: review.rating),
                            const SizedBox(width: AppSpacing.sm),
                            Chip(
                              avatar: const Icon(
                                Icons.verified_outlined,
                                size: 16,
                              ),
                              label: Text(l10n.reviewsVerified),
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
                                    child: ListTile(
                                      title: Text(line.name),
                                      subtitle: Text(l10n.reviewsVerified),
                                      trailing: FilledButton(
                                        onPressed: () =>
                                            showCustomerReviewDialog(
                                              context,
                                              ref,
                                              eligible: line,
                                            ),
                                        child: Text(l10n.reviewsLeave),
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
                  (line) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(line.name),
                    trailing: TextButton(
                      onPressed: () => showCustomerReviewDialog(
                        context,
                        ref,
                        eligible: line,
                      ),
                      child: Text(l10n.reviewsLeave),
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
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _CustomerReviewDialog(eligible: eligible, review: review),
  );
  if (result == true) ref.invalidate(customerReviewsAccountProvider);
}

final class _CustomerReviewDialog extends ConsumerStatefulWidget {
  const _CustomerReviewDialog({this.eligible, this.review});

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
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.review?.rating ?? 5;
    _comment = TextEditingController(text: widget.review?.comment);
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save({bool withdraw = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
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
      if (mounted) Navigator.of(context).pop(true);
    } on CustomerReviewException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.reviewsFailure)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
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
                      child: _RatingStars(rating: rating),
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
