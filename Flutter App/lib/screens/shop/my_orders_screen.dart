import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_provider.dart';
import '../../models/customer_order.dart';
import '../../services/customer_commerce_service.dart';
import 'customer_order_details_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});
  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  late Future<List<CustomerOrder>> _request;

  @override
  void initState() {
    super.initState();
    _request = _load();
  }

  Future<List<CustomerOrder>> _load() => context
      .read<CustomerCommerceService>()
      .getMyOrders(context.read<AuthProvider>().token ?? '');
  Future<void> _refresh() async {
    final request = _load();
    setState(() {
      _request = request;
    });
    await request;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Orders')),
    body: FutureBuilder<List<CustomerOrder>>(
      future: _request,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _OrderListMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Unable to load orders',
            message: snapshot.error.toString(),
            action: FilledButton.tonal(
              onPressed: _refresh,
              child: const Text('Retry'),
            ),
          );
        }
        final orders = snapshot.data ?? const [];
        if (orders.isEmpty) {
          return const _OrderListMessage(
            icon: Icons.receipt_long_outlined,
            title: 'No orders yet',
            message: 'Your placed orders will appear here.',
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: order.id == null
                    ? null
                    : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CustomerOrderDetailsScreen(orderId: order.id!),
                          ),
                        );
                        if (mounted) await _refresh();
                      },
                child: Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order.reference ?? '#${order.id ?? '—'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          _OrderStatus(status: order.orderStatus),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 17,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _date(order.createdAt),
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                          const Spacer(),
                          Text(
                            '৳${order.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            order.paymentMethod ?? '—',
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                          const Spacer(),
                          const Text(
                            'View details',
                            style: TextStyle(
                              color: Color(0xFF1D4ED8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF1D4ED8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

class _OrderStatus extends StatelessWidget {
  const _OrderStatus({this.status});
  final String? status;
  @override
  Widget build(BuildContext context) {
    final value = status ?? 'Pending';
    final color = value.toLowerCase() == 'delivered'
        ? const Color(0xFF059669)
        : value.toLowerCase() == 'cancelled'
        ? const Color(0xFFDC2626)
        : const Color(0xFF2563EB);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OrderListMessage extends StatelessWidget {
  const _OrderListMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    ),
  );
}

String _date(DateTime? date) =>
    date == null ? '—' : '${date.day}/${date.month}/${date.year}';
