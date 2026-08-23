import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/router/app_routes.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/customer_review_providers.dart';
import '../domain/customer_review_models.dart';
import '../domain/customer_review_repository.dart';

final class StorefrontProductReviewsSection extends ConsumerWidget {
  const StorefrontProductReviewsSection({
    required this.publicationId,
    super.key,
  });

  final String publicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reviews = ref.watch(storefrontProductReviewsProvider(publicationId));
    return Card.outlined(
      key: const ValueKey('product-reviews'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: reviews.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Text(l10n.reviewsLoadFailure),
          data: (value) => Column(
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
                        Text('★' * review.rating),
                        const SizedBox(width: AppSpacing.sm),
                        Chip(
                          avatar: const Icon(Icons.verified_outlined, size: 16),
                          label: Text(l10n.reviewsVerified),
                        ),
                      ],
                    ),
                    subtitle: review.comment == null
                        ? null
                        : Text(review.comment!),
                  ),
                ),
            ],
          ),
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
                                      title: Text('★' * review.rating),
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
        ref.invalidate(
          storefrontProductReviewsProvider(eligible.publicationId),
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
        ref.invalidate(storefrontProductReviewsProvider(review.publicationId));
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
                      child: Text('★' * rating),
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

String _reviewStatus(AppLocalizations l10n, CustomerReviewStatus status) =>
    switch (status) {
      CustomerReviewStatus.pending => l10n.reviewsStatusPending,
      CustomerReviewStatus.published => l10n.reviewsStatusPublished,
      CustomerReviewStatus.rejected => l10n.reviewsStatusRejected,
      CustomerReviewStatus.withdrawn => l10n.reviewsStatusWithdrawn,
    };
