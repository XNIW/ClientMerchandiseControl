import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_system/tokens/app_radii.dart';
import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/customer_account_controller.dart';
import '../application/customer_account_providers.dart';
import '../domain/customer_account_failure.dart';
import '../domain/customer_account_models.dart';

class CustomerAccountPanel extends ConsumerWidget {
  const CustomerAccountPanel({required this.authDisplayName, super.key});

  final String? authDisplayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerAccountControllerProvider);
    final controller = ref.read(customerAccountControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);

    return switch (state.status) {
      CustomerAccountStatus.signedOut => const SizedBox.shrink(),
      CustomerAccountStatus.loading => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Semantics(
          container: true,
          liveRegion: true,
          label: l10n.customerAccountLoading,
          child: const Center(
            child: CircularProgressIndicator(
              key: ValueKey('customer-account-loading'),
            ),
          ),
        ),
      ),
      CustomerAccountStatus.offline || CustomerAccountStatus.failure
          when state.snapshot == null =>
        _CustomerAccountLoadFailure(
          failure: state.failure,
          onRetry: controller.retry,
        ),
      _ => _CustomerAccountReady(
        state: state,
        authDisplayName: authDisplayName,
        controller: controller,
      ),
    };
  }
}

class _CustomerAccountLoadFailure extends StatelessWidget {
  const _CustomerAccountLoadFailure({
    required this.failure,
    required this.onRetry,
  });

  final CustomerAccountFailure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Column(
          key: const ValueKey('customer-account-load-failure'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.cloud_off_outlined, size: AppSizes.iconEmphasis),
            const SizedBox(height: AppSpacing.sm),
            Text(_failureMessage(l10n, failure), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              key: const ValueKey('customer-account-retry'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.customerAccountRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerAccountReady extends StatelessWidget {
  const _CustomerAccountReady({
    required this.state,
    required this.authDisplayName,
    required this.controller,
  });

  final CustomerAccountState state;
  final String? authDisplayName;
  final CustomerAccountController controller;

  @override
  Widget build(BuildContext context) {
    final snapshot = state.snapshot;
    if (snapshot == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final profile = snapshot.profile;

    return Column(
      key: const ValueKey('customer-account-ready'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        const Divider(),
        if (state.status == CustomerAccountStatus.offline ||
            state.failure?.kind == CustomerAccountFailureKind.offline) ...[
          _InlineAccountStatus(
            icon: Icons.cloud_off_outlined,
            message: l10n.customerAccountOffline,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (state.notice != null) ...[
          _InlineAccountStatus(
            key: ValueKey('customer-account-notice-${state.noticeRevision}'),
            icon: state.notice == CustomerAccountNoticeKind.actionFailed
                ? Icons.error_outline
                : Icons.check_circle_outline,
            message: state.notice == CustomerAccountNoticeKind.actionFailed
                ? _failureMessage(l10n, state.failure)
                : _noticeMessage(l10n, state.notice!),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _ProfileSection(
          key: ValueKey(
            'profile-${profile?.updatedAt.toIso8601String() ?? 'new'}',
          ),
          profile: profile,
          initialDisplayName: profile?.displayName ?? authDisplayName,
          isBusy: state.isMutating,
          onSave: controller.saveProfile,
          onDelete: profile == null
              ? null
              : () async {
                  final confirmed = await _confirm(
                    context,
                    title: l10n.customerProfileResetTitle,
                    message: l10n.customerProfileResetMessage,
                    action: l10n.customerProfileResetAction,
                  );
                  if (confirmed) {
                    await controller.deleteProfile();
                  }
                },
        ),
        const SizedBox(height: AppSpacing.xl),
        const Divider(),
        _AddressSection(
          addresses: snapshot.addresses,
          isBusy: state.isMutating,
          onCreate: (draft) => controller.createAddress(draft),
          onUpdate: controller.updateAddress,
          onDelete: (address) async {
            final confirmed = await _confirm(
              context,
              title: l10n.customerAddressDeleteTitle,
              message: l10n.customerAddressDeleteMessage(address.label),
              action: l10n.customerAddressDeleteAction,
            );
            if (confirmed) {
              await controller.deleteAddress(address.id);
            }
          },
          onSetDefault: controller.setDefaultAddress,
        ),
        const SizedBox(height: AppSpacing.xl),
        const Divider(),
        _PrivacySection(
          profile: profile,
          deletionRequest: snapshot.deletionRequest,
          isBusy: state.isMutating,
          onConsentChanged: controller.recordPrivacyConsent,
          onExport: () async {
            await controller.exportData();
            if (!context.mounted) {
              return;
            }
            final export = ProviderScope.containerOf(context).read(
              customerAccountControllerProvider.select((value) => value.export),
            );
            if (export != null) {
              await _showExport(context, export);
              controller.clearExport();
            }
          },
          onRequestDeletion: () async {
            final confirmed = await _confirm(
              context,
              title: l10n.customerDeletionConfirmTitle,
              message: l10n.customerDeletionConfirmMessage,
              action: l10n.customerDeletionRequestAction,
            );
            if (confirmed) {
              await controller.requestAccountDeletion();
            }
          },
          onCancelDeletion: snapshot.deletionRequest?.canCancel ?? false
              ? () => controller.cancelAccountDeletion(
                  snapshot.deletionRequest!.id,
                )
              : null,
        ),
        if (state.isMutating) ...[
          const SizedBox(height: AppSpacing.md),
          const LinearProgressIndicator(
            key: ValueKey('customer-account-mutation-progress'),
          ),
        ],
      ],
    );
  }
}

class _ProfileSection extends StatefulWidget {
  const _ProfileSection({
    required this.profile,
    required this.initialDisplayName,
    required this.isBusy,
    required this.onSave,
    required this.onDelete,
    super.key,
  });

  final CustomerProfile? profile;
  final String? initialDisplayName;
  final bool isBusy;
  final Future<void> Function(CustomerProfileDraft draft) onSave;
  final Future<void> Function()? onDelete;

  @override
  State<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<_ProfileSection> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _locale;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialDisplayName);
    _locale = widget.profile?.locale ?? 'es-CL';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeading(
            icon: Icons.badge_outlined,
            title: l10n.customerProfileTitle,
            message: l10n.customerProfileDescription,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: const ValueKey('customer-profile-name'),
            controller: _nameController,
            enabled: !widget.isBusy,
            maxLength: 120,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.customerProfileNameLabel,
              hintText: l10n.customerProfileNameHint,
            ),
            validator: (value) =>
                _optionalFieldValidator(l10n, value, maxRunes: 120),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            key: const ValueKey('customer-profile-locale'),
            initialValue: _locale,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.customerProfileLanguageLabel,
            ),
            items: [
              DropdownMenuItem(
                value: 'es-CL',
                child: Text(l10n.customerProfileLanguageEsCl),
              ),
              DropdownMenuItem(
                value: 'it',
                child: Text(l10n.customerProfileLanguageIt),
              ),
              DropdownMenuItem(
                value: 'en',
                child: Text(l10n.customerProfileLanguageEn),
              ),
              DropdownMenuItem(
                value: 'zh-Hans',
                child: Text(l10n.customerProfileLanguageZhHans),
              ),
            ],
            onChanged: widget.isBusy
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _locale = value);
                    }
                  },
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.end,
            children: [
              if (widget.onDelete != null)
                TextButton.icon(
                  key: const ValueKey('customer-profile-reset'),
                  onPressed: widget.isBusy ? null : widget.onDelete,
                  icon: const Icon(Icons.restart_alt),
                  label: Text(l10n.customerProfileResetAction),
                ),
              FilledButton.icon(
                key: const ValueKey('customer-profile-save'),
                onPressed: widget.isBusy
                    ? null
                    : () async {
                        if (!(_formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        try {
                          final draft = CustomerProfileDraft(
                            displayName: _nameController.text,
                            locale: _locale,
                          );
                          await widget.onSave(draft);
                        } on CustomerAccountInputException {
                          _formKey.currentState?.validate();
                        }
                      },
                icon: const Icon(Icons.save_outlined),
                label: Text(l10n.customerProfileSave),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressSection extends StatelessWidget {
  const _AddressSection({
    required this.addresses,
    required this.isBusy,
    required this.onCreate,
    required this.onUpdate,
    required this.onDelete,
    required this.onSetDefault,
  });

  final List<CustomerAddress> addresses;
  final bool isBusy;
  final Future<void> Function(CustomerAddressDraft draft) onCreate;
  final Future<void> Function(String addressId, CustomerAddressDraft draft)
  onUpdate;
  final Future<void> Function(CustomerAddress address) onDelete;
  final Future<void> Function(String addressId) onSetDefault;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(
          icon: Icons.location_on_outlined,
          title: l10n.customerAddressesTitle,
          message: l10n.customerAddressesDescription,
          trailing: IconButton.filledTonal(
            key: const ValueKey('customer-address-add'),
            onPressed: isBusy
                ? null
                : () async {
                    final draft = await _showAddressEditor(context);
                    if (draft != null) {
                      await onCreate(draft);
                    }
                  },
            tooltip: l10n.customerAddressAdd,
            icon: const Icon(Icons.add_location_alt_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (addresses.isEmpty)
          _EmptySection(
            key: const ValueKey('customer-address-empty'),
            icon: Icons.add_location_alt_outlined,
            title: l10n.customerAddressesEmptyTitle,
            message: l10n.customerAddressesEmptyMessage,
          )
        else
          ...addresses.map(
            (address) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _AddressTile(
                address: address,
                isBusy: isBusy,
                onEdit: () async {
                  final draft = await _showAddressEditor(
                    context,
                    address: address,
                  );
                  if (draft != null) {
                    await onUpdate(address.id, draft);
                  }
                },
                onDelete: () => onDelete(address),
                onSetDefault: address.isDefault
                    ? null
                    : () => onSetDefault(address.id),
              ),
            ),
          ),
      ],
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final CustomerAddress address;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: l10n.customerAddressSemantics(
        address.label,
        address.addressLine1,
        address.commune,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadii.surface),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    address.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (address.isDefault)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(l10n.customerAddressDefault),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(address.recipientName),
              Text(address.addressLine1),
              if (address.addressLine2 != null) Text(address.addressLine2!),
              Text('${address.commune}, ${address.region}'),
              if (address.postalCode != null) Text(address.postalCode!),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                alignment: WrapAlignment.end,
                children: [
                  if (onSetDefault != null)
                    TextButton(
                      key: ValueKey('customer-address-default-${address.id}'),
                      onPressed: isBusy ? null : onSetDefault,
                      child: Text(l10n.customerAddressSetDefault),
                    ),
                  IconButton(
                    key: ValueKey('customer-address-edit-${address.id}'),
                    onPressed: isBusy ? null : onEdit,
                    tooltip: l10n.customerAddressEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    key: ValueKey('customer-address-delete-${address.id}'),
                    onPressed: isBusy ? null : onDelete,
                    tooltip: l10n.customerAddressDeleteAction,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({
    required this.profile,
    required this.deletionRequest,
    required this.isBusy,
    required this.onConsentChanged,
    required this.onExport,
    required this.onRequestDeletion,
    required this.onCancelDeletion,
  });

  final CustomerProfile? profile;
  final CustomerDeletionRequest? deletionRequest;
  final bool isBusy;
  final Future<void> Function(bool accepted) onConsentChanged;
  final Future<void> Function() onExport;
  final Future<void> Function() onRequestDeletion;
  final Future<void> Function()? onCancelDeletion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activeRequest = deletionRequest?.isActive ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(
          icon: Icons.privacy_tip_outlined,
          title: l10n.customerPrivacyTitle,
          message: l10n.customerPrivacyDescription,
        ),
        const SizedBox(height: AppSpacing.sm),
        SwitchListTile.adaptive(
          key: const ValueKey('customer-privacy-consent'),
          contentPadding: EdgeInsets.zero,
          value: profile?.hasPrivacyConsent ?? false,
          onChanged: isBusy ? null : onConsentChanged,
          title: Text(l10n.customerPrivacyConsentTitle),
          subtitle: Text(l10n.customerPrivacyConsentDescription),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          key: const ValueKey('customer-data-export'),
          onPressed: isBusy ? null : onExport,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.download_outlined),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  l10n.customerDataExportAction,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.customerDeletionTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          activeRequest
              ? l10n.customerDeletionPending
              : l10n.customerDeletionDescription,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (activeRequest && onCancelDeletion != null)
          OutlinedButton.icon(
            key: const ValueKey('customer-deletion-cancel'),
            onPressed: isBusy ? null : onCancelDeletion,
            icon: const Icon(Icons.undo),
            label: Text(l10n.customerDeletionCancelAction),
          )
        else if (!activeRequest)
          TextButton.icon(
            key: const ValueKey('customer-deletion-request'),
            onPressed: isBusy ? null : onRequestDeletion,
            icon: const Icon(Icons.person_off_outlined),
            label: Text(l10n.customerDeletionRequestAction),
          ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.message,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppSizes.iconStandard),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}

class _InlineAccountStatus extends StatelessWidget {
  const _InlineAccountStatus({
    required this.icon,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadii.surface),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(message)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          Icon(icon, size: AppSizes.iconEmphasis),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

Future<CustomerAddressDraft?> _showAddressEditor(
  BuildContext context, {
  CustomerAddress? address,
}) {
  final expectedSubjectId = ProviderScope.containerOf(
    context,
  ).read(customerAccountIdentityProvider)?.subjectId;
  if (expectedSubjectId == null) return Future.value();
  return showDialog<CustomerAddressDraft>(
    context: context,
    builder: (_) => _AuthBoundDialog(
      expectedSubjectId: expectedSubjectId,
      child: _AddressEditorDialog(address: address),
    ),
  );
}

class _AddressEditorDialog extends StatefulWidget {
  const _AddressEditorDialog({required this.address});

  final CustomerAddress? address;

  @override
  State<_AddressEditorDialog> createState() => _AddressEditorDialogState();
}

class _AddressEditorDialogState extends State<_AddressEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  var _inputInvalid = false;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _controllers = {
      'label': TextEditingController(text: address?.label),
      'recipient': TextEditingController(text: address?.recipientName),
      'line1': TextEditingController(text: address?.addressLine1),
      'line2': TextEditingController(text: address?.addressLine2),
      'commune': TextEditingController(text: address?.commune),
      'region': TextEditingController(text: address?.region),
      'postal': TextEditingController(text: address?.postalCode),
      'country': TextEditingController(text: address?.countryCode ?? 'CL'),
      'instructions': TextEditingController(
        text: address?.deliveryInstructions,
      ),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      key: const ValueKey('customer-address-dialog'),
      title: Text(
        widget.address == null
            ? l10n.customerAddressAdd
            : l10n.customerAddressEdit,
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(l10n, 'label', l10n.customerAddressLabel, 40),
                _field(l10n, 'recipient', l10n.customerAddressRecipient, 120),
                _field(l10n, 'line1', l10n.customerAddressLine1, 200),
                _field(
                  l10n,
                  'line2',
                  l10n.customerAddressLine2,
                  200,
                  optional: true,
                ),
                _field(l10n, 'commune', l10n.customerAddressCommune, 100),
                _field(l10n, 'region', l10n.customerAddressRegion, 100),
                _field(
                  l10n,
                  'postal',
                  l10n.customerAddressPostalCode,
                  16,
                  optional: true,
                ),
                _field(
                  l10n,
                  'country',
                  l10n.customerAddressCountryCode,
                  2,
                  capitalization: TextCapitalization.characters,
                ),
                _field(
                  l10n,
                  'instructions',
                  l10n.customerAddressInstructions,
                  500,
                  optional: true,
                  maxLines: 3,
                ),
                if (_inputInvalid)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      l10n.customerFieldInvalid,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.customerDialogCancel),
        ),
        FilledButton(
          key: const ValueKey('customer-address-submit'),
          onPressed: _submit,
          child: Text(l10n.customerDialogSave),
        ),
      ],
    );
  }

  Widget _field(
    AppLocalizations l10n,
    String key,
    String label,
    int maxRunes, {
    bool optional = false,
    int maxLines = 1,
    TextCapitalization capitalization = TextCapitalization.words,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextFormField(
        key: ValueKey('customer-address-field-$key'),
        controller: _controllers[key],
        maxLength: maxRunes,
        maxLines: maxLines,
        textCapitalization: capitalization,
        decoration: InputDecoration(labelText: label),
        onChanged: (_) {
          if (_inputInvalid) {
            setState(() => _inputInvalid = false);
          }
        },
        validator: (value) {
          final base = optional
              ? _optionalFieldValidator(l10n, value, maxRunes: maxRunes)
              : _requiredFieldValidator(l10n, value, maxRunes: maxRunes);
          if (base != null) {
            return base;
          }
          final normalized = value?.trim() ?? '';
          if ((key == 'country' &&
                  !RegExp(r'^[A-Za-z]{2}$').hasMatch(normalized)) ||
              (key == 'postal' &&
                  normalized.isNotEmpty &&
                  !RegExp(r'^[A-Za-z0-9 -]+$').hasMatch(normalized))) {
            return l10n.customerFieldInvalid;
          }
          return null;
        },
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    try {
      Navigator.of(context).pop(
        CustomerAddressDraft(
          label: _controllers['label']!.text,
          recipientName: _controllers['recipient']!.text,
          addressLine1: _controllers['line1']!.text,
          addressLine2: _controllers['line2']!.text,
          commune: _controllers['commune']!.text,
          region: _controllers['region']!.text,
          postalCode: _controllers['postal']!.text,
          countryCode: _controllers['country']!.text,
          deliveryInstructions: _controllers['instructions']!.text,
        ),
      );
    } on CustomerAccountInputException {
      setState(() => _inputInvalid = true);
    }
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  final expectedSubjectId = ProviderScope.containerOf(
    context,
  ).read(customerAccountIdentityProvider)?.subjectId;
  if (expectedSubjectId == null) return false;
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => _AuthBoundDialog(
          expectedSubjectId: expectedSubjectId,
          child: AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(AppLocalizations.of(context).customerDialogCancel),
              ),
              FilledButton(
                key: const ValueKey('customer-confirm-action'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(action),
              ),
            ],
          ),
        ),
      ) ??
      false;
}

Future<void> _showExport(BuildContext context, CustomerDataExport export) {
  final expectedSubjectId = ProviderScope.containerOf(
    context,
  ).read(customerAccountIdentityProvider)?.subjectId;
  if (expectedSubjectId == null) return Future.value();
  final formatted = const JsonEncoder.withIndent(
    '  ',
  ).convert(jsonDecode(export.json));
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _AuthBoundDialog(
      expectedSubjectId: expectedSubjectId,
      child: AlertDialog(
        key: const ValueKey('customer-export-dialog'),
        title: Text(l10n.customerDataExportTitle),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(child: SelectableText(formatted)),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.customerDialogClose),
          ),
        ],
      ),
    ),
  );
}

class _AuthBoundDialog extends ConsumerWidget {
  const _AuthBoundDialog({
    required this.expectedSubjectId,
    required this.child,
  });

  final String expectedSubjectId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(customerAccountIdentityProvider, (previous, next) {
      if (next?.subjectId != expectedSubjectId && context.mounted) {
        Navigator.of(context).maybePop();
      }
    });
    return child;
  }
}

String? _requiredFieldValidator(
  AppLocalizations l10n,
  String? value, {
  required int maxRunes,
}) {
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty) {
    return l10n.customerFieldRequired;
  }
  return _optionalFieldValidator(l10n, normalized, maxRunes: maxRunes);
}

String? _optionalFieldValidator(
  AppLocalizations l10n,
  String? value, {
  required int maxRunes,
}) {
  final normalized = value?.trim() ?? '';
  if (normalized.runes.length > maxRunes ||
      normalized.runes.any(
        (rune) => rune < 0x20 || (rune >= 0x7f && rune <= 0x9f),
      )) {
    return l10n.customerFieldInvalid;
  }
  return null;
}

String _failureMessage(AppLocalizations l10n, CustomerAccountFailure? failure) {
  return switch (failure?.kind) {
    CustomerAccountFailureKind.offline => l10n.customerAccountOffline,
    CustomerAccountFailureKind.unauthorized => l10n.customerAccountUnauthorized,
    CustomerAccountFailureKind.invalidInput => l10n.customerAccountInvalid,
    CustomerAccountFailureKind.conflict => l10n.customerAccountConflict,
    CustomerAccountFailureKind.timeout => l10n.customerAccountTimeout,
    CustomerAccountFailureKind.unavailable => l10n.customerAccountUnavailable,
    CustomerAccountFailureKind.unexpected ||
    null => l10n.customerAccountUnexpected,
  };
}

String _noticeMessage(AppLocalizations l10n, CustomerAccountNoticeKind notice) {
  return switch (notice) {
    CustomerAccountNoticeKind.profileSaved => l10n.customerProfileSaved,
    CustomerAccountNoticeKind.profileDeleted => l10n.customerProfileDeleted,
    CustomerAccountNoticeKind.addressSaved => l10n.customerAddressSaved,
    CustomerAccountNoticeKind.addressDeleted => l10n.customerAddressDeleted,
    CustomerAccountNoticeKind.defaultAddressChanged =>
      l10n.customerAddressDefaultChanged,
    CustomerAccountNoticeKind.consentUpdated =>
      l10n.customerPrivacyConsentUpdated,
    CustomerAccountNoticeKind.deletionRequested =>
      l10n.customerDeletionRequested,
    CustomerAccountNoticeKind.deletionCancelled =>
      l10n.customerDeletionCancelled,
    CustomerAccountNoticeKind.actionFailed => l10n.customerAccountUnexpected,
  };
}
