import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../services/admin/admin_customer_service.dart';
import '../../../services/admin/admin_order_service.dart';
import '../../../widgets/admin/admin_section_card.dart';
import '../../../widgets/admin/admin_shell.dart';

class AdminCustomerDetailsScreen extends StatefulWidget {
  const AdminCustomerDetailsScreen({
    super.key,
    required this.customerId,
    this.initialCustomer,
  });

  final int customerId;
  final AdminCustomer? initialCustomer;

  @override
  State<AdminCustomerDetailsScreen> createState() =>
      _AdminCustomerDetailsScreenState();
}

class _AdminCustomerDetailsScreenState
    extends State<AdminCustomerDetailsScreen> {
  Future<_CustomerDetailsData>? _request;
  bool _busy = false;
  bool _changed = false;

  String get _token => context.read<AuthProvider>().token ?? '';
  AdminCustomerService get _service => context.read<AdminCustomerService>();
  AdminOrderService get _orderService => context.read<AdminOrderService>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request ??= _load();
  }

  Future<_CustomerDetailsData> _load() async {
    final customerFuture = _service.getCustomer(_token, widget.customerId);
    final ordersFuture = _orderService.getOrders(_token);
    final results = await Future.wait([customerFuture, ordersFuture]);
    final customer = results[0] as AdminCustomer;
    final orders =
        (results[1] as List<AdminOrder>)
            .where(
              (order) =>
                  order.customerEmail?.toLowerCase() ==
                  customer.email?.toLowerCase(),
            )
            .toList()
          ..sort((a, b) {
            final dateComparison = (b.createdAt ?? DateTime(1970)).compareTo(
              a.createdAt ?? DateTime(1970),
            );
            return dateComparison != 0
                ? dateComparison
                : (b.id ?? 0).compareTo(a.id ?? 0);
          });
    return _CustomerDetailsData(customer, orders.take(6).toList());
  }

  Future<void> _refresh() async {
    final request = _load();
    setState(() {
      _request = request;
    });
    await request;
  }

  Future<void> _deleteOrRestore(AdminCustomer customer) async {
    final id = customer.id;
    if (id == null) return;
    setState(() => _busy = true);
    try {
      if (customer.isDeleted) {
        await _service.restoreCustomer(_token, id);
        _showMessage('Customer restored successfully.');
      } else {
        await _service.deleteCustomer(_token, id);
        _showMessage('Customer moved to deleted status.');
      }
      _changed = true;
      await _refresh();
    } catch (error) {
      _showMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
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
      title: 'Customer Details',
      activeItem: 'Customers',
      child: FutureBuilder<_CustomerDetailsData>(
        future: _request,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _DetailsError(error: snapshot.error, onRetry: _refresh);
          }
          final data = snapshot.data;
          if (data == null) {
            return _DetailsError(
              error: 'Customer details were empty.',
              onRetry: _refresh,
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(
                MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailsHeader(
                        customer: data.customer,
                        busy: _busy,
                        onBack: _goBack,
                        onAction: () => _deleteOrRestore(data.customer),
                      ),
                      const SizedBox(height: 22),
                      _CustomerTopSummary(customer: data.customer),
                      const SizedBox(height: 22),
                      _DetailGrid(customer: data.customer),
                      const SizedBox(height: 22),
                      _RecentOrdersSection(orders: data.recentOrders),
                      const SizedBox(height: 24),
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

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({
    required this.customer,
    required this.busy,
    required this.onBack,
    required this.onAction,
  });

  final AdminCustomer customer;
  final bool busy;
  final VoidCallback onBack;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Flex(
      direction: constraints.maxWidth < 600 ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (constraints.maxWidth >= 600)
          Expanded(
            child: _CustomerHeading(customer: customer, onBack: onBack),
          )
        else
          _CustomerHeading(customer: customer, onBack: onBack),
        SizedBox(
          width: constraints.maxWidth < 600 ? 0 : 12,
          height: constraints.maxWidth < 600 ? 12 : 0,
        ),
        SizedBox(
          width: constraints.maxWidth < 600 ? double.infinity : null,
          child: FilledButton.icon(
            onPressed: busy ? null : onAction,
            icon: busy
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    customer.isDeleted
                        ? Icons.restore_rounded
                        : Icons.delete_outline_rounded,
                  ),
            label: Text(customer.isDeleted ? 'Restore' : 'Delete'),
          ),
        ),
      ],
    ),
  );
}

class _CustomerHeading extends StatelessWidget {
  const _CustomerHeading({required this.customer, required this.onBack});

  final AdminCustomer customer;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      IconButton.filledTonal(
        tooltip: 'Back to customers',
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customer.displayName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 5),
            Text(
              customer.email ?? customer.phone ?? 'Customer account overview',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    ],
  );
}

class _CustomerTopSummary extends StatelessWidget {
  const _CustomerTopSummary({required this.customer});
  final AdminCustomer customer;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _SummaryTile(label: 'Status', value: customer.status ?? '—'),
        _SummaryTile(
          label: 'Total Orders',
          value: '${customer.totalOrders ?? 0}',
        ),
        _SummaryTile(
          label: 'Total Spend',
          value: _money(customer.totalSpend ?? 0),
        ),
        _SummaryTile(label: 'Registered', value: _date(customer.registeredAt)),
      ],
    );
  }
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.customer});
  final AdminCustomer customer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 940;
        final left = AdminSectionCard(
          title: 'Profile Info',
          child: _FieldList(
            fields: [
              (
                'Customer ID',
                customer.customerCode ?? '#${customer.id ?? '—'}',
              ),
              ('Full Name', customer.displayName),
              ('Gender', customer.gender ?? '—'),
              ('Date of Birth', _shortDate(customer.dateOfBirth)),
              ('Status', customer.status ?? '—'),
            ],
          ),
        );
        final right = AdminSectionCard(
          title: 'Contact & Address',
          child: _FieldList(
            fields: [
              ('Email', customer.email ?? '—'),
              ('Phone', customer.phone ?? '—'),
              ('Address', customer.address ?? '—'),
              ('City / Country', customer.location),
              ('Notes', customer.notes ?? '—'),
            ],
          ),
        );
        if (!wide) {
          return Column(children: [left, const SizedBox(height: 20), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 20),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _RecentOrdersSection extends StatelessWidget {
  const _RecentOrdersSection({required this.orders});
  final List<AdminOrder> orders;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'Recent Orders',
      subtitle: 'Loaded from the existing admin order API',
      child: orders.isEmpty
          ? const _EmptyBlock(
              icon: Icons.receipt_long_outlined,
              title: 'No recent orders',
              message:
                  'This customer has no orders available in the current data set.',
            )
          : Column(
              children: orders
                  .map((order) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFFEFF6FF),
                            child: Text(
                              (order.reference ?? '#')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.reference ?? '#${order.id ?? '—'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${order.orderStatus ?? 'Pending'} • ${_shortDate(order.createdAt)}',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _money(order.totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: AdminSectionCard(
        title: label,
        child: Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
      ),
    );
  }
}

class _FieldList extends StatelessWidget {
  const _FieldList({required this.fields});
  final List<(String, String)> fields;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: fields
          .map(
            (field) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 118,
                    child: Text(
                      field.$1,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  Expanded(child: Text(field.$2)),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Icon(icon, size: 44, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _DetailsError extends StatelessWidget {
  const _DetailsError({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load customer details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

String _money(double value) => '৳${value.toStringAsFixed(2)}';

String _date(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

String _shortDate(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

class _CustomerDetailsData {
  const _CustomerDetailsData(this.customer, this.recentOrders);
  final AdminCustomer customer;
  final List<AdminOrder> recentOrders;
}
