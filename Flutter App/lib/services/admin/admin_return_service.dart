import '../../core/api_client.dart';
import 'admin_order_service.dart';

class AdminReturnService {
  AdminReturnService({
    required this.apiClient,
    required this.adminOrderService,
  });

  final ApiClient apiClient;
  final AdminOrderService adminOrderService;

  Future<List<AdminReturnRecord>> getReturns(String token) async {
    final response = await apiClient.getJson(
      '/returns/list',
      headers: _headers(token),
    );
    if (response is! List) {
      throw const FormatException('Unexpected returns response.');
    }

    final requests = response
        .whereType<Map<String, dynamic>>()
        .map(AdminReturnRequest.fromJson)
        .toList(growable: false);
    final orders = await _loadOrders(token, requests);
    final records = requests
        .map((request) => AdminReturnRecord(request, orders[request.orderId]))
        .toList(growable: false);
    records.sort(_newestFirst);
    return records;
  }

  Future<AdminReturnRecord> getReturn(String token, int id) async {
    final response = await apiClient.getJson(
      '/returns/$id',
      headers: _headers(token),
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Unexpected return details response.');
    }
    final request = AdminReturnRequest.fromJson(response);
    AdminOrder? order;
    if (request.orderId != null) {
      try {
        order = await adminOrderService.getOrder(token, request.orderId!);
      } catch (_) {
        // Return details remain usable when linked order enrichment fails.
      }
    }
    return AdminReturnRecord(request, order);
  }

  Future<AdminReturnRequest> updateStatus(
    String token,
    int id,
    String status, {
    String? note,
  }) async {
    final backendStatus = status.toLowerCase() == 'completed'
        ? 'Refunded'
        : status;
    final body = <String, dynamic>{'status': backendStatus};
    if (note != null) body['note'] = note.trim();
    final response = await apiClient.putJson(
      '/returns/status/$id',
      headers: _headers(token),
      body: body,
    );
    return AdminReturnRequest.fromJson(response);
  }

  Future<Map<int, AdminOrder>> _loadOrders(
    String token,
    List<AdminReturnRequest> requests,
  ) async {
    final orderIds = requests
        .map((request) => request.orderId)
        .whereType<int>()
        .toSet();
    final entries = await Future.wait(
      orderIds.map((id) async {
        try {
          return MapEntry(id, await adminOrderService.getOrder(token, id));
        } catch (_) {
          return null;
        }
      }),
    );
    return Map.fromEntries(entries.whereType<MapEntry<int, AdminOrder>>());
  }

  int _newestFirst(AdminReturnRecord a, AdminReturnRecord b) {
    final date = (b.request.requestedAt ?? DateTime(1970)).compareTo(
      a.request.requestedAt ?? DateTime(1970),
    );
    return date != 0 ? date : (b.request.id ?? 0).compareTo(a.request.id ?? 0);
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
  };
}

class AdminReturnRequest {
  const AdminReturnRequest({
    this.id,
    this.orderId,
    this.customerId,
    this.productId,
    this.reason,
    this.note,
    this.adminNote,
    this.status,
    this.requestedAt,
    this.updatedAt,
    this.approvedAt,
    this.refundAmount,
    this.orderReference,
    this.customerName,
    this.customerEmail,
    this.imageUrls = const [],
  });

  final int? id;
  final int? orderId;
  final int? customerId;
  final int? productId;
  final String? reason;
  final String? note;
  final String? adminNote;
  final String? status;
  final DateTime? requestedAt;
  final DateTime? updatedAt;
  final DateTime? approvedAt;
  final double? refundAmount;
  final String? orderReference;
  final String? customerName;
  final String? customerEmail;
  final List<String> imageUrls;

  String get normalizedStatus {
    final value = status?.trim().toLowerCase();
    if (value == null || value.isEmpty || value == 'requested') {
      return 'pending';
    }
    return value == 'refunded' ? 'completed' : value;
  }

  String get displayStatus {
    return switch (normalizedStatus) {
      'approved' => 'Approved',
      'rejected' => 'Rejected',
      'completed' => 'Completed',
      _ => 'Pending',
    };
  }

  String get displayId => id == null ? '—' : 'RET-$id';

  factory AdminReturnRequest.fromJson(Map<String, dynamic> json) {
    return AdminReturnRequest(
      id: _asInt(json['id']),
      orderId: _asInt(json['orderId']),
      customerId: _asInt(json['customerId']),
      productId: _asInt(json['productId']),
      reason: _asString(json['reason']),
      note: _asString(json['customerNote'] ?? json['note'] ?? json['remarks']),
      adminNote: _asString(
        json['adminNote'] ??
            json['moderatorNote'] ??
            json['resolutionNote'] ??
            json['note'],
      ),
      status: _asString(json['status']),
      requestedAt: _asDate(json['requestedAt'] ?? json['requestedDate']),
      updatedAt: _asDate(json['updatedAt']),
      approvedAt: _asDate(json['approvedAt'] ?? json['approvedDate']),
      refundAmount: _asNullableDouble(
        json['refundAmount'] ?? json['refundedAmount'],
      ),
      orderReference: _asString(json['orderReference']),
      customerName: _asString(json['customerName']),
      customerEmail: _asString(json['customerEmail']),
      imageUrls: _extractImages(json),
    );
  }
}

class AdminReturnRecord {
  const AdminReturnRecord(this.request, this.order);

  final AdminReturnRequest request;
  final AdminOrder? order;

  String get orderReference =>
      request.orderReference ?? order?.reference ?? '${request.orderId ?? '—'}';
  String get customerName =>
      request.customerName ?? order?.customerName ?? 'Unknown customer';
  String? get customerEmail => request.customerEmail ?? order?.customerEmail;

  List<AdminOrderItem> get products {
    final items = order?.items ?? const <AdminOrderItem>[];
    final productId = request.productId;
    if (productId == null) return items;
    return items.where((item) => item.productId == productId).toList();
  }

  int get quantity => products.fold(0, (total, item) => total + item.quantity);
  String get productSummary {
    if (products.isEmpty) {
      return request.productId == null
          ? 'Order products unavailable'
          : 'Product #${request.productId}';
    }
    final names = products
        .map((item) => item.name)
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .toList();
    if (names.isEmpty) return 'Product #${request.productId ?? '—'}';
    return names.length == 1
        ? names.first
        : '${names.first} +${names.length - 1}';
  }
}

List<String> _extractImages(Map<String, dynamic> json) {
  final result = <String>[];
  for (final candidate in [
    json['imageUrls'],
    json['images'],
    json['returnImages'],
    json['attachments'],
  ]) {
    if (candidate is String && candidate.trim().isNotEmpty) {
      result.add(candidate.trim());
    } else if (candidate is Iterable) {
      for (final value in candidate) {
        if (value is Map) {
          final url = _asString(value['url'] ?? value['imageUrl']);
          if (url != null) result.add(url);
        } else {
          final url = _asString(value);
          if (url != null) result.add(url);
        }
      }
    }
  }
  return result.toSet().toList(growable: false);
}

int? _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  return value is num ? value.toDouble() : double.tryParse(value.toString());
}

String? _asString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _asDate(dynamic value) {
  final text = _asString(value);
  return text == null ? null : DateTime.tryParse(text);
}
