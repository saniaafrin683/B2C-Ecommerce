import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api_client.dart';
import '../../../core/auth_provider.dart';
import '../../../services/admin/admin_order_service.dart';
import '../../../widgets/admin/admin_shell.dart';
import '../../../widgets/admin/admin_section_card.dart';
import '../../../widgets/product_image.dart';

const adminOrderStatuses = [
  'Pending',
  'Confirmed',
  'Processing',
  'Shipped',
  'Delivered',
  'Cancelled',
];

class AdminOrderDetailsScreen extends StatefulWidget {
  const AdminOrderDetailsScreen({
    super.key,
    required this.orderId,
    this.initialReference,
  });

  final int orderId;
  final String? initialReference;

  @override
  State<AdminOrderDetailsScreen> createState() =>
      _AdminOrderDetailsScreenState();
}

class _AdminOrderDetailsScreenState extends State<AdminOrderDetailsScreen> {
  AdminOrder? _order;
  String? _error;
  bool _loading = true;
  bool _updating = false;
  bool _changed = false;
  bool _loadedOnce = false;

  String get _token => context.read<AuthProvider>().token ?? '';
  AdminOrderService get _service => context.read<AdminOrderService>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      _loadOrder();
    }
  }

  Future<void> _loadOrder({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final order = await _service.getOrder(_token, widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadOrder(showLoading: false);
  }

  Future<void> _updateStatus(AdminOrder order) async {
    final status = await showOrderStatusDialog(
      context,
      currentStatus: order.orderStatus,
      reference: order.reference,
    );
    if (status == null || !mounted) return;
    setState(() {
      _updating = true;
    });
    try {
      await _service.updateStatus(_token, widget.orderId, status);
      final refreshed = await _service.getOrder(_token, widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = refreshed;
        _changed = true;
        _updating = false;
      });
      _showMessage('Order status updated to $status.');
    } catch (error) {
      if (mounted) {
        setState(() {
          _updating = false;
        });
        _showMessage(
          'Unable to update order status: ${error.toString()}',
          error: true,
        );
      }
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? const Color(0xFFB91C1C) : null,
        ),
      );
  }

  void _goBack() => Navigator.of(context).pop(_changed);

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Order Details',
      activeItem: 'Orders',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _DetailsError(error: _error, onRetry: _refresh)
          : _order == null
          ? _DetailsError(error: 'Order details were empty.', onRetry: _refresh)
          : RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1300),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailsHeader(
                          order: _order!,
                          updating: _updating,
                          onBack: _goBack,
                          onUpdate: () => _updateStatus(_order!),
                        ),
                        const SizedBox(height: 22),
                        _OrderProgress(status: _order!.orderStatus),
                        const SizedBox(height: 22),
                        _InformationSections(order: _order!),
                        const SizedBox(height: 22),
                        _ItemsSection(items: _order!.items),
                        const SizedBox(height: 22),
                        _TotalsSection(order: _order!),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({
    required this.order,
    required this.updating,
    required this.onBack,
    required this.onUpdate,
  });
  final AdminOrder order;
  final bool updating;
  final VoidCallback onBack;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Flex(
      direction: constraints.maxWidth < 600 ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (constraints.maxWidth >= 600)
          Expanded(
            child: _OrderHeading(order: order, onBack: onBack),
          )
        else
          _OrderHeading(order: order, onBack: onBack),
        SizedBox(
          width: constraints.maxWidth < 600 ? 0 : 12,
          height: constraints.maxWidth < 600 ? 12 : 0,
        ),
        SizedBox(
          width: constraints.maxWidth < 600 ? double.infinity : null,
          child: FilledButton.icon(
            onPressed: updating ? null : onUpdate,
            icon: updating
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync_rounded),
            label: const Text('Update Status'),
          ),
        ),
      ],
    ),
  );
}

class _OrderHeading extends StatelessWidget {
  const _OrderHeading({required this.order, required this.onBack});

  final AdminOrder order;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      IconButton.filledTonal(
        tooltip: 'Back to orders',
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.reference ?? '#${order.id ?? '—'}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 5),
            Text(
              'Placed ${formatAdminOrderDate(order.createdAt)}',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    ],
  );
}

class _OrderProgress extends StatelessWidget {
  const _OrderProgress({required this.status});
  final String? status;

  @override
  Widget build(BuildContext context) {
    const stages = [
      'Pending',
      'Confirmed',
      'Processing',
      'Shipped',
      'Delivered',
    ];
    final normalized = status?.toLowerCase();
    final cancelled = normalized == 'cancelled';
    final currentIndex = stages.indexWhere(
      (stage) => stage.toLowerCase() == normalized,
    );
    return AdminSectionCard(
      title: 'Order Status',
      subtitle: cancelled
          ? 'This order was cancelled'
          : 'Current fulfillment progress',
      trailing: adminOrderStatusChip(status),
      child: cancelled
          ? const Row(
              children: [
                Icon(Icons.cancel_outlined, color: Color(0xFFDC2626)),
                SizedBox(width: 10),
                Text(
                  'Cancelled',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                if (compact) {
                  return Column(
                    children: List.generate(stages.length, (index) {
                      final complete = index <= currentIndex;
                      return _VerticalStage(
                        label: stages[index],
                        complete: complete,
                        last: index == stages.length - 1,
                      );
                    }),
                  );
                }
                return Row(
                  children: List.generate(stages.length, (index) {
                    final complete = index <= currentIndex;
                    return Expanded(
                      child: _HorizontalStage(
                        label: stages[index],
                        complete: complete,
                        last: index == stages.length - 1,
                      ),
                    );
                  }),
                );
              },
            ),
    );
  }
}

class _HorizontalStage extends StatelessWidget {
  const _HorizontalStage({
    required this.label,
    required this.complete,
    required this.last,
  });
  final String label;
  final bool complete;
  final bool last;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: complete
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFE2E8F0),
            ),
            child: Icon(
              complete ? Icons.check_rounded : Icons.circle,
              size: complete ? 15 : 7,
              color: complete ? Colors.white : const Color(0xFF94A3B8),
            ),
          ),
          if (!last)
            Expanded(
              child: Container(
                height: 3,
                color: complete
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFFE2E8F0),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: complete ? FontWeight.w600 : FontWeight.w400,
            color: complete ? const Color(0xFF1E40AF) : const Color(0xFF64748B),
          ),
        ),
      ),
    ],
  );
}

class _VerticalStage extends StatelessWidget {
  const _VerticalStage({
    required this.label,
    required this.complete,
    required this.last,
  });
  final String label;
  final bool complete;
  final bool last;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: complete
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
            child: Icon(
              complete ? Icons.check_rounded : Icons.circle,
              size: complete ? 15 : 7,
              color: complete ? Colors.white : const Color(0xFF94A3B8),
            ),
          ),
          if (!last)
            Container(
              width: 3,
              height: 25,
              color: complete
                  ? const Color(0xFF93C5FD)
                  : const Color(0xFFE2E8F0),
            ),
        ],
      ),
      const SizedBox(width: 12),
      Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: complete ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    ],
  );
}

class _InformationSections extends StatelessWidget {
  const _InformationSections({required this.order});
  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    final customer = AdminSectionCard(
      title: 'Customer & Shipping',
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Customer',
            value: order.customerName,
          ),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: order.customerEmail,
          ),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: order.customerPhone,
          ),
          _InfoRow(
            icon: Icons.local_shipping_outlined,
            label: 'Shipping',
            value: order.shippingAddress,
          ),
          if (order.billingAddress != null)
            _InfoRow(
              icon: Icons.receipt_outlined,
              label: 'Billing',
              value: order.billingAddress,
            ),
        ],
      ),
    );
    final payment = AdminSectionCard(
      title: 'Payment & Delivery',
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.payments_outlined,
            label: 'Method',
            value: order.paymentMethod,
          ),
          _InfoRow(
            icon: Icons.verified_outlined,
            label: 'Payment',
            value: order.paymentStatus,
          ),
          _InfoRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Tracking',
            value: order.trackingNumber,
          ),
          _InfoRow(
            icon: Icons.delivery_dining_outlined,
            label: 'Courier',
            value: order.courierName,
          ),
          _InfoRow(
            icon: Icons.inventory_2_outlined,
            label: 'Shipment',
            value: order.shipmentStatus,
          ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 800
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: customer),
                const SizedBox(width: 20),
                Expanded(child: payment),
              ],
            )
          : Column(children: [customer, const SizedBox(height: 20), payment]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, this.value});
  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        SizedBox(
          width: 75,
          child: Text(label, style: const TextStyle(color: Color(0xFF64748B))),
        ),
        Expanded(
          child: Text(
            value ?? '—',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

class _ItemsSection extends StatelessWidget {
  const _ItemsSection({required this.items});
  final List<AdminOrderItem> items;

  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Ordered Items',
    subtitle: '${items.length} line item${items.length == 1 ? '' : 's'}',
    child: items.isEmpty
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 25),
            child: Center(child: Text('No order items available.')),
          )
        : Column(
            children: items.map((item) => _OrderItemLine(item: item)).toList(),
          ),
  );
}

class _OrderItemLine extends StatelessWidget {
  const _OrderItemLine({required this.item});
  final AdminOrderItem item;

  @override
  Widget build(BuildContext context) {
    final image = SizedBox(
      width: 62,
      height: 62,
      child: ProductImage(
        imageUrl: context.read<ApiClient>().normalizeImageUrl(item.imageUrl),
        borderRadius: BorderRadius.circular(10),
      ),
    );
    final information = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name ?? 'Unnamed product',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          [
            if (item.size != null) 'Size: ${item.size}',
            if (item.color != null) 'Color: ${item.color}',
          ].join(' • '),
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
    final quantity = Text(
      '${item.quantity} × ${adminOrderMoney(item.unitPrice)}',
      style: const TextStyle(color: Color(0xFF64748B)),
    );
    final total = Text(
      adminOrderMoney(item.lineTotal),
      textAlign: TextAlign.end,
      style: const TextStyle(fontWeight: FontWeight.w700),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 560) {
            return Column(
              children: [
                Row(
                  children: [
                    image,
                    const SizedBox(width: 13),
                    Expanded(child: information),
                  ],
                ),
                const SizedBox(height: 9),
                Row(children: [quantity, const Spacer(), total]),
              ],
            );
          }
          return Row(
            children: [
              image,
              const SizedBox(width: 13),
              Expanded(child: information),
              const SizedBox(width: 10),
              quantity,
              const SizedBox(width: 18),
              SizedBox(width: 90, child: total),
            ],
          );
        },
      ),
    );
  }
}

class _TotalsSection extends StatelessWidget {
  const _TotalsSection({required this.order});
  final AdminOrder order;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: constraints.maxWidth < 430 ? constraints.maxWidth : 430,
        child: AdminSectionCard(
          title: 'Order Summary',
          child: Column(
            children: [
              _TotalRow(
                label: 'Regular subtotal',
                value: order.regularSubtotal,
              ),
              _TotalRow(
                label: 'Product discount',
                value: -order.productDiscountTotal,
              ),
              _TotalRow(label: 'Subtotal', value: order.subtotal),
              _TotalRow(label: 'Coupon discount', value: -order.couponDiscount),
              _TotalRow(label: 'Tax', value: order.tax),
              _TotalRow(label: 'Delivery', value: order.shippingCost),
              const Divider(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Final total',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    adminOrderMoney(order.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value});
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Color(0xFF64748B))),
        ),
        Text(
          adminOrderMoney(value),
          style: TextStyle(color: value < 0 ? const Color(0xFF059669) : null),
        ),
      ],
    ),
  );
}

class _DetailsError extends StatelessWidget {
  const _DetailsError({required this.error, required this.onRetry});
  final Object? error;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          size: 48,
          color: Color(0xFF64748B),
        ),
        const SizedBox(height: 12),
        const Text('Unable to load order details.'),
        const SizedBox(height: 5),
        Text(
          error.toString(),
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 14),
        FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

Future<String?> showOrderStatusDialog(
  BuildContext context, {
  String? currentStatus,
  String? reference,
}) async {
  var selected = adminOrderStatuses.firstWhere(
    (status) => status.toLowerCase() == currentStatus?.toLowerCase(),
    orElse: () => 'Pending',
  );
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Update order status'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose the new status for ${reference ?? 'this order'}. This may update payment and shipment records.',
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: selected,
                decoration: const InputDecoration(
                  labelText: 'Order status',
                  border: OutlineInputBorder(),
                ),
                items: adminOrderStatuses
                    .map(
                      (status) =>
                          DropdownMenuItem(value: status, child: Text(status)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selected = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: selected.toLowerCase() == currentStatus?.toLowerCase()
                ? null
                : () => Navigator.pop(dialogContext, selected),
            child: const Text('Confirm Update'),
          ),
        ],
      ),
    ),
  );
}

Widget adminOrderStatusChip(String? status) {
  final value = status ?? 'Unknown';
  final color = switch (value.toLowerCase()) {
    'delivered' => const Color(0xFF059669),
    'cancelled' => const Color(0xFFDC2626),
    'shipped' => const Color(0xFF2563EB),
    'processing' => const Color(0xFF7C3AED),
    'confirmed' => const Color(0xFF0891B2),
    _ => const Color(0xFFD97706),
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      value,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

Widget adminPaymentStatusChip(String? status) {
  final value = status ?? 'Unknown';
  final color = switch (value.toLowerCase()) {
    'paid' || 'completed' => const Color(0xFF059669),
    'failed' || 'cancelled' => const Color(0xFFDC2626),
    _ => const Color(0xFFD97706),
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      value,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

String adminOrderMoney(double value) {
  final prefix = value < 0 ? '-৳' : '৳';
  return '$prefix${value.abs().toStringAsFixed(2)}';
}

String formatAdminOrderDate(DateTime? value) {
  if (value == null) return '—';
  const months = [
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
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}
