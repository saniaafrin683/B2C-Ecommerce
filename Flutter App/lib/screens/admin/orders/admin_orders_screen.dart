import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../services/admin/admin_order_service.dart';
import '../../../widgets/admin/admin_shell.dart';
import 'admin_order_details_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  static const routeName = '/admin/orders';

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final _searchController = TextEditingController();
  Future<List<AdminOrder>>? _request;
  String _orderStatus = 'All';
  String _paymentStatus = 'All';
  final Set<int> _updatingIds = {};

  String get _token => context.read<AuthProvider>().token ?? '';
  AdminOrderService get _service => context.read<AdminOrderService>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request ??= _service.getOrders(_token);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final request = _service.getOrders(_token);
    setState(() {
      _request = request;
    });
    await request;
  }

  List<AdminOrder> _filtered(List<AdminOrder> orders) {
    final query = _searchController.text.trim().toLowerCase();
    return orders.where((order) {
      final matchesSearch =
          query.isEmpty ||
          [order.reference, order.customerName, order.customerEmail]
              .whereType<String>()
              .any((value) => value.toLowerCase().contains(query));
      final matchesOrderStatus =
          _orderStatus == 'All' ||
          order.orderStatus?.toLowerCase() == _orderStatus.toLowerCase();
      final matchesPaymentStatus =
          _paymentStatus == 'All' ||
          order.paymentStatus?.toLowerCase() == _paymentStatus.toLowerCase();
      return matchesSearch && matchesOrderStatus && matchesPaymentStatus;
    }).toList();
  }

  Future<void> _view(AdminOrder order) async {
    final id = order.id;
    if (id == null) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminOrderDetailsScreen(
          orderId: id,
          initialReference: order.reference,
        ),
      ),
    );
    if (mounted) await _refresh();
  }

  Future<void> _updateStatus(AdminOrder order) async {
    final id = order.id;
    if (id == null) return;
    final status = await showOrderStatusDialog(
      context,
      currentStatus: order.orderStatus,
      reference: order.reference,
    );
    if (status == null || !mounted) return;
    setState(() => _updatingIds.add(id));
    try {
      await _service.updateStatus(_token, id, status);
      if (!mounted) return;
      _showMessage('Order status updated to $status.');
      await _refresh();
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Unable to update order status: ${error.toString()}',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _updatingIds.remove(id));
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

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Orders',
      activeItem: 'Orders',
      child: FutureBuilder<List<AdminOrder>>(
        future: _request,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _OrdersError(error: snapshot.error, onRetry: _refresh);
          }
          final allOrders = snapshot.data ?? const [];
          final orders = _filtered(allOrders);
          final paymentStatuses =
              allOrders
                  .map((order) => order.paymentStatus)
                  .whereType<String>()
                  .toSet()
                  .toList()
                ..sort();
          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(
                MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1550),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _OrdersHeader(count: allOrders.length),
                      const SizedBox(height: 22),
                      _OrderFilters(
                        controller: _searchController,
                        orderStatus: _orderStatus,
                        paymentStatus: _paymentStatus,
                        paymentStatuses: paymentStatuses,
                        onSearch: (_) => setState(() {}),
                        onOrderStatus: (value) =>
                            setState(() => _orderStatus = value),
                        onPaymentStatus: (value) =>
                            setState(() => _paymentStatus = value),
                      ),
                      const SizedBox(height: 18),
                      if (orders.isEmpty)
                        const _EmptyOrders()
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth >= 950) {
                              return _OrdersTable(
                                orders: orders,
                                updatingIds: _updatingIds,
                                onView: _view,
                                onUpdate: _updateStatus,
                              );
                            }
                            return _OrderCards(
                              orders: orders,
                              updatingIds: _updatingIds,
                              onView: _view,
                              onUpdate: _updateStatus,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Order Management',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 5),
      Text(
        '$count orders in your store',
        style: const TextStyle(color: Color(0xFF64748B)),
      ),
    ],
  );
}

class _OrderFilters extends StatelessWidget {
  const _OrderFilters({
    required this.controller,
    required this.orderStatus,
    required this.paymentStatus,
    required this.paymentStatuses,
    required this.onSearch,
    required this.onOrderStatus,
    required this.onPaymentStatus,
  });
  final TextEditingController controller;
  final String orderStatus;
  final String paymentStatus;
  final List<String> paymentStatuses;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onOrderStatus;
  final ValueChanged<String> onPaymentStatus;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8ECF3)),
    ),
    child: Builder(
      builder: (context) {
        final searchField = ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: TextField(
            controller: controller,
            onChanged: onSearch,
            decoration: const InputDecoration(
              labelText: 'Search orders',
              hintText: 'Order ID, customer, or email',
              prefixIcon: Icon(Icons.search_rounded),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        );
        final orderStatusField = ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: DropdownButtonFormField<String>(
            initialValue: orderStatus,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Order status',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: ['All', ...adminOrderStatuses]
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  ),
                )
                .toList(),
            onChanged: (value) =>
                value == null ? null : onOrderStatus(value),
          ),
        );
        final paymentStatusField = ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: DropdownButtonFormField<String>(
            initialValue: paymentStatus,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Payment status',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: ['All', ...paymentStatuses]
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  ),
                )
                .toList(),
            onChanged: (value) =>
                value == null ? null : onPaymentStatus(value),
          ),
        );

        if (MediaQuery.sizeOf(context).width < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: 12),
              orderStatusField,
              const SizedBox(height: 12),
              paymentStatusField,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: searchField),
            const SizedBox(width: 16),
            SizedBox(width: 220, child: orderStatusField),
            const SizedBox(width: 16),
            SizedBox(width: 220, child: paymentStatusField),
          ],
        );
      },
    ),
  );
}

class _OrdersTable extends StatelessWidget {
  const _OrdersTable({
    required this.orders,
    required this.updatingIds,
    required this.onView,
    required this.onUpdate,
  });
  final List<AdminOrder> orders;
  final Set<int> updatingIds;
  final ValueChanged<AdminOrder> onView;
  final ValueChanged<AdminOrder> onUpdate;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8ECF3)),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          horizontalMargin: 18,
          columnSpacing: 25,
          columns: const [
            DataColumn(label: Text('ORDER')),
            DataColumn(label: Text('CUSTOMER')),
            DataColumn(label: Text('DATE')),
            DataColumn(label: Text('TOTAL')),
            DataColumn(label: Text('PAYMENT METHOD')),
            DataColumn(label: Text('PAYMENT')),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('ACTIONS')),
          ],
          rows: orders
              .map(
                (order) => DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 125,
                        child: Text(
                          order.reference ?? '#${order.id ?? '—'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 190,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.customerName ?? 'Guest',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              order.customerEmail ?? '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(Text(formatAdminOrderDate(order.createdAt))),
                    DataCell(
                      Text(
                        adminOrderMoney(order.totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: Text(
                          order.paymentMethod ?? '—',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(adminPaymentStatusChip(order.paymentStatus)),
                    DataCell(adminOrderStatusChip(order.orderStatus)),
                    DataCell(
                      _OrderActions(
                        order: order,
                        updating: updatingIds.contains(order.id),
                        onView: onView,
                        onUpdate: onUpdate,
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    ),
  );
}

class _OrderCards extends StatelessWidget {
  const _OrderCards({
    required this.orders,
    required this.updatingIds,
    required this.onView,
    required this.onUpdate,
  });
  final List<AdminOrder> orders;
  final Set<int> updatingIds;
  final ValueChanged<AdminOrder> onView;
  final ValueChanged<AdminOrder> onUpdate;

  @override
  Widget build(BuildContext context) => Column(
    children: orders
        .map(
          (order) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8ECF3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.reference ?? '#${order.id ?? '—'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    adminOrderStatusChip(order.orderStatus),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  order.customerName ?? 'Guest',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  order.customerEmail ?? '—',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 13),
                Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    _CardFact(
                      icon: Icons.calendar_today_outlined,
                      value: formatAdminOrderDate(order.createdAt),
                    ),
                    _CardFact(
                      icon: Icons.payments_outlined,
                      value: order.paymentMethod ?? '—',
                    ),
                    adminPaymentStatusChip(order.paymentStatus),
                  ],
                ),
                const Divider(height: 26),
                Row(
                  children: [
                    Text(
                      adminOrderMoney(order.totalAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    _OrderActions(
                      order: order,
                      updating: updatingIds.contains(order.id),
                      onView: onView,
                      onUpdate: onUpdate,
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
        .toList(),
  );
}

class _CardFact extends StatelessWidget {
  const _CardFact({required this.icon, required this.value});
  final IconData icon;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: const Color(0xFF64748B)),
      const SizedBox(width: 5),
      Text(
        value,
        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      ),
    ],
  );
}

class _OrderActions extends StatelessWidget {
  const _OrderActions({
    required this.order,
    required this.updating,
    required this.onView,
    required this.onUpdate,
  });
  final AdminOrder order;
  final bool updating;
  final ValueChanged<AdminOrder> onView;
  final ValueChanged<AdminOrder> onUpdate;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'View details',
        visualDensity: VisualDensity.compact,
        onPressed: () => onView(order),
        icon: const Icon(Icons.visibility_outlined, size: 20),
      ),
      updating
          ? const Padding(
              padding: EdgeInsets.all(9),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : IconButton(
              tooltip: 'Update status',
              visualDensity: VisualDensity.compact,
              onPressed: () => onUpdate(order),
              icon: const Icon(
                Icons.sync_rounded,
                size: 20,
                color: Color(0xFF2563EB),
              ),
            ),
    ],
  );
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8ECF3)),
    ),
    child: const Column(
      children: [
        Icon(Icons.receipt_long_outlined, size: 52, color: Color(0xFF94A3B8)),
        SizedBox(height: 14),
        Text(
          'No orders found',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 5),
        Text(
          'Try changing your search or filters.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      ],
    ),
  );
}

class _OrdersError extends StatelessWidget {
  const _OrdersError({required this.error, required this.onRetry});
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
        const Text('Unable to load orders.'),
        const SizedBox(height: 5),
        Text(
          error.toString(),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 14),
        FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
