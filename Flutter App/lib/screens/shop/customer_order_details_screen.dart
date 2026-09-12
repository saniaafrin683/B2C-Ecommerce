import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/auth_provider.dart';
import '../../core/api_client.dart';
import '../../models/customer_order.dart';
import '../../services/customer_commerce_service.dart';
import '../../widgets/product_image.dart';

class CustomerOrderDetailsScreen extends StatefulWidget {
  const CustomerOrderDetailsScreen({super.key, required this.orderId});
  final int orderId;
  @override
  State<CustomerOrderDetailsScreen> createState() =>
      _CustomerOrderDetailsScreenState();
}

class _CustomerOrderDetailsScreenState
    extends State<CustomerOrderDetailsScreen> {
  late Future<_OrderDetailsData> _request;
  bool _openingInvoice = false;

  @override
  void initState() {
    super.initState();
    _request = _load();
  }

  Future<_OrderDetailsData> _load() async {
    final auth = context.read<AuthProvider>();
    final service = context.read<CustomerCommerceService>();
    final order = await service.getMyOrder(auth.token ?? '', widget.orderId);
    final reviews = order.isDelivered
        ? await _safeReviews(service, auth.token ?? '')
        : <Map<String, dynamic>>[];
    final returns = order.isDelivered && auth.customer?.id != null
        ? await _safeReturns(service, auth.token ?? '', auth.customer!.id!)
        : <Map<String, dynamic>>[];
    return _OrderDetailsData(
      order,
      reviews,
      returns
          .where((item) => _asInt(item['orderId']) == widget.orderId)
          .toList(),
    );
  }

  Future<List<Map<String, dynamic>>> _safeReviews(
    CustomerCommerceService service,
    String token,
  ) async {
    try {
      return await service.getReviewsForOrder(token, widget.orderId);
    } catch (_) {
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> _safeReturns(
    CustomerCommerceService service,
    String token,
    int customerId,
  ) async {
    try {
      return await service.getReturns(token, customerId);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _refresh() async {
    final request = _load();
    setState(() {
      _request = request;
    });
    await request;
  }

  Future<void> _invoice() async {
    setState(() => _openingInvoice = true);
    try {
      final auth = context.read<AuthProvider>();
      final bytes = await context.read<CustomerCommerceService>().getInvoice(
        auth.token ?? '',
        widget.orderId,
      );
      await Printing.layoutPdf(
        name: 'StyleOra-invoice-${widget.orderId}.pdf',
        onLayout: (_) async => bytes,
      );
    } catch (error) {
      if (mounted) _message(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _openingInvoice = false);
    }
  }

  void _message(String text, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: error ? const Color(0xFFB91C1C) : null,
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Order Details'),
      actions: [
        IconButton(
          tooltip: 'Open invoice',
          onPressed: _openingInvoice ? null : _invoice,
          icon: _openingInvoice
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.picture_as_pdf_outlined),
        ),
      ],
    ),
    body: FutureBuilder<_OrderDetailsData>(
      future: _request,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 48),
                const SizedBox(height: 10),
                Text(snapshot.error.toString()),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: _refresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final data = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _OrderHero(order: data.order),
              const SizedBox(height: 16),
              _TimelineCard(order: data.order),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Delivery',
                rows: {
                  'Customer': data.order.customerName,
                  'Phone': data.order.customerPhone,
                  'Address': data.order.shippingAddress,
                  'Tracking':
                      data.order.trackingNumber ?? data.order.shipmentStatus,
                },
              ),
              const SizedBox(height: 16),
              _ActionStateCard(
                title: 'Reviews',
                message: data.order.isDelivered
                    ? 'Reviews are available for delivered orders.'
                    : 'Reviews can only be submitted after delivery.',
                enabled: data.order.isDelivered,
              ),
              const SizedBox(height: 12),
              _ActionStateCard(
                title: 'Return Requests',
                message: data.order.isDelivered
                    ? 'Return requests are available for delivered orders.'
                    : 'Return requests can only be submitted after delivery.',
                enabled: data.order.isDelivered,
              ),
              const SizedBox(height: 16),
              Text('Items', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              ...data.order.items.map(
                (item) => _OrderItemCard(
                  item: item,
                  delivered: data.order.isDelivered,
                  reviewed: data.reviews.any(
                    (review) => _asInt(review['productId']) == item.productId,
                  ),
                  returnStatus: _returnStatus(data.returns, item.productId),
                  onReview: () => _review(item),
                  onReturn: () => _return(item),
                ),
              ),
              const SizedBox(height: 16),
              _Totals(order: data.order),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _openingInvoice ? null : _invoice,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Open Invoice PDF'),
              ),
            ],
          ),
        );
      },
    ),
  );

  Future<void> _review(CustomerOrderItem item) async {
    var rating = 5;
    final controller = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Write a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    onPressed: () => setDialogState(() => rating = index + 1),
                    icon: Icon(
                      index < rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ),
              TextField(
                controller: controller,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Your review',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
    if (submit != true || item.productId == null || !mounted) {
      controller.dispose();
      return;
    }
    if (controller.text.trim().isEmpty) {
      _message('Please write a short review.', error: true);
      controller.dispose();
      return;
    }
    try {
      final auth = context.read<AuthProvider>();
      await context.read<CustomerCommerceService>().submitReview(
        auth.token ?? '',
        widget.orderId,
        item.productId!,
        rating,
        controller.text,
      );
      if (mounted) {
        _message('Review submitted for approval.');
        await _refresh();
      }
    } catch (error) {
      if (mounted) _message(error.toString(), error: true);
    }
    controller.dispose();
  }

  Future<void> _return(CustomerOrderItem item) async {
    final reason = TextEditingController();
    final note = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request Return'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reason,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Additional details',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
    if (submit != true || item.productId == null || !mounted) {
      reason.dispose();
      note.dispose();
      return;
    }
    if (reason.text.trim().isEmpty) {
      _message('Please enter a return reason.', error: true);
      reason.dispose();
      note.dispose();
      return;
    }
    final auth = context.read<AuthProvider>();
    if (auth.customer?.id == null) {
      reason.dispose();
      note.dispose();
      return;
    }
    try {
      await context.read<CustomerCommerceService>().requestReturn(
        auth.token ?? '',
        widget.orderId,
        auth.customer!.id!,
        item.productId!,
        reason.text,
        note.text,
      );
      if (mounted) {
        _message('Return request submitted.');
        await _refresh();
      }
    } catch (error) {
      if (mounted) _message(error.toString(), error: true);
    }
    reason.dispose();
    note.dispose();
  }
}

class _OrderHero extends StatelessWidget {
  const _OrderHero({required this.order});
  final CustomerOrder order;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.reference ?? '#${order.id}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                order.paymentStatus ?? 'Payment pending',
                style: const TextStyle(color: Color(0xFFBFDBFE)),
              ),
            ],
          ),
        ),
        Text(
          order.orderStatus ?? 'Pending',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});
  final String title;
  final Map<String, String?> rows;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ...rows.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    entry.key,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
                Expanded(child: Text(entry.value ?? '—')),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ActionStateCard extends StatelessWidget {
  const _ActionStateCard({
    required this.title,
    required this.message,
    required this.enabled,
  });

  final String title;
  final String message;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          message,
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: enabled ? () {} : null,
            child: Text(enabled ? 'Available' : 'Disabled'),
          ),
        ),
      ],
    ),
  );
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final current = (order.orderStatus ?? 'Pending').trim();
    const steps = [
      'Pending',
      'Confirmed',
      'Processing',
      'Shipped',
      'Delivered',
    ];
    final currentIndex = steps.indexWhere(
      (step) => step.toLowerCase() == current.toLowerCase(),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Icon(
                        entry.key <= currentIndex
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: entry.key <= currentIndex
                            ? const Color(0xFF1D4ED8)
                            : const Color(0xFFCBD5E1),
                      ),
                      const SizedBox(width: 10),
                      Text(entry.value),
                    ],
                  ),
                ),
              ),
          if (current.toLowerCase() == 'cancelled') ...[
            const SizedBox(height: 6),
            const Text(
              'This order was cancelled.',
              style: TextStyle(color: Color(0xFFB91C1C)),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  const _OrderItemCard({
    required this.item,
    required this.delivered,
    required this.reviewed,
    required this.returnStatus,
    required this.onReview,
    required this.onReturn,
  });
  final CustomerOrderItem item;
  final bool delivered;
  final bool reviewed;
  final String? returnStatus;
  final VoidCallback onReview;
  final VoidCallback onReturn;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: ProductImage(
                imageUrl: context.read<ApiClient>().normalizeImageUrl(
                  item.imageUrl,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name ?? 'Product',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${item.quantity} × ৳${item.unitPrice.toStringAsFixed(2)}',
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Text(
              '৳${item.lineTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        if (delivered) ...[
          const Divider(height: 22),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 6,
            children: [
              if (reviewed)
                const Chip(label: Text('Reviewed'))
              else
                TextButton.icon(
                  onPressed: onReview,
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Write Review'),
                ),
              if (returnStatus != null)
                Chip(label: Text('Return: $returnStatus'))
              else
                TextButton.icon(
                  onPressed: onReturn,
                  icon: const Icon(Icons.assignment_return_outlined),
                  label: const Text('Request Return'),
                ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _Totals extends StatelessWidget {
  const _Totals({required this.order});
  final CustomerOrder order;
  @override
  Widget build(BuildContext context) => _InfoCard(
    title: 'Payment Summary',
    rows: {
      'Subtotal': '৳${order.subtotal.toStringAsFixed(2)}',
      'Product savings': '৳${order.productDiscount.toStringAsFixed(2)}',
      'Coupon discount': '৳${order.couponDiscount.toStringAsFixed(2)}',
      'Delivery': '৳${order.shippingCost.toStringAsFixed(2)}',
      'Final total': '৳${order.total.toStringAsFixed(2)}',
    },
  );
}

class _OrderDetailsData {
  const _OrderDetailsData(this.order, this.reviews, this.returns);
  final CustomerOrder order;
  final List<Map<String, dynamic>> reviews;
  final List<Map<String, dynamic>> returns;
}

int? _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value');
String? _returnStatus(List<Map<String, dynamic>> returns, int? productId) {
  for (final item in returns) {
    if (_asInt(item['productId']) == productId) {
      return item['status']?.toString() ?? 'Pending';
    }
  }
  return null;
}
