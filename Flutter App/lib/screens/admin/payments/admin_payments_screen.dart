import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../services/admin/admin_payment_service.dart';
import '../../../widgets/admin/admin_section_card.dart';
import '../../../widgets/admin/admin_shell.dart';
import '../../../widgets/admin/admin_stat_card.dart';
import 'admin_payment_details_screen.dart';
import 'admin_payment_form_screen.dart';
import 'admin_payment_widgets.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});
  static const routeName = '/admin/payments';
  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  static const _pageSize = 8;
  final _searchController = TextEditingController();
  final Set<int> _deletingIds = {};
  Future<List<AdminPaymentRecord>>? _request;
  String _status = 'All';
  int _page = 0;

  String get _token => context.read<AuthProvider>().token ?? '';
  AdminPaymentService get _service => context.read<AdminPaymentService>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request ??= _service.getPayments(_token);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final request = _service.getPayments(_token);
    setState(() {
      _request = request;
      _page = 0;
    });
    await request;
  }

  List<AdminPaymentRecord> _filtered(List<AdminPaymentRecord> records) {
    final query = _searchController.text.trim().toLowerCase();
    final result = records.where((record) {
      final p = record.payment;
      final matchesSearch =
          query.isEmpty ||
          [
            p.transactionId,
            p.orderId?.toString(),
            p.invoiceId?.toString(),
            p.displayId,
            record.orderReference,
          ].whereType<String>().any(
            (value) => value.toLowerCase().contains(query),
          );
      final matchesStatus =
          _status == 'All' || p.normalizedStatus == _status.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();
    result.sort(AdminPaymentRecord.newestFirst);
    return result;
  }

  Future<void> _view(AdminPaymentRecord record) async {
    if (record.payment.id == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminPaymentDetailsScreen(
          paymentId: record.payment.id!,
          initialRecord: record,
        ),
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  Future<void> _edit(AdminPaymentRecord record) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminPaymentFormScreen(payment: record.payment),
      ),
    );
    if (changed == true && mounted) {
      _message('Payment updated successfully.');
      await _refresh();
    }
  }

  Future<void> _delete(AdminPaymentRecord record) async {
    final id = record.payment.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete payment?'),
        content: Text(
          'Delete ${record.payment.displayId}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deletingIds.add(id));
    try {
      await _service.deletePayment(_token, id);
      if (!mounted) return;
      _message('Payment deleted successfully.');
      await _refresh();
    } catch (error) {
      if (mounted) _message('Unable to delete payment: $error', error: true);
    } finally {
      if (mounted) setState(() => _deletingIds.remove(id));
    }
  }

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: error ? const Color(0xFFB91C1C) : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) => AdminShell(
    title: 'Payments',
    activeItem: 'Payments',
    child: FutureBuilder<List<AdminPaymentRecord>>(
      future: _request,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _Error(error: snapshot.error, onRetry: _refresh);
        }
        final all = snapshot.data ?? const <AdminPaymentRecord>[];
        final filtered = _filtered(all);
        final pages = filtered.isEmpty
            ? 0
            : (filtered.length / _pageSize).ceil();
        if (pages > 0 && _page >= pages) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _page = pages - 1);
            }
          });
        }
        final page = pages == 0 ? 0 : _page.clamp(0, pages - 1);
        final items = filtered.skip(page * _pageSize).take(_pageSize).toList();
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
                    _Header(total: all.length, onRefresh: _refresh),
                    const SizedBox(height: 22),
                    _Summary(records: all),
                    const SizedBox(height: 22),
                    _Filters(
                      controller: _searchController,
                      status: _status,
                      onSearch: () => setState(() => _page = 0),
                      onStatus: (value) => setState(() {
                        _status = value;
                        _page = 0;
                      }),
                      onClear: () => setState(() {
                        _searchController.clear();
                        _status = 'All';
                        _page = 0;
                      }),
                    ),
                    const SizedBox(height: 18),
                    if (filtered.isEmpty)
                      _Empty(
                        filtered: all.isNotEmpty,
                        onClear: () => setState(() {
                          _searchController.clear();
                          _status = 'All';
                          _page = 0;
                        }),
                      )
                    else ...[
                      LayoutBuilder(
                        builder: (context, constraints) =>
                            constraints.maxWidth >= 1150
                            ? _Table(
                                records: items,
                                deletingIds: _deletingIds,
                                onView: _view,
                                onEdit: _edit,
                                onDelete: _delete,
                              )
                            : _Cards(
                                records: items,
                                deletingIds: _deletingIds,
                                onView: _view,
                                onEdit: _edit,
                                onDelete: _delete,
                              ),
                      ),
                      if (filtered.length > _pageSize) ...[
                        const SizedBox(height: 18),
                        _Pagination(
                          page: page,
                          pages: pages,
                          onPrevious: page == 0
                              ? null
                              : () => setState(() => _page--),
                          onNext: page + 1 >= pages
                              ? null
                              : () => setState(() => _page++),
                        ),
                      ],
                    ],
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

class _Header extends StatelessWidget {
  const _Header({required this.total, required this.onRefresh});
  final int total;
  final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payments management',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 5),
            Text(
              '$total payment records',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      IconButton.filledTonal(
        tooltip: 'Refresh payments',
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.records});
  final List<AdminPaymentRecord> records;
  @override
  Widget build(BuildContext context) {
    int count(String status) => records
        .where((record) => record.payment.normalizedStatus == status)
        .length;
    final cards = [
      AdminStatCard(
        label: 'Total Payments',
        value: '${records.length}',
        icon: Icons.payments_outlined,
        color: const Color(0xFF2563EB),
      ),
      AdminStatCard(
        label: 'Paid',
        value: '${count('paid')}',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF059669),
      ),
      AdminStatCard(
        label: 'Pending',
        value: '${count('pending')}',
        icon: Icons.schedule_rounded,
        color: const Color(0xFFF59E0B),
      ),
      AdminStatCard(
        label: 'Failed',
        value: '${count('failed')}',
        icon: Icons.cancel_outlined,
        color: const Color(0xFFDC2626),
      ),
      AdminStatCard(
        label: 'Refunded',
        value: '${count('refunded')}',
        icon: Icons.currency_exchange_rounded,
        color: const Color(0xFF7C3AED),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1200
            ? 5
            : constraints.maxWidth >= 700
            ? 3
            : 1;
        const gap = 14.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map((card) => SizedBox(width: width, child: card))
              .toList(),
        );
      },
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.controller,
    required this.status,
    required this.onSearch,
    required this.onStatus,
    required this.onClear,
  });
  final TextEditingController controller;
  final String status;
  final VoidCallback onSearch;
  final ValueChanged<String> onStatus;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Search and filter',
    subtitle: 'Payments are sorted newest first',
    child: LayoutBuilder(
      builder: (context, constraints) {
        final searchWidth = constraints.maxWidth < 360
            ? constraints.maxWidth
            : 360.0;
        final filterWidth = constraints.maxWidth < 190
            ? constraints.maxWidth
            : 190.0;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: searchWidth,
              child: TextField(
                controller: controller,
                onChanged: (_) => onSearch(),
                decoration: const InputDecoration(
                  labelText: 'Transaction, order, or invoice ID',
                  prefixIcon: Icon(Icons.search_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: filterWidth,
              child: DropdownButtonFormField<String>(
                key: ValueKey(status),
                initialValue: status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const ['All', 'Paid', 'Pending', 'Failed', 'Refunded']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) => onStatus(value ?? 'All'),
              ),
            ),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Clear'),
            ),
          ],
        );
      },
    ),
  );
}

class _Table extends StatelessWidget {
  const _Table({
    required this.records,
    required this.deletingIds,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });
  final List<AdminPaymentRecord> records;
  final Set<int> deletingIds;
  final Future<void> Function(AdminPaymentRecord) onView;
  final Future<void> Function(AdminPaymentRecord) onEdit;
  final Future<void> Function(AdminPaymentRecord) onDelete;
  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Payment records',
    subtitle: 'Transactions and linked business records',
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        dataRowMinHeight: 72,
        columns: const [
          DataColumn(label: Text('Payment')),
          DataColumn(label: Text('Order / Invoice')),
          DataColumn(label: Text('Customer')),
          DataColumn(label: Text('Method')),
          DataColumn(label: Text('Transaction ID')),
          DataColumn(label: Text('Amount')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Actions')),
        ],
        rows: records.map((record) {
          final p = record.payment;
          return DataRow(
            cells: [
              DataCell(
                Text(
                  p.displayId,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              DataCell(
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.orderReference),
                    Text(
                      p.invoiceId == null
                          ? 'No invoice'
                          : 'Invoice #${p.invoiceId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(
                SizedBox(
                  width: 170,
                  child: Text(
                    record.customerName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(p.paymentMethod ?? '—')),
              DataCell(
                SizedBox(
                  width: 170,
                  child: Text(
                    p.transactionId ?? '—',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(_money(p.amount))),
              DataCell(AdminPaymentStatusChip(status: p.displayStatus)),
              DataCell(Text(_date(p.paymentDate))),
              DataCell(
                _Actions(
                  record: record,
                  busy: p.id != null && deletingIds.contains(p.id),
                  onView: onView,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    ),
  );
}

class _Cards extends StatelessWidget {
  const _Cards({
    required this.records,
    required this.deletingIds,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });
  final List<AdminPaymentRecord> records;
  final Set<int> deletingIds;
  final Future<void> Function(AdminPaymentRecord) onView;
  final Future<void> Function(AdminPaymentRecord) onEdit;
  final Future<void> Function(AdminPaymentRecord) onDelete;
  @override
  Widget build(BuildContext context) => Column(
    children: records.map((record) {
      final p = record.payment;
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: AdminSectionCard(
          title: p.displayId,
          subtitle: p.transactionId ?? 'No transaction ID',
          trailing: AdminPaymentStatusChip(status: p.displayStatus),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 20,
                runSpacing: 10,
                children: [
                  _Mini('Order', record.orderReference),
                  _Mini('Method', p.paymentMethod ?? '—'),
                  _Mini('Amount', _money(p.amount)),
                  _Mini('Date', _date(p.paymentDate)),
                ],
              ),
              const SizedBox(height: 14),
              _Actions(
                record: record,
                busy: p.id != null && deletingIds.contains(p.id),
                onView: onView,
                onEdit: onEdit,
                onDelete: onDelete,
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );
}

class _Mini extends StatelessWidget {
  const _Mini(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      ),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.record,
    required this.busy,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });
  final AdminPaymentRecord record;
  final bool busy;
  final Future<void> Function(AdminPaymentRecord) onView;
  final Future<void> Function(AdminPaymentRecord) onEdit;
  final Future<void> Function(AdminPaymentRecord) onDelete;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 5,
    runSpacing: 5,
    children: [
      TextButton(
        onPressed: busy ? null : () => onView(record),
        child: const Text('View'),
      ),
      TextButton(
        onPressed: busy ? null : () => onEdit(record),
        child: const Text('Edit'),
      ),
      TextButton(
        onPressed: busy ? null : () => onDelete(record),
        style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
        child: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Delete'),
      ),
    ],
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.filtered, required this.onClear});
  final bool filtered;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: filtered ? 'No matching payments' : 'No payments',
    subtitle: filtered
        ? 'Adjust search or status filters.'
        : 'Payment records will appear here.',
    child: Center(
      child: Column(
        children: [
          const Icon(
            Icons.payments_outlined,
            size: 52,
            color: Color(0xFF64748B),
          ),
          const SizedBox(height: 12),
          Text(
            filtered
                ? 'No records match the filters.'
                : 'The payment list is empty.',
          ),
          if (filtered) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onClear,
              child: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    ),
  );
}

class _Error extends StatelessWidget {
  const _Error({required this.error, required this.onRetry});
  final Object? error;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_off_outlined, size: 52),
        const SizedBox(height: 12),
        const Text('Unable to load payments.'),
        const SizedBox(height: 6),
        Text(error.toString()),
        const SizedBox(height: 14),
        FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.page,
    required this.pages,
    required this.onPrevious,
    required this.onNext,
  });
  final int page;
  final int pages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Pagination',
    subtitle: 'Page ${page + 1} of $pages',
    child: Wrap(
      alignment: WrapAlignment.end,
      spacing: 10,
      children: [
        OutlinedButton(onPressed: onPrevious, child: const Text('Previous')),
        FilledButton.tonal(onPressed: onNext, child: const Text('Next')),
      ],
    ),
  );
}

String _date(DateTime? value) => value == null
    ? '—'
    : '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
String _money(double value) => '৳${value.toStringAsFixed(2)}';
