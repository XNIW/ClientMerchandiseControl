import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/customer_after_sales_models.dart';
import '../domain/customer_after_sales_repository.dart';

abstract interface class CustomerAfterSalesPort {
  Future<Object?> invoke(String function, Map<String, Object?> parameters);

  Future<void> uploadPrivate({
    required String objectPath,
    required Uint8List bytes,
    required String mimeType,
  });
}

// Lettura puntuale della superficie cliente già concessa da GRANT + FORCE RLS.
abstract interface class CustomerAfterSalesEvidenceReceiptPort {
  String? get currentOwnerId;
  Future<Object?> readEvidenceReceipt({
    required String caseId,
    required String objectPath,
  });
}

final class PlatformCustomerAfterSalesPort
    implements CustomerAfterSalesPort, CustomerAfterSalesEvidenceReceiptPort {
  PlatformCustomerAfterSalesPort(this.client);

  final SupabaseClient client;

  @override
  String? get currentOwnerId => client.auth.currentUser?.id;

  @override
  Future<Object?> readEvidenceReceipt({
    required String caseId,
    required String objectPath,
  }) => client
      .from('customer_service_case_evidence')
      .select('id,case_id,user_id,object_path,scan_status')
      .eq('case_id', caseId)
      .eq('object_path', objectPath)
      .maybeSingle();

  @override
  Future<Object?> invoke(String function, Map<String, Object?> parameters) {
    return client.rpc(function, params: parameters);
  }

  @override
  Future<void> uploadPrivate({
    required String objectPath,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    await client.storage
        .from('customer-after-sales-evidence')
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );
  }
}

final class SupabaseCustomerAfterSalesRepository
    implements CustomerAfterSalesRepository {
  SupabaseCustomerAfterSalesRepository({
    required this.port,
    this.timeout = const Duration(seconds: 12),
    this.now = DateTime.now,
  });

  final CustomerAfterSalesPort port;
  final Duration timeout;
  final DateTime Function() now;

  @override
  Future<List<CustomerAfterSalesCase>> list({required String shopSlug}) {
    return _guard(() async {
      _inputShop(shopSlug);
      final payload = _payload(
        await port.invoke('customer_after_sales_list_v1', {
          'p_shop_slug': shopSlug,
          'p_page_size': 50,
        }),
        const {'apiVersion', 'status', 'items', 'serverTime'},
        'after_sales_list',
      );
      _root(payload);
      final items = _list(
        payload,
        'items',
        50,
      ).map(_case).toList(growable: false);
      _unique(items.map((item) => item.id));
      return items;
    });
  }

  @override
  Future<CustomerAfterSalesOrderLines> listOrderLines(String orderId) {
    return _guard(() async {
      _inputUuid(orderId);
      final payload = _strict(
        await port.invoke('customer_after_sales_order_lines_v1', {
          'p_order_id': orderId,
        }),
        const {
          'apiVersion',
          'status',
          'orderId',
          'shopSlug',
          'items',
          'serverTime',
        },
        'after_sales_order_lines',
      );
      if (payload['apiVersion'] != 'customer-after-sales-order-lines.v1') {
        throw const FormatException('after_sales_order_lines_version');
      }
      final status = _string(payload, 'status');
      if (status != 'ok') throw CustomerAfterSalesException(status);
      final responseOrderId = _uuid(payload, 'orderId');
      if (responseOrderId != orderId) {
        throw const FormatException('after_sales_order_lines_identity');
      }
      final shopSlug = _string(payload, 'shopSlug');
      if (!_shopPattern.hasMatch(shopSlug)) {
        throw const FormatException('after_sales_order_lines_shop');
      }
      final items = _list(
        payload,
        'items',
        100,
      ).map(_orderLine).toList(growable: false);
      _unique(items.map((item) => item.orderItemId));
      return CustomerAfterSalesOrderLines(
        orderId: responseOrderId,
        shopSlug: shopSlug,
        items: items,
        serverTime: _date(payload, 'serverTime'),
      );
    });
  }

  @override
  Future<CustomerAfterSalesCase> create({
    required CustomerAfterSalesDraft draft,
    required String idempotencyKey,
  }) {
    return _guard(() async {
      _inputUuid(draft.orderId);
      _inputUuid(idempotencyKey);
      if (draft.lines.isEmpty || draft.lines.length > 100) {
        throw const CustomerAfterSalesException('invalid');
      }
      final note = draft.note?.trim();
      if (note != draft.note || (note != null && note.runes.length > 1000)) {
        throw const CustomerAfterSalesException('invalid');
      }
      final payload = _payload(
        await port.invoke('customer_after_sales_create_v1', {
          'p_order_id': draft.orderId,
          'p_type': draft.type.name,
          'p_reason': _reasonWire(draft.reason),
          'p_note': note,
          'p_lines': draft.lines
              .map(
                (line) => {
                  'orderItemId': line.orderItemId,
                  'quantity': line.quantity,
                },
              )
              .toList(growable: false),
          'p_idempotency_key': idempotencyKey,
        }),
        const {'apiVersion', 'status', 'idempotent', 'case', 'serverTime'},
        'after_sales_create',
      );
      _root(payload);
      if (payload['idempotent'] is! bool || payload['case'] == null) {
        throw const FormatException('after_sales_create_shape');
      }
      return _case(payload['case']);
    });
  }

  @override
  Future<CustomerAfterSalesCase> cancel({
    required String caseId,
    required int expectedVersion,
  }) {
    return _guard(() async {
      _inputUuid(caseId);
      if (expectedVersion < 1) {
        throw const CustomerAfterSalesException('invalid');
      }
      final payload = _payload(
        await port.invoke('customer_after_sales_cancel_v1', {
          'p_case_id': caseId,
          'p_expected_version': expectedVersion,
        }),
        const {'apiVersion', 'status', 'case'},
        'after_sales_cancel',
      );
      _root(payload);
      final value = _case(payload['case']);
      if (value.id != caseId) {
        throw const FormatException('after_sales_cancel_identity');
      }
      return value;
    });
  }

  @override
  Future<String> uploadEvidence({
    required String caseId,
    required CustomerAfterSalesEvidenceInput input,
  }) async {
    final transfer = input.transfer;
    if (transfer.inFlight)
      throw const CustomerAfterSalesException('evidence_ambiguous');
    final receiptPort = port is CustomerAfterSalesEvidenceReceiptPort
        ? port as CustomerAfterSalesEvidenceReceiptPort
        : null;
    final owner = input.ownerId ?? receiptPort?.currentOwnerId;
    var active = true;
    bool current() =>
        active &&
        (input.canContinue?.call() ?? true) &&
        (receiptPort == null ||
            owner != null && receiptPort.currentOwnerId == owner);
    void fence() {
      if (!current())
        throw const CustomerAfterSalesException('context_changed');
    }

    transfer.inFlight = true;
    Future<String> operation() async {
      try {
        fence();
        _inputUuid(caseId);
        final extension = input.extension.toLowerCase();
        const mimeTypes = {
          'jpg': 'image/jpeg',
          'jpeg': 'image/jpeg',
          'png': 'image/png',
          'webp': 'image/webp',
        };
        if (input.bytes.isEmpty ||
            input.bytes.lengthInBytes > 8 * 1024 * 1024 ||
            mimeTypes[extension] != input.mimeType) {
          throw const CustomerAfterSalesException('invalid_evidence');
        }
        if (transfer.evidenceId != null) return transfer.evidenceId!;
        Future<String?> receipt() async {
          if (receiptPort == null || transfer.objectPath == null) return null;
          fence();
          final raw = await receiptPort.readEvidenceReceipt(
            caseId: caseId,
            objectPath: transfer.objectPath!,
          );
          fence();
          if (raw == null) return null;
          final value = _strict(raw, const {
            'id',
            'case_id',
            'user_id',
            'object_path',
            'scan_status',
          }, 'evidence_receipt');
          if (_uuid(value, 'case_id') != caseId ||
              _uuid(value, 'user_id') != owner ||
              _string(value, 'object_path') != transfer.objectPath ||
              !const {
                'pending_scan',
                'safe',
                'rejected',
              }.contains(_string(value, 'scan_status'))) {
            throw const FormatException('evidence_receipt_identity');
          }
          return transfer.evidenceId = _uuid(value, 'id');
        }

        Future<String?> register({bool allowMissing = false}) async {
          fence();
          final value = _payload(
            await port.invoke('customer_after_sales_evidence_register_v1', {
              'p_case_id': caseId,
              'p_object_path': transfer.objectPath,
            }),
            const {'apiVersion', 'status', 'evidenceId'},
            'after_sales_evidence_register',
          );
          fence();
          if (value['apiVersion'] != 'customer-after-sales.v1')
            throw const FormatException('evidence_register_version');
          if (value['status'] == 'pending_scan' && value.length == 3)
            return transfer.evidenceId = _uuid(value, 'evidenceId');
          final found = await receipt();
          if (found != null) return found;
          if (allowMissing && value['status'] == 'invalid_evidence')
            return null;
          throw CustomerAfterSalesException(
            value['status'] is String
                ? value['status'] as String
                : 'evidence_ambiguous',
          );
        }

        if (transfer.objectPath != null) {
          final found = await receipt();
          if (found != null) return found;
          if (!transfer.expiresAt!.isAfter(now().toUtc())) {
            // Trasporto precedente terminale e receipt esatta assente: la vecchia
            // prenotazione è scaduta. Il cleanup resta di competenza backend.
            transfer.objectPath = null;
            transfer.uploadAttempted = false;
            transfer.uploaded = false;
          } else if (transfer.uploadAttempted) {
            final registered = await register(allowMissing: !transfer.uploaded);
            if (registered != null) return registered;
          }
        }
        if (transfer.objectPath == null) {
          if (transfer.ticketUncertainUntil?.isAfter(now().toUtc()) ?? false) {
            throw const CustomerAfterSalesException('evidence_ambiguous');
          }
          fence();
          // Il ticket non è idempotente: una risposta persa riserva fino a20min.
          transfer.ticketUncertainUntil = now().toUtc().add(
            const Duration(minutes: 20),
          );
          final ticket = _payload(
            await port.invoke(
              'customer_after_sales_evidence_upload_ticket_v1',
              {'p_case_id': caseId, 'p_extension': extension},
            ),
            const {
              'apiVersion',
              'status',
              'ticketId',
              'objectPath',
              'expiresAt',
            },
            'after_sales_evidence_ticket',
          );
          if (ticket['apiVersion'] == 'customer-after-sales.v1' &&
              ticket.length == 2 &&
              const {'invalid', 'not_found', 'evidence_limit_reached'}.contains(ticket['status'])) {
            transfer.ticketUncertainUntil = null;
          }
          _root(ticket);
          if (ticket.length != 5)
            throw const FormatException('after_sales_evidence_ticket_shape');
          final ticketId = _uuid(ticket, 'ticketId');
          final path = _evidenceObjectPath(ticket, caseId, extension);
          if (path.split('/')[2].split('.').first != ticketId ||
              owner != null && path.split('/').first != owner) {
            throw const FormatException('evidence_ticket_identity');
          }
          // Conservo una risposta tardiva, ma il fence vieta upload successivi.
          final expiresAt = _date(ticket, 'expiresAt');
          transfer.objectPath = path;
          transfer.expiresAt = expiresAt;
          transfer.ticketUncertainUntil = null;
          fence();
        }
        if (!transfer.expiresAt!.isAfter(now().toUtc())) {
          throw const CustomerAfterSalesException('evidence_ticket_expired');
        }
        fence();
        transfer.uploadAttempted = true;
        try {
          await port.uploadPrivate(
            objectPath: transfer.objectPath!,
            bytes: input.bytes,
            mimeType: input.mimeType,
          );
          transfer.uploaded = true;
        } on Object {
          fence();
          // Anche un errore di trasporto può seguire un upload memorizzato.
          final registered = await register(allowMissing: true);
          if (registered != null) return registered;
          throw const CustomerAfterSalesException('evidence_ambiguous');
        }
        fence();
        return (await register())!;
      } finally {
        transfer.inFlight = false;
      }
    }

    try {
      return await _guard(operation);
    } on CustomerAfterSalesException catch (error) {
      if (const {'timeout', 'offline', 'unexpected'}.contains(error.code)) {
        throw const CustomerAfterSalesException('evidence_ambiguous');
      }
      rethrow;
    } finally {
      active = false;
    }
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation().timeout(timeout);
    } on CustomerAfterSalesException {
      rethrow;
    } on TimeoutException {
      throw const CustomerAfterSalesException('timeout');
    } on SocketException {
      throw const CustomerAfterSalesException('offline');
    } on AuthException {
      throw const CustomerAfterSalesException('unauthorized');
    } on PostgrestException catch (error) {
      throw CustomerAfterSalesException(error.code ?? 'unexpected');
    } on FormatException {
      throw const CustomerAfterSalesException('unexpected');
    } on Object {
      throw const CustomerAfterSalesException('unexpected');
    }
  }
}

void _root(Map<String, Object?> payload) {
  if (payload['apiVersion'] != 'customer-after-sales.v1') {
    throw const FormatException('after_sales_version');
  }
  final status = _string(payload, 'status');
  if (status != 'ok') throw CustomerAfterSalesException(status);
}

CustomerAfterSalesCase _case(Object? raw) {
  final map = _payload(raw, const {
    'id',
    'caseCode',
    'orderId',
    'type',
    'status',
    'reason',
    'note',
    'version',
    'submittedAt',
    'updatedAt',
    'lines',
    'evidence',
    'timeline',
  }, 'after_sales_case');
  if (map.length != 13 ||
      !RegExp(r'^CS-[0-9A-F]{16}$').hasMatch(_string(map, 'caseCode'))) {
    throw const FormatException('after_sales_case_shape');
  }
  final version = _integer(map, 'version');
  final submittedAt = _date(map, 'submittedAt');
  final updatedAt = _date(map, 'updatedAt');
  final lines = _list(map, 'lines', 100).map(_line).toList(growable: false);
  final evidence = _list(
    map,
    'evidence',
    3,
  ).map(_evidence).toList(growable: false);
  final timeline = _list(
    map,
    'timeline',
    100,
  ).map(_event).toList(growable: false);
  if (version < 1 ||
      lines.isEmpty ||
      timeline.isEmpty ||
      timeline.last.version != version ||
      updatedAt.isBefore(submittedAt)) {
    throw const FormatException('after_sales_case_invariant');
  }
  return CustomerAfterSalesCase(
    id: _uuid(map, 'id'),
    caseCode: _string(map, 'caseCode'),
    orderId: _uuid(map, 'orderId'),
    type: _type(_string(map, 'type')),
    status: _status(_string(map, 'status')),
    reason: _reason(_string(map, 'reason')),
    note: _safeOptional(map, 'note', 1000),
    version: version,
    submittedAt: submittedAt,
    updatedAt: updatedAt,
    lines: lines,
    evidence: evidence,
    timeline: timeline,
  );
}

CustomerAfterSalesLine _line(Object? raw) {
  final map = _strict(raw, const {
    'id',
    'orderItemId',
    'quantity',
    'name',
  }, 'after_sales_line');
  final quantity = _integer(map, 'quantity');
  if (quantity < 1 || quantity > 99) {
    throw const FormatException('after_sales_line_quantity');
  }
  return CustomerAfterSalesLine(
    id: _uuid(map, 'id'),
    orderItemId: _uuid(map, 'orderItemId'),
    quantity: quantity,
    name: _safe(map, 'name', 200),
  );
}

CustomerAfterSalesOrderLine _orderLine(Object? raw) {
  final map = _strict(raw, const {
    'orderItemId',
    'name',
    'orderedQuantity',
    'existingOpenQuantity',
    'maximumRequestQuantity',
  }, 'after_sales_order_line');
  final orderedQuantity = _integer(map, 'orderedQuantity');
  final existingOpenQuantity = _integer(map, 'existingOpenQuantity');
  final maximumRequestQuantity = _integer(map, 'maximumRequestQuantity');
  if (orderedQuantity < 1 ||
      orderedQuantity > 99 ||
      existingOpenQuantity < 0 ||
      existingOpenQuantity > orderedQuantity ||
      maximumRequestQuantity != orderedQuantity - existingOpenQuantity) {
    throw const FormatException('after_sales_order_line_quantity');
  }
  return CustomerAfterSalesOrderLine(
    orderItemId: _uuid(map, 'orderItemId'),
    name: _safe(map, 'name', 200),
    orderedQuantity: orderedQuantity,
    existingOpenQuantity: existingOpenQuantity,
    maximumRequestQuantity: maximumRequestQuantity,
  );
}

CustomerAfterSalesEvidence _evidence(Object? raw) {
  final map = _strict(raw, const {
    'id',
    'status',
    'mimeType',
    'createdAt',
  }, 'after_sales_evidence');
  final status = _string(map, 'status');
  if (!const {'pending_scan', 'safe', 'rejected'}.contains(status)) {
    throw const FormatException('after_sales_evidence_status');
  }
  return CustomerAfterSalesEvidence(
    id: _uuid(map, 'id'),
    status: status,
    mimeType: _safeOptional(map, 'mimeType', 40),
    createdAt: _date(map, 'createdAt'),
  );
}

CustomerAfterSalesEvent _event(Object? raw) {
  final map = _payload(raw, const {
    'id',
    'version',
    'status',
    'actorKind',
    'noteKey',
    'createdAt',
  }, 'after_sales_event');
  const required = {'id', 'version', 'status', 'actorKind', 'createdAt'};
  if (!map.keys.toSet().containsAll(required)) {
    throw const FormatException('after_sales_event_shape');
  }
  final actor = _string(map, 'actorKind');
  if (!const {'customer', 'staff', 'provider', 'system'}.contains(actor)) {
    throw const FormatException('after_sales_actor');
  }
  return CustomerAfterSalesEvent(
    id: _uuid(map, 'id'),
    version: _integer(map, 'version'),
    status: _status(_string(map, 'status')),
    actorKind: actor,
    noteKey: _safeOptional(map, 'noteKey', 120),
    createdAt: _date(map, 'createdAt'),
  );
}

CustomerAfterSalesType _type(String value) => switch (value) {
  'orderProblem' => CustomerAfterSalesType.orderProblem,
  'returnRequest' => CustomerAfterSalesType.returnRequest,
  'refundRequest' => CustomerAfterSalesType.refundRequest,
  _ => throw const FormatException('after_sales_type'),
};

CustomerAfterSalesStatus _status(String value) => switch (value) {
  'submitted' => CustomerAfterSalesStatus.submitted,
  'reviewing' => CustomerAfterSalesStatus.reviewing,
  'approved' => CustomerAfterSalesStatus.approved,
  'rejected' => CustomerAfterSalesStatus.rejected,
  'returnRequired' => CustomerAfterSalesStatus.returnRequired,
  'received' => CustomerAfterSalesStatus.received,
  'refundPending' => CustomerAfterSalesStatus.refundPending,
  'refunded' => CustomerAfterSalesStatus.refunded,
  'closed' => CustomerAfterSalesStatus.closed,
  _ => throw const FormatException('after_sales_status'),
};

CustomerAfterSalesReason _reason(String value) => switch (value) {
  'damaged' => CustomerAfterSalesReason.damaged,
  'wrong_item' => CustomerAfterSalesReason.wrongItem,
  'missing_item' => CustomerAfterSalesReason.missingItem,
  'quality_issue' => CustomerAfterSalesReason.qualityIssue,
  'changed_mind' => CustomerAfterSalesReason.changedMind,
  'delivery_issue' => CustomerAfterSalesReason.deliveryIssue,
  'other' => CustomerAfterSalesReason.other,
  _ => throw const FormatException('after_sales_reason'),
};

String _reasonWire(CustomerAfterSalesReason value) => switch (value) {
  CustomerAfterSalesReason.damaged => 'damaged',
  CustomerAfterSalesReason.wrongItem => 'wrong_item',
  CustomerAfterSalesReason.missingItem => 'missing_item',
  CustomerAfterSalesReason.qualityIssue => 'quality_issue',
  CustomerAfterSalesReason.changedMind => 'changed_mind',
  CustomerAfterSalesReason.deliveryIssue => 'delivery_issue',
  CustomerAfterSalesReason.other => 'other',
};

Map<String, Object?> _payload(Object? raw, Set<String> allowed, String label) {
  if (raw is! Map) throw FormatException('${label}_map');
  final map = raw.map((key, value) => MapEntry(key.toString(), value));
  if (map.keys.any((key) => !allowed.contains(key))) {
    throw FormatException('${label}_keys');
  }
  return map;
}

Map<String, Object?> _strict(Object? raw, Set<String> keys, String label) {
  final map = _payload(raw, keys, label);
  if (map.length != keys.length) throw FormatException('${label}_shape');
  return map;
}

List<Object?> _list(Map<String, Object?> map, String key, int maximum) {
  final value = map[key];
  if (value is! List || value.length > maximum) {
    throw FormatException('after_sales_$key');
  }
  return value.cast<Object?>();
}

String _string(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('after_sales_$key');
  }
  return value;
}

String _safe(Map<String, Object?> map, String key, int maximum) {
  final value = _string(map, key);
  if (value != value.trim() ||
      value.runes.length > maximum ||
      value.contains('<')) {
    throw FormatException('after_sales_$key');
  }
  return value;
}

String? _safeOptional(Map<String, Object?> map, String key, int maximum) {
  if (!map.containsKey(key) || map[key] == null) return null;
  return _safe(map, key, maximum);
}

String _uuid(Map<String, Object?> map, String key) {
  final value = _string(map, key);
  if (!_uuidPattern.hasMatch(value)) throw FormatException('after_sales_$key');
  return value;
}

int _integer(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int) throw FormatException('after_sales_$key');
  return value;
}

DateTime _date(Map<String, Object?> map, String key) {
  final value = DateTime.tryParse(_string(map, key))?.toUtc();
  if (value == null || value.year < 2020 || value.year > 2200) {
    throw FormatException('after_sales_$key');
  }
  return value;
}

void _inputUuid(String value) {
  if (!_uuidPattern.hasMatch(value)) {
    throw const CustomerAfterSalesException('invalid');
  }
}

void _inputShop(String value) {
  if (!_shopPattern.hasMatch(value)) {
    throw const CustomerAfterSalesException('invalid');
  }
}

void _unique(Iterable<String> values) {
  final list = values.toList();
  if (list.toSet().length != list.length) {
    throw const FormatException('after_sales_duplicate');
  }
}

String _evidenceObjectPath(
  Map<String, Object?> ticket,
  String caseId,
  String extension,
) {
  final value = _string(ticket, 'objectPath');
  final parts = value.split('/');
  final fileParts = parts.length == 3 ? parts[2].split('.') : const <String>[];
  if (parts.length != 3 ||
      !_uuidPattern.hasMatch(parts[0]) ||
      parts[1] != caseId ||
      fileParts.length != 2 ||
      !_uuidPattern.hasMatch(fileParts[0]) ||
      fileParts[1] != extension) {
    throw const FormatException('after_sales_evidence_path');
  }
  return value;
}

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);
final _shopPattern = RegExp(r'^[a-z0-9][a-z0-9-]{2,62}$');
