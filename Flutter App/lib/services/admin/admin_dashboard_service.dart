import '../../core/api_client.dart';
import 'admin_invoice_service.dart';
import 'admin_order_service.dart';
import 'admin_payment_service.dart';
import 'admin_return_service.dart';
import 'admin_review_service.dart';

class AdminDashboardService {
  AdminDashboardService({required this.apiClient});

  final ApiClient apiClient;

  Future<AdminDashboardData> loadDashboard(String token) async {
    final headers = <String, String>{'Authorization': 'Bearer $token'};
    final results = await Future.wait([
      _fetch('Summary', '/reports/summary', headers),
      _fetch('Orders', '/orders/list', headers),
      _fetch('Low stock', '/products/low-stock', headers),
      _fetch('Returns', '/returns/list', headers),
      _fetch('Payments', '/payments/list', headers),
      _fetch('Invoices', '/invoices/list', headers),
      _fetch('Reviews', '/reviews/list', headers),
      _fetch('Revenue trend', '/reports/revenue/monthly', headers),
      _fetch('Orders trend', '/reports/orders/monthly', headers),
      _fetch('Top products', '/reports/top-products', headers),
    ]);

    if (results.every((result) => !result.succeeded)) {
      throw const AdminDashboardException(
        'The dashboard APIs are temporarily unavailable. Please try again.',
      );
    }

    final summary = _asMap(results[0].value);
    final orders = _asMapList(
      results[1].value,
    ).map(AdminOrder.fromJson).toList();
    final lowStock = _asMapList(
      results[2].value,
    ).map(AdminLowStockProduct.fromJson).toList();
    final returns = _asMapList(
      results[3].value,
    ).map(AdminReturnRequest.fromJson).toList();
    final payments = _asMapList(
      results[4].value,
    ).map(AdminPayment.fromJson).toList();
    final invoices = _asMapList(
      results[5].value,
    ).map(AdminInvoice.fromJson).toList();
    final reviews = _asMapList(
      results[6].value,
    ).map(AdminReview.fromJson).toList();

    orders.sort(_newestOrderFirst);
    lowStock.sort((a, b) => a.stock.compareTo(b.stock));
    returns.sort(_newestReturnFirst);
    payments.sort(_newestPaymentFirst);
    invoices.sort(AdminInvoice.newestFirst);
    reviews.sort(_newestReviewFirst);

    final revenueTrend = _parseTrend(
      results[7].value,
      valueKeys: const ['revenue', 'totalRevenue', 'amount'],
    );
    final ordersTrend = _parseTrend(
      results[8].value,
      valueKeys: const ['ordersCount', 'count', 'orders'],
    );
    final topProducts = _parseTopProducts(results[9].value);

    return AdminDashboardData(
      totalProducts: _summaryInt(summary, 'totalProducts'),
      totalOrders: _summaryInt(summary, 'totalOrders', fallback: orders.length),
      totalCustomers: _summaryInt(summary, 'totalCustomers'),
      totalRevenue: _summaryDouble(
        summary,
        'totalRevenue',
        fallback: orders.fold(0, (total, order) => total + order.totalAmount),
      ),
      pendingOrders: _summaryInt(
        summary,
        'pendingOrders',
        fallback: orders.where((order) => _isPending(order.orderStatus)).length,
      ),
      lowStockProducts: _summaryInt(
        summary,
        'lowStockItems',
        fallback: lowStock.length,
      ),
      pendingReturns: returns
          .where((item) => item.normalizedStatus == 'pending')
          .length,
      pendingReviews: _summaryInt(
        summary,
        'pendingReviews',
        fallback: reviews.where((review) => review.isPending).length,
      ),
      paidPayments: results[4].succeeded
          ? payments.where((payment) => _isPaid(payment.paymentStatus)).length
          : _maxInt(
              0,
              _asInt(summary['totalPayments']) -
                  _asInt(summary['pendingPayments']),
            ),
      pendingInvoices: invoices
          .where((invoice) => !_isPaid(invoice.paymentStatus))
          .length,
      revenueTrend: revenueTrend.isNotEmpty
          ? revenueTrend
          : _deriveMonthlyRevenue(orders),
      ordersTrend: ordersTrend.isNotEmpty
          ? ordersTrend
          : _deriveMonthlyOrders(orders),
      orderStatuses: _distribution(
        orders.map((order) => order.orderStatus),
        emptyLabel: 'Pending',
      ),
      paymentStatuses: _distribution(
        payments.map((payment) => payment.paymentStatus),
        emptyLabel: 'Pending',
      ),
      returnStatuses: _distribution(
        returns.map((item) => item.displayStatus),
        emptyLabel: 'Pending',
      ),
      topProducts: topProducts.isNotEmpty
          ? topProducts
          : _deriveTopProducts(orders),
      lowStockItems: lowStock.take(6).toList(growable: false),
      recentPayments: payments.take(5).toList(growable: false),
      recentInvoices: invoices.take(5).toList(growable: false),
      recentReturns: returns.take(5).toList(growable: false),
      pendingReviewItems: reviews
          .where((review) => review.isPending)
          .take(5)
          .toList(growable: false),
      unavailableSections: results
          .where((result) => !result.succeeded)
          .map((result) => result.label)
          .toList(growable: false),
    );
  }

  Future<_DashboardFetch> _fetch(
    String label,
    String path,
    Map<String, String> headers,
  ) async {
    try {
      return _DashboardFetch(
        label,
        await apiClient.getJson(path, headers: headers),
      );
    } catch (_) {
      return _DashboardFetch(label, null, succeeded: false);
    }
  }

  static List<AdminTrendPoint> _parseTrend(
    dynamic value, {
    required List<String> valueKeys,
  }) {
    final points = <AdminTrendPoint>[];
    for (final item in _asMapList(value)) {
      final month = _text(item['month'] ?? item['label'] ?? item['period']);
      if (month == null) continue;
      dynamic rawValue;
      for (final key in valueKeys) {
        if (item[key] != null) {
          rawValue = item[key];
          break;
        }
      }
      points.add(AdminTrendPoint(_monthLabel(month), _asDouble(rawValue)));
    }
    return points.length <= 12 ? points : points.sublist(points.length - 12);
  }

  static List<AdminTopProduct> _parseTopProducts(dynamic value) {
    return _asMapList(value)
        .map(
          (item) => AdminTopProduct(
            name:
                _text(item['productName'] ?? item['name']) ?? 'Unnamed product',
            quantity: _asInt(item['totalSold'] ?? item['quantity']),
            revenue: _asDouble(item['totalRevenue'] ?? item['revenue']),
          ),
        )
        .where((item) => item.quantity > 0 || item.revenue > 0)
        .take(6)
        .toList(growable: false);
  }

  static List<AdminTrendPoint> _deriveMonthlyRevenue(List<AdminOrder> orders) {
    final totals = <String, double>{};
    for (final order in orders) {
      final date = order.createdAt;
      if (date == null) continue;
      final key = _monthKey(date);
      totals[key] = (totals[key] ?? 0) + order.totalAmount;
    }
    return _lastMonths(totals);
  }

  static List<AdminTrendPoint> _deriveMonthlyOrders(List<AdminOrder> orders) {
    final totals = <String, double>{};
    for (final order in orders) {
      final date = order.createdAt;
      if (date == null) continue;
      final key = _monthKey(date);
      totals[key] = (totals[key] ?? 0) + 1;
    }
    return _lastMonths(totals);
  }

  static List<AdminTrendPoint> _lastMonths(Map<String, double> values) {
    final keys = values.keys.toList()..sort();
    final selected = keys.length <= 12 ? keys : keys.sublist(keys.length - 12);
    return selected
        .map((key) => AdminTrendPoint(_monthLabel(key), values[key] ?? 0))
        .toList(growable: false);
  }

  static List<AdminTopProduct> _deriveTopProducts(List<AdminOrder> orders) {
    final products = <String, AdminTopProduct>{};
    for (final order in orders) {
      for (final item in order.items) {
        final name = _text(item.name) ?? 'Product #${item.productId ?? '—'}';
        final current = products[name];
        products[name] = AdminTopProduct(
          name: name,
          quantity: (current?.quantity ?? 0) + item.quantity,
          revenue: (current?.revenue ?? 0) + item.lineTotal,
        );
      }
    }
    final result = products.values.toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));
    return result.take(6).toList(growable: false);
  }

  static List<AdminDistributionItem> _distribution(
    Iterable<String?> statuses, {
    required String emptyLabel,
  }) {
    final values = <String, int>{};
    for (final status in statuses) {
      final label = _displayStatus(status, emptyLabel);
      values[label] = (values[label] ?? 0) + 1;
    }
    final result =
        values.entries
            .map((entry) => AdminDistributionItem(entry.key, entry.value))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));
    return result;
  }

  static String _displayStatus(String? value, String fallback) {
    final normalized = value?.trim().replaceAll('_', ' ').toLowerCase();
    if (normalized == null || normalized.isEmpty) return fallback;
    return normalized
        .split(' ')
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  static bool _isPending(String? status) {
    final value = status?.trim().toLowerCase() ?? '';
    return value.isEmpty || value == 'pending' || value == 'processing';
  }

  static bool _isPaid(String? status) {
    final value = status?.trim().toLowerCase() ?? '';
    return value == 'paid' ||
        value == 'completed' ||
        value == 'success' ||
        value == 'succeeded';
  }

  static int _newestOrderFirst(AdminOrder a, AdminOrder b) =>
      (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970));

  static int _newestPaymentFirst(AdminPayment a, AdminPayment b) =>
      (b.paymentDate ?? b.createdAt ?? DateTime(1970)).compareTo(
        a.paymentDate ?? a.createdAt ?? DateTime(1970),
      );

  static int _newestReturnFirst(AdminReturnRequest a, AdminReturnRequest b) =>
      (b.requestedAt ?? DateTime(1970)).compareTo(
        a.requestedAt ?? DateTime(1970),
      );

  static int _newestReviewFirst(AdminReview a, AdminReview b) =>
      (b.reviewDate ?? b.createdAt ?? DateTime(1970)).compareTo(
        a.reviewDate ?? a.createdAt ?? DateTime(1970),
      );

  static int _summaryInt(
    Map<String, dynamic> summary,
    String key, {
    int fallback = 0,
  }) => summary.containsKey(key) ? _asInt(summary[key]) : fallback;

  static double _summaryDouble(
    Map<String, dynamic> summary,
    String key, {
    double fallback = 0,
  }) => summary.containsKey(key) ? _asDouble(summary[key]) : fallback;

  static String _monthKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

  static String _monthLabel(String value) {
    final parts = value.split('-');
    final month = parts.length > 1 ? int.tryParse(parts[1]) : null;
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month == null || month < 1 || month > 12) return value;
    return '${names[month - 1]} ${parts.first.length >= 4 ? parts.first.substring(2) : parts.first}';
  }

  static Map<String, dynamic> _asMap(dynamic value) =>
      value is Map<String, dynamic> ? value : <String, dynamic>{};

  static List<Map<String, dynamic>> _asMapList(dynamic value) => value is List
      ? value.whereType<Map<String, dynamic>>().toList()
      : <Map<String, dynamic>>[];

  static int _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  static double _asDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int _maxInt(int a, int b) => a > b ? a : b;
}

class AdminDashboardData {
  const AdminDashboardData({
    required this.totalProducts,
    required this.totalOrders,
    required this.totalCustomers,
    required this.totalRevenue,
    required this.pendingOrders,
    required this.lowStockProducts,
    required this.pendingReturns,
    required this.pendingReviews,
    required this.paidPayments,
    required this.pendingInvoices,
    required this.revenueTrend,
    required this.ordersTrend,
    required this.orderStatuses,
    required this.paymentStatuses,
    required this.returnStatuses,
    required this.topProducts,
    required this.lowStockItems,
    required this.recentPayments,
    required this.recentInvoices,
    required this.recentReturns,
    required this.pendingReviewItems,
    required this.unavailableSections,
  });

  final int totalProducts;
  final int totalOrders;
  final int totalCustomers;
  final double totalRevenue;
  final int pendingOrders;
  final int lowStockProducts;
  final int pendingReturns;
  final int pendingReviews;
  final int paidPayments;
  final int pendingInvoices;
  final List<AdminTrendPoint> revenueTrend;
  final List<AdminTrendPoint> ordersTrend;
  final List<AdminDistributionItem> orderStatuses;
  final List<AdminDistributionItem> paymentStatuses;
  final List<AdminDistributionItem> returnStatuses;
  final List<AdminTopProduct> topProducts;
  final List<AdminLowStockProduct> lowStockItems;
  final List<AdminPayment> recentPayments;
  final List<AdminInvoice> recentInvoices;
  final List<AdminReturnRequest> recentReturns;
  final List<AdminReview> pendingReviewItems;
  final List<String> unavailableSections;
}

class AdminTrendPoint {
  const AdminTrendPoint(this.label, this.value);
  final String label;
  final double value;
}

class AdminDistributionItem {
  const AdminDistributionItem(this.label, this.count);
  final String label;
  final int count;
}

class AdminTopProduct {
  const AdminTopProduct({
    required this.name,
    required this.quantity,
    required this.revenue,
  });
  final String name;
  final int quantity;
  final double revenue;
}

class AdminLowStockProduct {
  const AdminLowStockProduct({required this.name, required this.stock});
  final String name;
  final int stock;

  factory AdminLowStockProduct.fromJson(Map<String, dynamic> json) =>
      AdminLowStockProduct(
        name:
            AdminDashboardService._text(json['name'] ?? json['productName']) ??
            'Unnamed product',
        stock: AdminDashboardService._asInt(
          json['stock'] ??
              json['currentStock'] ??
              json['stockQuantity'] ??
              json['quantity'],
        ),
      );
}

class AdminDashboardException implements Exception {
  const AdminDashboardException(this.message);
  final String message;
  @override
  String toString() => message;
}

class _DashboardFetch {
  const _DashboardFetch(this.label, this.value, {this.succeeded = true});
  final String label;
  final dynamic value;
  final bool succeeded;
}
