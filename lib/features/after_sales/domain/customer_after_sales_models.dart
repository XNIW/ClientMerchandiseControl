import 'dart:typed_data';

enum CustomerAfterSalesType { orderProblem, returnRequest, refundRequest }

enum CustomerAfterSalesStatus {
  submitted,
  reviewing,
  approved,
  rejected,
  returnRequired,
  received,
  refundPending,
  refunded,
  closed,
}

enum CustomerAfterSalesReason {
  damaged,
  wrongItem,
  missingItem,
  qualityIssue,
  changedMind,
  deliveryIssue,
  other,
}

final class CustomerAfterSalesLineDraft {
  const CustomerAfterSalesLineDraft({
    required this.orderItemId,
    required this.quantity,
  });

  final String orderItemId;
  final int quantity;
}

final class CustomerAfterSalesOrderLine {
  const CustomerAfterSalesOrderLine({
    required this.orderItemId,
    required this.name,
    required this.orderedQuantity,
    required this.existingOpenQuantity,
    required this.maximumRequestQuantity,
  });

  final String orderItemId;
  final String name;
  final int orderedQuantity;
  final int existingOpenQuantity;
  final int maximumRequestQuantity;

  bool get canRequest => maximumRequestQuantity > 0;
}

final class CustomerAfterSalesOrderLines {
  CustomerAfterSalesOrderLines({
    required this.orderId,
    required this.shopSlug,
    required List<CustomerAfterSalesOrderLine> items,
    required this.serverTime,
  }) : items = List.unmodifiable(items);

  final String orderId;
  final String shopSlug;
  final List<CustomerAfterSalesOrderLine> items;
  final DateTime serverTime;
}

final class CustomerAfterSalesDraft {
  CustomerAfterSalesDraft({
    required this.orderId,
    required this.type,
    required this.reason,
    required this.note,
    required List<CustomerAfterSalesLineDraft> lines,
  }) : lines = List.unmodifiable(lines);

  final String orderId;
  final CustomerAfterSalesType type;
  final CustomerAfterSalesReason reason;
  final String? note;
  final List<CustomerAfterSalesLineDraft> lines;
}

final class CustomerAfterSalesEvidenceInput {
  CustomerAfterSalesEvidenceInput({
    required this.bytes,
    required this.extension,
    required this.mimeType,
    this.ownerId,
    this.canContinue,
  });

  final String? ownerId;
  bool Function()? canContinue;
  final transfer = CustomerAfterSalesEvidenceTransfer();
  final Uint8List bytes;
  final String extension;
  final String mimeType;
}

// Checkpoint solo in memoria, legato al singolo file e al proprietario.
// Non costituisce una promessa di persistenza dei file temporanei.
final class CustomerAfterSalesEvidenceTransfer {
  String? objectPath;
  DateTime? expiresAt;
  String? evidenceId;
  bool uploadAttempted = false;
  bool uploaded = false;
  bool inFlight = false;
  DateTime? ticketUncertainUntil;
}

enum CustomerAfterSalesAttachmentStatus {
  ready,
  reading,
  uploading,
  confirmed,
  failed,
  fileUnavailable,
  invalidFile,
  ambiguous,
}

final class CustomerAfterSalesLocalAttachment {
  CustomerAfterSalesLocalAttachment({
    required this.name,
    required this.extension,
    required this.mimeType,
    required this.readBytes,
  });

  final String name;
  final String extension;
  final String mimeType;
  final Future<Uint8List> Function() readBytes;
  CustomerAfterSalesAttachmentStatus status =
      CustomerAfterSalesAttachmentStatus.ready;
  CustomerAfterSalesEvidenceInput? input;
  String? evidenceId;
}

final class CustomerAfterSalesLine {
  const CustomerAfterSalesLine({
    required this.id,
    required this.orderItemId,
    required this.quantity,
    required this.name,
  });

  final String id;
  final String orderItemId;
  final int quantity;
  final String name;
}

final class CustomerAfterSalesEvidence {
  const CustomerAfterSalesEvidence({
    required this.id,
    required this.status,
    required this.mimeType,
    required this.createdAt,
  });

  final String id;
  final String status;
  final String? mimeType;
  final DateTime createdAt;
}

final class CustomerAfterSalesEvent {
  const CustomerAfterSalesEvent({
    required this.id,
    required this.version,
    required this.status,
    required this.actorKind,
    required this.noteKey,
    required this.createdAt,
  });

  final String id;
  final int version;
  final CustomerAfterSalesStatus status;
  final String actorKind;
  final String? noteKey;
  final DateTime createdAt;
}

final class CustomerAfterSalesCase {
  CustomerAfterSalesCase({
    required this.id,
    required this.caseCode,
    required this.orderId,
    required this.type,
    required this.status,
    required this.reason,
    required this.note,
    required this.version,
    required this.submittedAt,
    required this.updatedAt,
    required List<CustomerAfterSalesLine> lines,
    required List<CustomerAfterSalesEvidence> evidence,
    required List<CustomerAfterSalesEvent> timeline,
  }) : lines = List.unmodifiable(lines),
       evidence = List.unmodifiable(evidence),
       timeline = List.unmodifiable(timeline);

  final String id;
  final String caseCode;
  final String orderId;
  final CustomerAfterSalesType type;
  final CustomerAfterSalesStatus status;
  final CustomerAfterSalesReason reason;
  final String? note;
  final int version;
  final DateTime submittedAt;
  final DateTime updatedAt;
  final List<CustomerAfterSalesLine> lines;
  final List<CustomerAfterSalesEvidence> evidence;
  final List<CustomerAfterSalesEvent> timeline;

  bool get canCancel => status == CustomerAfterSalesStatus.submitted;
  bool get canAttachEvidence => !const {CustomerAfterSalesStatus.closed, CustomerAfterSalesStatus.rejected, CustomerAfterSalesStatus.refunded}.contains(status);
}
