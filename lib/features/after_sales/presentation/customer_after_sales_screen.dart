import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/router/app_routes.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../account/application/customer_account_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/domain/authenticated_customer.dart';
import '../application/customer_after_sales_controller.dart';
import '../domain/customer_after_sales_models.dart';

final class CustomerAfterSalesScreen extends ConsumerWidget {
  const CustomerAfterSalesScreen({this.caseId, this.orderId, super.key});

  final String? caseId;
  final String? orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(customerAfterSalesControllerProvider);
    final selected = caseId == null
        ? null
        : state.cases.where((item) => item.id == caseId).firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.afterSalesTitle),
        leading: BackButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.accountLocation),
        ),
      ),
      body: SafeArea(
        top: false,
        child: orderId != null
            ? _AfterSalesCreateForm(orderId: orderId!)
            : caseId != null
            ? _AfterSalesCaseDetail(value: selected, state: state)
            : _AfterSalesList(state: state),
      ),
    );
  }
}

final class _AfterSalesList extends ConsumerWidget {
  const _AfterSalesList({required this.state});

  final CustomerAfterSalesState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (state.isLoading && state.cases.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator.adaptive(
      onRefresh: ref
          .read(customerAfterSalesControllerProvider.notifier)
          .refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (state.failure != null)
            _FailureBanner(message: l10n.afterSalesFailure),
          if (state.cases.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Column(
                children: [
                  const Icon(Icons.support_agent_outlined, size: 48),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.afterSalesEmpty, textAlign: TextAlign.center),
                ],
              ),
            )
          else
            ...state.cases.map(
              (value) => Card(
                child: ListTile(
                  minTileHeight: AppSizes.minimumTouchTarget,
                  leading: const Icon(Icons.support_agent_outlined),
                  title: Text('${l10n.afterSalesCaseCode} ${value.caseCode}'),
                  subtitle: Text(
                    '${_typeLabel(l10n, value.type)} · '
                    '${_statusLabel(l10n, value.status)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push(AppRoutes.afterSalesLocation(value.id)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final class _AfterSalesCaseDetail extends ConsumerWidget {
  const _AfterSalesCaseDetail({required this.value, required this.state});

  final CustomerAfterSalesCase? value;
  final CustomerAfterSalesState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final item = value;
    if (state.isLoading && item == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (item == null) {
      return Center(child: Text(l10n.afterSalesFailure));
    }
    return RefreshIndicator.adaptive(
      onRefresh: ref
          .read(customerAfterSalesControllerProvider.notifier)
          .refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (state.failure != null)
            _FailureBanner(message: l10n.afterSalesFailure),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item.caseCode,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(_typeLabel(l10n, item.type)),
                  Text(_reasonLabel(l10n, item.reason)),
                  Chip(label: Text(_statusLabel(l10n, item.status))),
                  if (item.note != null) Text(item.note!),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.afterSalesItems,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ...item.lines.map(
            (line) => ListTile(
              title: Text(line.name),
              trailing: Text('×${line.quantity}'),
            ),
          ),
          if (item.evidence.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.afterSalesEvidence,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ...item.evidence.map(
              (evidence) => ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text(evidence.status),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.afterSalesTimeline,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ...item.timeline.map(
            (event) => ListTile(
              leading: const Icon(Icons.circle_outlined, size: 18),
              title: Text(_statusLabel(l10n, event.status)),
              subtitle: Text(
                MaterialLocalizations.of(
                  context,
                ).formatMediumDate(event.createdAt.toLocal()),
              ),
            ),
          ),
          if (item.canCancel) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              key: const ValueKey('after-sales-cancel'),
              onPressed: state.isMutating
                  ? null
                  : () => ref
                        .read(customerAfterSalesControllerProvider.notifier)
                        .cancel(item),
              child: Text(l10n.afterSalesCancel),
            ),
          ],
        ],
      ),
    );
  }
}

final class _AfterSalesCreateForm extends ConsumerStatefulWidget {
  const _AfterSalesCreateForm({required this.orderId});

  final String orderId;

  @override
  ConsumerState<_AfterSalesCreateForm> createState() =>
      _AfterSalesCreateFormState();
}

final class _AfterSalesCreateFormState
    extends ConsumerState<_AfterSalesCreateForm> {
  final _note = TextEditingController();
  final _noteFocus = FocusNode();
  CustomerAfterSalesType _type = CustomerAfterSalesType.orderProblem;
  CustomerAfterSalesReason _reason = CustomerAfterSalesReason.damaged;
  final Map<String, int> _selected = {};
  final List<XFile> _evidence = [];
  Future<CustomerAfterSalesOrderLines>? _items;
  late final String? _owner;
  late final String? _shop;
  late final ProviderSubscription<AuthenticatedCustomer?> _identitySubscription;
  late final ProviderSubscription<String?> _shopSubscription;
  ProviderSubscription<AuthState>? _authSubscription;
  var _scopeValid = true;

  @override
  void initState() {
    super.initState();
    final container = ProviderScope.containerOf(context, listen: false);
    _owner = container.read(customerAccountIdentityProvider)?.subjectId;
    _shop = container.read(customerAccountShopSlugProvider);
    _scopeValid = _owner != null && _shop != null;
    _identitySubscription = container.listen(customerAccountIdentityProvider, (
      _,
      next,
    ) {
      if (next?.subjectId != _owner) _invalidateScope();
    });
    _shopSubscription = container.listen(customerAccountShopSlugProvider, (
      _,
      next,
    ) {
      if (next != _shop) _invalidateScope();
    });
    if (container.exists(authControllerProvider)) {
      _authSubscription = container.listen(authControllerProvider, (_, next) {
        final owner = switch (next) {
          AuthAuthenticated(:final customer) => customer.subjectId,
          _ => null,
        };
        if (owner != _owner) _invalidateScope();
      });
    }
    if (_scopeValid) {
      _items = ref
          .read(customerAfterSalesRepositoryProvider)
          .listOrderLines(widget.orderId);
    }
  }

  void _invalidateScope() {
    if (!_scopeValid || !mounted) return;
    setState(() => _scopeValid = false);
    _note.clear();
    _selected.clear();
    _evidence.clear();
    if (_noteFocus.hasFocus) _noteFocus.unfocus();
  }

  bool get _isCurrent =>
      mounted &&
      _scopeValid &&
      ref.read(customerAccountIdentityProvider)?.subjectId == _owner &&
      ref.read(customerAccountShopSlugProvider) == _shop;

  @override
  void dispose() {
    _identitySubscription.close();
    _authSubscription?.close();
    _shopSubscription.close();
    _noteFocus.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!mounted || !_isCurrent) return;
    final l10n = AppLocalizations.of(context);
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.afterSalesSelectItem)));
      return;
    }
    final value = await ref
        .read(customerAfterSalesControllerProvider.notifier)
        .create(
          CustomerAfterSalesDraft(
            orderId: widget.orderId,
            type: _type,
            reason: _reason,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            lines: _selected.entries
                .map(
                  (entry) => CustomerAfterSalesLineDraft(
                    orderItemId: entry.key,
                    quantity: entry.value,
                  ),
                )
                .toList(),
          ),
        );
    if (!mounted || !_isCurrent) return;
    if (value == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.afterSalesFailure)));
    } else {
      var uploadsPassed = true;
      for (final file in _evidence) {
        if (!mounted || !_isCurrent) return;
        final extension = file.name.split('.').last.toLowerCase();
        final mimeType = switch (extension) {
          'jpg' || 'jpeg' => 'image/jpeg',
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => '',
        };
        if (mimeType.isEmpty) {
          uploadsPassed = false;
          continue;
        }
        final bytes = await file.readAsBytes();
        if (!mounted || !_isCurrent) return;
        final passed = await ref
            .read(customerAfterSalesControllerProvider.notifier)
            .uploadEvidence(
              caseId: value.id,
              input: CustomerAfterSalesEvidenceInput(
                bytes: bytes,
                extension: extension,
                mimeType: mimeType,
              ),
            );
        if (!mounted || !_isCurrent) return;
        uploadsPassed = uploadsPassed && passed;
      }
      if (!mounted || !_isCurrent) return;
      context.go(AppRoutes.afterSalesLocation(value.id));
      unawaited(
        ref.read(customerAfterSalesControllerProvider.notifier).refresh(),
      );
      if (!uploadsPassed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.afterSalesEvidenceUploadFailure)),
        );
      }
    }
  }

  Future<void> _pickEvidence() async {
    if (!mounted || !_isCurrent) return;
    final l10n = AppLocalizations.of(context);
    try {
      final selected = await ImagePicker().pickMultiImage(
        limit: 3,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
        requestFullMetadata: false,
      );
      if (!mounted || !_isCurrent) return;
      setState(() {
        _evidence
          ..clear()
          ..addAll(selected.take(3));
      });
    } on Object {
      if (!mounted || !_isCurrent) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.afterSalesEvidencePickerFailure)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(customerAfterSalesControllerProvider);
    if (!_scopeValid) return Center(child: Text(l10n.afterSalesFailure));
    return FutureBuilder<CustomerAfterSalesOrderLines>(
      future: _items,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(child: Text(l10n.afterSalesFailure));
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            DropdownButtonFormField<CustomerAfterSalesType>(
              initialValue: _type,
              isExpanded: true,
              itemHeight: null,
              isDense: false,
              decoration: InputDecoration(labelText: l10n.afterSalesCreate),
              items: CustomerAfterSalesType.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(_typeLabel(l10n, value)),
                    ),
                  )
                  .toList(),
              onChanged: state.isMutating
                  ? null
                  : (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<CustomerAfterSalesReason>(
              initialValue: _reason,
              isExpanded: true,
              itemHeight: null,
              isDense: false,
              decoration: InputDecoration(labelText: l10n.afterSalesReason),
              items: CustomerAfterSalesReason.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(_reasonLabel(l10n, value)),
                    ),
                  )
                  .toList(),
              onChanged: state.isMutating
                  ? null
                  : (value) => setState(() => _reason = value ?? _reason),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.afterSalesItems,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ...snapshot.data!.items.map((item) {
              final selectedQuantity = _selected[item.orderItemId];
              return Semantics(
                enabled: item.canRequest && !state.isMutating,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Checkbox(
                    value: selectedQuantity != null,
                    onChanged: !item.canRequest || state.isMutating
                        ? null
                        : (checked) => setState(() {
                            if (checked ?? false) {
                              _selected[item.orderItemId] = 1;
                            } else {
                              _selected.remove(item.orderItemId);
                            }
                          }),
                  ),
                  title: Text(item.name),
                  subtitle: Text(
                    '${l10n.afterSalesQuantity}: '
                    '${item.maximumRequestQuantity}',
                  ),
                  trailing: selectedQuantity == null
                      ? null
                      : DropdownButton<int>(
                          value: selectedQuantity,
                          items: List.generate(
                            item.maximumRequestQuantity,
                            (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text('${index + 1}'),
                            ),
                          ),
                          onChanged: state.isMutating
                              ? null
                              : (value) => setState(() {
                                  if (value != null) {
                                    _selected[item.orderItemId] = value;
                                  }
                                }),
                        ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _note,
              focusNode: _noteFocus,
              maxLength: 1000,
              maxLines: 4,
              enabled: !state.isMutating,
              decoration: InputDecoration(labelText: l10n.afterSalesNote),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              key: const ValueKey('after-sales-evidence-picker'),
              onPressed: state.isMutating ? null : _pickEvidence,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(l10n.afterSalesEvidenceAttach),
            ),
            if (_evidence.isNotEmpty)
              Semantics(
                liveRegion: true,
                child: Text(
                  l10n.afterSalesEvidenceSelected(_evidence.length),
                  textAlign: TextAlign.center,
                ),
              ),
            Text(
              l10n.afterSalesEvidenceHelp,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              key: const ValueKey('after-sales-submit'),
              onPressed: state.isMutating ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSizes.minimumTouchTarget),
              ),
              child: Text(l10n.afterSalesSubmit),
            ),
          ],
        );
      },
    );
  }
}

final class _FailureBanner extends StatelessWidget {
  const _FailureBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text(message),
      ),
    ),
  );
}

String _typeLabel(AppLocalizations l10n, CustomerAfterSalesType value) =>
    switch (value) {
      CustomerAfterSalesType.orderProblem => l10n.afterSalesTypeOrderProblem,
      CustomerAfterSalesType.returnRequest => l10n.afterSalesTypeReturnRequest,
      CustomerAfterSalesType.refundRequest => l10n.afterSalesTypeRefundRequest,
    };

String _reasonLabel(
  AppLocalizations l10n,
  CustomerAfterSalesReason value,
) => switch (value) {
  CustomerAfterSalesReason.damaged => l10n.afterSalesReasonDamaged,
  CustomerAfterSalesReason.wrongItem => l10n.afterSalesReasonWrongItem,
  CustomerAfterSalesReason.missingItem => l10n.afterSalesReasonMissingItem,
  CustomerAfterSalesReason.qualityIssue => l10n.afterSalesReasonQualityIssue,
  CustomerAfterSalesReason.changedMind => l10n.afterSalesReasonChangedMind,
  CustomerAfterSalesReason.deliveryIssue => l10n.afterSalesReasonDeliveryIssue,
  CustomerAfterSalesReason.other => l10n.afterSalesReasonOther,
};

String _statusLabel(AppLocalizations l10n, CustomerAfterSalesStatus value) =>
    switch (value) {
      CustomerAfterSalesStatus.submitted => l10n.afterSalesStatusSubmitted,
      CustomerAfterSalesStatus.reviewing => l10n.afterSalesStatusReviewing,
      CustomerAfterSalesStatus.approved => l10n.afterSalesStatusApproved,
      CustomerAfterSalesStatus.rejected => l10n.afterSalesStatusRejected,
      CustomerAfterSalesStatus.returnRequired =>
        l10n.afterSalesStatusReturnRequired,
      CustomerAfterSalesStatus.received => l10n.afterSalesStatusReceived,
      CustomerAfterSalesStatus.refundPending =>
        l10n.afterSalesStatusRefundPending,
      CustomerAfterSalesStatus.refunded => l10n.afterSalesStatusRefunded,
      CustomerAfterSalesStatus.closed => l10n.afterSalesStatusClosed,
    };
