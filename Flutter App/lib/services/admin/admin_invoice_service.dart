import '../../core/api_client.dart';
import 'admin_order_service.dart';

class AdminInvoiceService {
  AdminInvoiceService({
    required this.apiClient,
    required this.adminOrderService,
  });

  final ApiClient apiClient;
  final AdminOrderService adminOrderService;

  Future<List<AdminInvoiceRecord>> getInvoices(String token) async {
    final response = await apiClient.getJson(
      '/invoices/list',
      headers: _headers(token),
    );
    if (response is! List) {
      throw const FormatException('Unexpected invoices response.');
    }
    final invoices = response
        .whereType<Map<String, dynamic>>()
        .map(AdminInvoice.fromJson)
        .toList(growable: false);
    final orders = await _loadOrders(token, invoices);
    final records = invoices
        .map((invoice) => AdminInvoiceRecord(invoice, orders[invoice.orderId]))
        .toList(growable: false);
    records.sort(AdminInvoiceRecord.newestFirst);
    return records;
  }

  Future<AdminInvoiceRecord> getInvoice(String token, int id) async {
    final response = await apiClient.getJson(
      '/invoices/$id',
      headers: _headers(token),
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Unexpected invoice response.');
    }
    final invoice = AdminInvoice.fromJson(response);
    AdminOrder? order;
    if (invoice.orderId != null) {
      try {
        order = await adminOrderService.getOrder(token, invoice.orderId!);
      } catch (_) {}
    }
    return AdminInvoiceRecord(invoice, order);
  }

  Future<List<AdminInvoice>> getInvoicesByOrder(
    String token,
    int orderId,
  ) async {
    final response = await apiClient.getJson(
      '/invoices/by-order/$orderId',
      headers: _headers(token),
    );
    if (response is! List) {
      throw const FormatException('Unexpected invoices response.');
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map(AdminInvoice.fromJson)
        .toList(growable: false);
  }

  Future<AdminInvoice> createInvoice(
    String token,
    AdminInvoiceInput input,
  ) async {
    final response = await apiClient.postJson(
      '/invoices/create',
      headers: _headers(token),
      body: input.toJson(),
    );
    return AdminInvoice.fromJson(response);
  }

  Future<AdminInvoice> updateInvoice(
    String token,
    int id,
    AdminInvoiceInput input,
  ) async {
    final response = await apiClient.putJson(
      '/invoices/update/$id',
      headers: _headers(token),
      body: input.toJson(),
    );
    return AdminInvoice.fromJson(response);
  }

  Future<void> deleteInvoice(String token, int id) async {
    await apiClient.delete('/invoices/delete/$id', headers: _headers(token));
  }

  Future<Map<int, AdminOrder>> _loadOrders(
    String token,
    List<AdminInvoice> invoices,
  ) async {
    final ids = invoices
        .map((invoice) => invoice.orderId)
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

class AdminInvoice {
  const AdminInvoice({
    this.id,
    this.invoiceNumber,
    this.orderId,
    this.orderReference,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.billingAddress,
    this.subtotal = 0,
    this.regularSubtotal = 0,
    this.productDiscountTotal = 0,
    this.subtotalAfterProductDiscount = 0,
    this.tax = 0,
    this.discount = 0,
    this.couponDiscount = 0,
    this.couponCode,
    this.shippingCost = 0,
    this.totalAmount = 0,
    this.status,
    this.paymentStatus,
    this.paymentMethod,
    this.issueDate,
    this.dueDate,
    this.notes,
  });

  final int? id;
  final String? invoiceNumber;
  final int? orderId;
  final String? orderReference;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? billingAddress;
  final double subtotal;
  final double regularSubtotal;
  final double productDiscountTotal;
  final double subtotalAfterProductDiscount;
  final double tax;
  final double discount;
  final double couponDiscount;
  final String? couponCode;
  final double shippingCost;
  final double totalAmount;
  final String? status;
  final String? paymentStatus;
  final String? paymentMethod;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final String? notes;

  String get displayNumber =>
      invoiceNumber?.trim().isNotEmpty == true ? invoiceNumber!.trim() : id == null
      ? '—'
      : 'INV-$id';

  String get displayStatus =>
      status?.trim().isNotEmpty == true
          ? status!.trim()
          : paymentStatus?.trim().isNotEmpty == true
          ? paymentStatus!.trim()
          : 'Pending';

  String get normalizedStatus => displayStatus.toLowerCase();

  factory AdminInvoice.fromJson(Map<String, dynamic> json) => AdminInvoice(
    id: _int(json['id']),
    invoiceNumber: _string(json['invoiceNumber']),
    orderId: _int(json['orderId']),
    orderReference: _string(json['orderReference']),
    customerName: _string(json['customerName']),
    customerEmail: _string(json['customerEmail']),
    customerPhone: _string(json['customerPhone']),
    billingAddress: _string(json['billingAddress']),
    subtotal: _double(json['subtotal']),
    regularSubtotal: _double(json['regularSubtotal']),
    productDiscountTotal: _double(json['productDiscountTotal']),
    subtotalAfterProductDiscount: _double(
      json['subtotalAfterProductDiscount'] ?? json['subtotal'],
    ),
    tax: _double(json['tax']),
    discount: _double(json['discount']),
    couponDiscount: _double(json['couponDiscount']),
    couponCode: _string(json['couponCode']),
    shippingCost: _double(json['shippingCost']),
    totalAmount: _double(json['totalAmount'] ?? json['finalTotal']),
    status: _string(json['status'] ?? json['invoiceStatus']),
    paymentStatus: _string(json['paymentStatus']),
    paymentMethod: _string(json['paymentMethod']),
    issueDate: _date(json['issueDate']),
    dueDate: _date(json['dueDate']),
    notes: _string(json['notes']),
  );

  AdminInvoiceInput toInput() => AdminInvoiceInput(
    invoiceNumber: invoiceNumber ?? '',
    orderId: orderId,
    orderReference: orderReference ?? '',
    customerName: customerName ?? '',
    customerEmail: customerEmail ?? '',
    customerPhone: customerPhone ?? '',
    billingAddress: billingAddress ?? '',
    subtotal: subtotal,
    regularSubtotal: regularSubtotal,
    productDiscountTotal: productDiscountTotal,
    subtotalAfterProductDiscount: subtotalAfterProductDiscount,
    tax: tax,
    discount: discount,
    couponDiscount: couponDiscount,
    couponCode: couponCode ?? '',
    shippingCost: shippingCost,
    totalAmount: totalAmount,
    paymentStatus: paymentStatus ?? 'Pending',
    paymentMethod: paymentMethod ?? '',
    issueDate: issueDate,
    dueDate: dueDate,
    notes: notes ?? '',
  );

  static int newestFirst(AdminInvoice a, AdminInvoice b) {
    final date = (b.issueDate ?? DateTime(1970)).compareTo(
      a.issueDate ?? DateTime(1970),
    );
    return date != 0 ? date : (b.id ?? 0).compareTo(a.id ?? 0);
  }
}

class AdminInvoiceInput {
  const AdminInvoiceInput({
    required this.invoiceNumber,
    required this.orderId,
    required this.orderReference,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.billingAddress,
    required this.subtotal,
    required this.regularSubtotal,
    required this.productDiscountTotal,
    required this.subtotalAfterProductDiscount,
    required this.tax,
    required this.discount,
    required this.couponDiscount,
    required this.couponCode,
    required this.shippingCost,
    required this.totalAmount,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.issueDate,
    required this.dueDate,
    required this.notes,
  });

  final String invoiceNumber;
  final int? orderId;
  final String orderReference;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String billingAddress;
  final double subtotal;
  final double regularSubtotal;
  final double productDiscountTotal;
  final double subtotalAfterProductDiscount;
  final double tax;
  final double discount;
  final double couponDiscount;
  final String couponCode;
  final double shippingCost;
  final double totalAmount;
  final String paymentStatus;
  final String paymentMethod;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final String notes;

  Map<String, dynamic> toJson() => {
    'invoiceNumber': invoiceNumber.trim(),
    'orderId': orderId,
    'orderReference': orderReference.trim(),
    'customerName': customerName.trim(),
    'customerEmail': customerEmail.trim(),
    'customerPhone': customerPhone.trim(),
    'billingAddress': billingAddress.trim(),
    'subtotal': subtotal,
    'regularSubtotal': regularSubtotal,
    'productDiscountTotal': productDiscountTotal,
    'subtotalAfterProductDiscount': subtotalAfterProductDiscount,
    'tax': tax,
    'discount': discount,
    'couponDiscount': couponDiscount,
    'couponCode': couponCode.trim(),
    'shippingCost': shippingCost,
    'totalAmount': totalAmount,
    'paymentStatus': paymentStatus,
    'paymentMethod': paymentMethod.trim(),
    'issueDate': issueDate == null ? null : _datePayload(issueDate!),
    'dueDate': dueDate == null ? null : _datePayload(dueDate!),
    'notes': notes.trim(),
  };
}

class AdminInvoiceRecord {
  const AdminInvoiceRecord(this.invoice, this.order);

  final AdminInvoice invoice;
  final AdminOrder? order;

  String get orderReference =>
      order?.reference ??
      invoice.orderReference ??
      (invoice.orderId == null ? '—' : '${invoice.orderId}');

  String get customerName =>
      invoice.customerName ?? order?.customerName ?? 'Unknown customer';

  String? get customerEmail => invoice.customerEmail ?? order?.customerEmail;

  String? get customerPhone => invoice.customerPhone ?? order?.customerPhone;

  List<AdminOrderItem> get items => order?.items ?? const <AdminOrderItem>[];

  static int newestFirst(AdminInvoiceRecord a, AdminInvoiceRecord b) =>
      AdminInvoice.newestFirst(a.invoice, b.invoice);
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

String _datePayload(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
