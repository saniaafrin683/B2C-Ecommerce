import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../services/admin/admin_customer_service.dart';
import '../../../widgets/admin/admin_shell.dart';
import 'admin_customer_details_screen.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  static const routeName = '/admin/customers';

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  final _searchController = TextEditingController();
  Future<_CustomerListData>? _request;
  bool _showDeleted = false;
  String _statusFilter = 'All';
  final Set<int> _busyIds = {};

  String get _token => context.read<AuthProvider>().token ?? '';
  AdminCustomerService get _service => context.read<AdminCustomerService>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request ??= _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_CustomerListData> _load() async {
    final customers = _showDeleted
        ? await _service.getDeletedCustomers(_token)
        : await _service.getCustomers(_token);
    return _CustomerListData(customers);
  }

  Future<void> _refresh() async {
    final request = _load();
    setState(() {
      _request = request;
    });
    await request;
  }

  List<AdminCustomer> _filtered(List<AdminCustomer> customers) {
    final query = _searchController.text.trim().toLowerCase();
    return customers.where((customer) {
      final matchesSearch =
          query.isEmpty ||
          [customer.displayName, customer.email, customer.phone]
              .whereType<String>()
              .any((value) => value.toLowerCase().contains(query));
      final matchesStatus =
          _statusFilter == 'All' ||
          customer.status?.toLowerCase() == _statusFilter.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _openDetails(AdminCustomer customer) async {
    final id = customer.id;
    if (id == null) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminCustomerDetailsScreen(
          customerId: id,
          initialCustomer: customer,
        ),
      ),
    );
    if (mounted) await _refresh();
  }

  Future<void> _delete(AdminCustomer customer) async {
    final id = customer.id;
    if (id == null) return;
    final confirmed = await _confirmAction(
      title: 'Delete customer?',
      message:
          'Delete ${customer.displayName}? This will move the account to deleted status.',
      confirmText: 'Delete',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyIds.add(id));
    try {
      await _service.deleteCustomer(_token, id);
      if (!mounted) return;
      _showMessage('Customer moved to deleted status.');
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  Future<void> _restore(AdminCustomer customer) async {
    final id = customer.id;
    if (id == null) return;
    final confirmed = await _confirmAction(
      title: 'Restore customer?',
      message: 'Restore ${customer.displayName} back to active status?',
      confirmText: 'Restore',
      destructive: false,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyIds.add(id));
    try {
      await _service.restoreCustomer(_token, id);
      if (!mounted) return;
      _showMessage('Customer restored successfully.');
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String confirmText,
    required bool destructive,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: destructive ? const Color(0xFFDC2626) : null,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
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
      title: 'Customers',
      activeItem: 'Customers',
      child: FutureBuilder<_CustomerListData>(
        future: _request,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _CustomerError(error: snapshot.error, onRetry: _refresh);
          }
          final data = snapshot.data ?? const _CustomerListData([]);
          final customers = _filtered(data.customers);
          final statuses = data.customers
              .map((customer) => customer.status)
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
                      _CustomersHeader(
                        count: data.customers.length,
                        showDeleted: _showDeleted,
                        onToggleDeleted: (value) {
                          if (_showDeleted == value) return;
                          setState(() {
                            _showDeleted = value;
                            _statusFilter = 'All';
                            _request = _load();
                          });
                        },
                      ),
                      const SizedBox(height: 22),
                      _CustomerFilters(
                        controller: _searchController,
                        statusFilter: _statusFilter,
                        statuses: statuses,
                        onSearch: (_) => setState(() {}),
                        onStatus: (value) => setState(() => _statusFilter = value),
                      ),
                      const SizedBox(height: 18),
                      if (customers.isEmpty)
                        _EmptyCustomers(showDeleted: _showDeleted)
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth >= 940) {
                              return _CustomerTable(
                                customers: customers,
                                busyIds: _busyIds,
                                showDeleted: _showDeleted,
                                onView: _openDetails,
                                onDelete: _delete,
                                onRestore: _restore,
                              );
                            }
                            return _CustomerCards(
                              customers: customers,
                              busyIds: _busyIds,
                              showDeleted: _showDeleted,
                              onView: _openDetails,
                              onDelete: _delete,
                              onRestore: _restore,
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

class _CustomersHeader extends StatelessWidget {
  const _CustomersHeader({
    required this.count,
    required this.showDeleted,
    required this.onToggleDeleted,
  });

  final int count;
  final bool showDeleted;
  final ValueChanged<bool> onToggleDeleted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Management',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 5),
              Text(
                showDeleted
                    ? 'Viewing deleted customer accounts'
                    : '$count customer accounts in the system',
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        FilterChip(
          selected: showDeleted,
          label: const Text('Deleted'),
          onSelected: onToggleDeleted,
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          backgroundColor: Colors.white,
          selectedColor: const Color(0xFFEFF6FF),
        ),
      ],
    );
  }
}

class _CustomerFilters extends StatelessWidget {
  const _CustomerFilters({
    required this.controller,
    required this.statusFilter,
    required this.statuses,
    required this.onSearch,
    required this.onStatus,
  });

  final TextEditingController controller;
  final String statusFilter;
  final List<String> statuses;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onStatus;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 380,
          child: TextField(
            controller: controller,
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Search by name, email, or phone',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ),
        DropdownButton<String>(
          value: statusFilter,
          borderRadius: BorderRadius.circular(14),
          items: [
            const DropdownMenuItem(value: 'All', child: Text('All statuses')),
            ...statuses.map(
              (status) => DropdownMenuItem(
                value: status,
                child: Text(status),
              ),
            ),
          ],
          onChanged: (value) => onStatus(value ?? 'All'),
        ),
      ],
    );
  }
}

class _CustomerTable extends StatelessWidget {
  const _CustomerTable({
    required this.customers,
    required this.busyIds,
    required this.showDeleted,
    required this.onView,
    required this.onDelete,
    required this.onRestore,
  });

  final List<AdminCustomer> customers;
  final Set<int> busyIds;
  final bool showDeleted;
  final ValueChanged<AdminCustomer> onView;
  final ValueChanged<AdminCustomer> onDelete;
  final ValueChanged<AdminCustomer> onRestore;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
        columns: const [
          DataColumn(label: Text('Customer ID')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Contact')),
          DataColumn(label: Text('Location')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Orders')),
          DataColumn(label: Text('Spend')),
          DataColumn(label: Text('Registered')),
          DataColumn(label: Text('Actions')),
        ],
        rows: customers.map((customer) {
          final id = customer.id;
          final busy = id != null && busyIds.contains(id);
          return DataRow(
            cells: [
              DataCell(Text(customer.customerCode ?? '#${customer.id ?? '—'}')),
              DataCell(Text(customer.displayName)),
              DataCell(Text(customer.email ?? customer.phone ?? '—')),
              DataCell(Text(customer.location)),
              DataCell(_StatusChip(status: customer.status)),
              DataCell(Text('${customer.totalOrders ?? 0}')),
              DataCell(Text(_money(customer.totalSpend ?? 0))),
              DataCell(Text(_date(customer.registeredAt))),
              DataCell(
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: busy ? null : () => onView(customer),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('View'),
                    ),
                    if (showDeleted)
                      FilledButton.tonalIcon(
                        onPressed: busy ? null : () => onRestore(customer),
                        icon: busy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.restore_rounded, size: 16),
                        label: const Text('Restore'),
                      )
                    else
                      FilledButton.tonalIcon(
                        onPressed: busy ? null : () => onDelete(customer),
                        icon: busy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_outline_rounded, size: 16),
                        label: const Text('Delete'),
                      ),
                  ],
                ),
              ),
            ],
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _CustomerCards extends StatelessWidget {
  const _CustomerCards({
    required this.customers,
    required this.busyIds,
    required this.showDeleted,
    required this.onView,
    required this.onDelete,
    required this.onRestore,
  });

  final List<AdminCustomer> customers;
  final Set<int> busyIds;
  final bool showDeleted;
  final ValueChanged<AdminCustomer> onView;
  final ValueChanged<AdminCustomer> onDelete;
  final ValueChanged<AdminCustomer> onRestore;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: customers
          .map(
            (customer) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE8ECF3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFFEFF6FF),
                            child: Text(
                              _initials(customer.displayName),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  customer.email ?? customer.phone ?? '—',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _StatusChip(status: customer.status),
                                    _MetaChip(text: customer.customerCode ?? '—'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(
                        icon: Icons.place_outlined,
                        label: 'Location',
                        value: customer.location,
                      ),
                      _InfoRow(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Orders',
                        value: '${customer.totalOrders ?? 0}',
                      ),
                      _InfoRow(
                        icon: Icons.payments_outlined,
                        label: 'Spend',
                        value: _money(customer.totalSpend ?? 0),
                      ),
                      _InfoRow(
                        icon: Icons.event_outlined,
                        label: 'Registered',
                        value: _date(customer.registeredAt),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          TextButton.icon(
                            onPressed: () => onView(customer),
                            icon: const Icon(Icons.visibility_outlined, size: 16),
                            label: const Text('View'),
                          ),
                          if (showDeleted)
                            FilledButton.tonalIcon(
                              onPressed: () => onRestore(customer),
                              icon: const Icon(Icons.restore_rounded, size: 16),
                              label: const Text('Restore'),
                            )
                          else
                            FilledButton.tonalIcon(
                              onPressed: () => onDelete(customer),
                              icon: const Icon(Icons.delete_outline_rounded, size: 16),
                              label: const Text('Delete'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _EmptyCustomers extends StatelessWidget {
  const _EmptyCustomers({required this.showDeleted});
  final bool showDeleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.person_off_outlined, size: 52, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            showDeleted ? 'No deleted customers found' : 'No customers found',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            showDeleted
                ? 'Deleted customer accounts will appear here.'
                : 'Try a different search or status filter.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _CustomerError extends StatelessWidget {
  const _CustomerError({required this.error, required this.onRetry});
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
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)),
            const SizedBox(height: 12),
            Text(
              'Unable to load customers',
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String? status;

  @override
  Widget build(BuildContext context) {
    final normalized = status?.toLowerCase();
    final color = switch (normalized) {
      'active' => const Color(0xFF059669),
      'inactive' => const Color(0xFFF59E0B),
      'suspended' => const Color(0xFFB45309),
      'deleted' => const Color(0xFFDC2626),
      _ => const Color(0xFF64748B),
    };
    return Chip(
      label: Text(status ?? '—'),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      backgroundColor: color.withValues(alpha: 0.08),
      side: BorderSide(color: color.withValues(alpha: 0.18)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text),
      backgroundColor: const Color(0xFFF8FAFC),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerListData {
  const _CustomerListData(this.customers);

  final List<AdminCustomer> customers;
}

String _money(double value) => '৳${value.toStringAsFixed(2)}';

String _date(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

String _initials(String value) {
  final parts = value.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
}
