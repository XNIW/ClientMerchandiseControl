import 'package:flutter/material.dart';

import '../../../core/widgets/feature_placeholder.dart';
import '../../../l10n/generated/app_localizations.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FeaturePlaceholder(
      icon: Icons.account_circle_outlined,
      title: l10n.accountTitle,
      message: l10n.accountFoundationMessage,
    );
  }
}
