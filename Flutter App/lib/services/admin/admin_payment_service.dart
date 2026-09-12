import '../../core/api_client.dart';
import 'admin_order_service.dart';

class AdminPaymentService {
  AdminPaymentService({
    required this.apiClient,
    required this.adminOrderService,
  });

  final ApiClient apiClient;
  final AdminOrderService adminOrderService;

  Future<List<AdminPaymentRecord>> getPayments(String token) async {
    final response = await apiClient.getJson(
      '/payments/list',
      headers: _headers(token),
    );
    if (response is! List) {
      throw const FormatException('Unexpected payments response.');
    }
    final payments = response
        .whereType<Map<String, dynamic>>()
        .map(AdminPayment.fromJson)
        .toList(growable: false);
    final orders = await _loadOrders(token, payments);
    final records = payments
        .map(
          (payment) =>
              AdminPaymentRecord(payment, orders[payment.orderId], null),
        )
        .toList(growable: false);
    records.sort(AdminPaymentRecord.newestFirst);
    return records;
  }

  Future<AdminPaymentRecord> getPayment(String token, int id) async {
    final response = await apiClient.getJson(
      '/payments/$id',
      headers: _headers(token),
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Unexpected payment response.');
    }
    final payment = AdminPayment.fromJson(response);
    AdminOrder? order;
    AdminInvoiceSummary? invoice;
    if (payment.orderId != null) {
      try {
        order = await adminOrderService.getOrder(token, payment.orderId!);
      } catch (_) {}
    }
    if (payment.invoiceId != null) {
      try {
        final raw = await apiClient.getJson(
          '/invoices/${payment.invoiceId}',
          headers: _headers(token),
        );
        if (raw is Map<String, dynamic>) {
          invoice = AdminInvoiceSummary.fromJson(raw);
        }
      } catch (_) {}
    }
    return AdminPaymentRecord(payment, order, invoice);
  }

  Future<List<AdminPayment>> getPaymentsByOrder(String token, int orderId) =>
      _getPaymentList(token, '/payments/by-order/$orderId');

  Future<List<AdminPayment>> getPaymentsByInvoice(
    String token,
    int invoiceId,
  ) => _getPaymentList(token, '/payments/by-invoice/$invoiceId');

  Future<AdminPayment> createPayment(
    String token,
    AdminPaymentInput input,
  ) async {
    final response = await apiClient.postJson(
      '/payments/create',
      headers: _headers(token),
      body: input.toJson(),
    );
    return AdminPayment.fromJson(response);
  }

  Future<AdminPayment> updatePayment(
    String token,
    int id,
    AdminPaymentInput input,
  ) async {
    final response = await apiClient.putJson(
      '/payments/update/$id',
      headers: _headers(token),
      body: input.toJson(),
    );
    return AdminPayment.fromJson(response);
  }

  Future<void> deletePayment(String token, int id) =>
      apiClient.delete('/payments/delete/$id', headers: _headers(token));

  Future<List<AdminPayment>> _getPaymentList(String token, String path) async {
    final response = await apiClient.getJson(path, headers: _headers(token));
    if (response is! List) {
      throw const FormatException('Unexpected payments response.');
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map(AdminPayment.fromJson)
        .toList(growable: false);
  }

  Future<Map<int, AdminOrder>> _loadOrders(
    String token,
    List<AdminPayment> payments,
  ) async {
    final ids = payments
        .map((payment) => payment.orderId)
        .whereType<int>()
        .toSet();
    final entries = await Future.wait(
      ids.map((id) async {
        try {
          return MapEntry(id, await adminOrderService.getOrder(token, id));
        } catch (_) {
          return null;
        }
      }),
    );
    return Map.fromEntries(entries.whereType<MapEntry<int, AdminOrder>>());
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
  };
}

class AdminPayment {
  const AdminPayment({
    this.id,
    this.invoiceId,
    this.orderId,
    this.customerName,
    this.amount = 0,
    this.paymentMethod,
    this.transactionId,
    this.paymentStatus,
    this.paymentDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? invoiceId;
  final int? orderId;
  final String? customerName;
  final double amount;
  final String? paymentMethod;
  final String? transactionId;
  final String? paymentStatus;
  final DateTime? paymentDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayId => id == null ? '—' : 'PAY-$id';
  String get displayStatus => paymentStatus?.trim().isNotEmpty == true
      ? paymentStatus!.trim()
      : 'Pending';
  String get normalizedStatus => displayStatus.toLowerCase();

  factory AdminPayment.fromJson(Map<String, dynamic> json) => AdminPayment(
    id: _int(json['id']),
    invoiceId: _int(json['invoiceId']),
    orderId: _int(json['orderId']),
    customerName: _string(json['customerName']),
    amount: _double(json['amount']),
    paymentMethod: _string(json['paymentMethod']),
    transactionId: _string(json['transactionId']),
    paymentStatus: _string(json['paymentStatus']),
    paymentDate: _date(json['paymentDate']),
    notes: _string(json['notes']),
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
  );

  AdminPaymentInput toInput({
    required String status,
    required String transactionId,
    required String notes,
  }) => AdminPaymentInput(
    invoiceId: invoiceId,
    orderId: orderId,
    customerName: customerName,
    amount: amount,
    paymentMethod: paymentMethod,
    transactionId: transactionId,
    paymentStatus: status,
    paymentDate: paymentDate,
    notes: notes,
  );
}

class AdminPaymentInput {
  const AdminPaymentInput({
    required this.invoiceId,
    required this.orderId,
    required this.customerName,
    required this.amount,
    required this.paymentMethod,
    required this.transactionId,
    required this.paymentStatus,
    required this.paymentDate,
    required this.notes,
  });
  final int? invoiceId;
  final int? orderId;
  final String? customerName;
  final double amount;
  final String? paymentMethod;
  final String transactionId;
  final String paymentStatus;
  final DateTime? paymentDate;
  final String notes;

  Map<String, dynamic> toJson() => {
    'invoiceId': invoiceId,
    'orderId': orderId,
    'customerName': customerName,
    'amount': amount,
    'paymentMethod': paymentMethod,
    'transactionId': transactionId.trim(),
    'paymentStatus': paymentStatus,
    'paymentDate': paymentDate == null ? null : _datePayload(paymentDate!),
    'notes': notes.trim(),
  };
}

class AdminInvoiceSummary {
  const AdminInvoiceSummary({
    this.id,
    this.number,
    this.orderReference,
    this.customerName,
    this.customerEmail,
    this.totalAmount = 0,
    this.paymentStatus,
    this.paymentMethod,
    this.issueDate,
    this.dueDate,
    this.notes,
  });
  final int? id;
  final String? number;
  final String? orderReference;
  final String? customerName;
  final String? customerEmail;
  final double totalAmount;
  final String? paymentStatus;
  final String? paymentMethod;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final String? notes;

  factory AdminInvoiceSummary.fromJson(Map<String, dynamic> json) =>
      AdminInvoiceSummary(
        id: _int(json['id']),
        number: _string(json['invoiceNumber']),
        orderReference: _string(json['orderReference']),
        customerName: _string(json['customerName']),
        customerEmail: _string(json['customerEmail']),
        totalAmount: _double(json['totalAmount'] ?? json['finalTotal']),
        paymentStatus: _string(json['paymentStatus']),
        paymentMethod: _string(json['paymentMethod']),
        issueDate: _date(json['issueDate']),
        dueDate: _date(json['dueDate']),
        notes: _string(json['notes']),
      );
}

class AdminPaymentRecord {
  const AdminPaymentRecord(this.payment, this.order, this.invoice);
  final AdminPayment payment;
  final AdminOrder? order;
  final AdminInvoiceSummary? invoice;
  String get orderReference =>
      order?.reference ??
      invoice?.orderReference ??
      '${payment.orderId ?? '—'}';
  String get customerName =>
      payment.customerName ??
      order?.customerName ??
      invoice?.customerName ??
      'Unknown customer';
  String? get customerEmail => order?.customerEmail ?? invoice?.customerEmail;

  static int newestFirst(AdminPaymentRecord a, AdminPaymentRecord b) {
    final date =
        (b.payment.paymentDate ?? b.payment.createdAt ?? DateTime(1970))
            .compareTo(
              a.payment.paymentDate ?? a.payment.createdAt ?? DateTime(1970),
            );
    return date != 0 ? date : (b.payment.id ?? 0).compareTo(a.payment.id ?? 0);
  }
}

int? _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
double _double(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
String? _string(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _date(dynamic value) {
  final text = _string(value);
  return text == null ? null : DateTime.tryParse(text);
}

String _datePayload(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
