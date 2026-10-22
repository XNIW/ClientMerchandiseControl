import 'cart_failure.dart';

/// Esito della singola azione. Non deriva da notice/failure condivisi nella UI.
enum CartActionOutcome {
  localSaved,
  accountConfirmed,
  rejected,
  pendingConfirmation,
  ignored,
  contextChanged,
}

final class CartActionResult {
  const CartActionResult({
    required this.outcome,
    required this.generation,
    required this.shopSlug,
    required this.subjectId,
    this.failureKind,
  });

  final CartActionOutcome outcome;
  final int generation;
  final String? shopSlug;
  final String? subjectId;
  final CartFailureKind? failureKind;
}
