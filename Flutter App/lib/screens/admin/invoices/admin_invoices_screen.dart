import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../services/admin/admin_invoice_service.dart';
import '../../../widgets/admin/admin_section_card.dart';
import '../../../widgets/admin/admin_shell.dart';
import '../../../widgets/admin/admin_sidebar.dart';
import '../../../widgets/admin/admin_stat_card.dart';
import 'admin_invoice_details_screen.dart';
import 'admin_invoice_form_screen.dart';
import 'admin_invoice_widgets.dart';

class AdminInvoicesScreen extends StatefulWidget {
  const AdminInvoicesScreen({super.key});

  static const routeName = adminInvoicesRoute;

  @override
  State<AdminInvoicesScreen> createState() => _AdminInvoicesScreenState();
}

class _AdminInvoicesScreenState extends State<AdminInvoicesScreen> {
  static const _pageSize = 8;

  final _searchController = TextEditingController();
  final Set<int> _deletingIds = {};
  Future<List<AdminInvoiceRecord>>? _request;
  String _status = 'All';
  int _page = 0;

  String get _token => context.read<AuthProvider>().token ?? '';
  AdminInvoiceService get _service => context.read<AdminInvoiceService>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request ??= _service.getInvoices(_token);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final request = _service.getInvoices(_token);
    setState(() {
      _request = request;
      _page = 0;
    });
    await request;
  }

  List<AdminInvoiceRecord> _filtered(List<AdminInvoiceRecord> records) {
    final query = _searchController.text.trim().toLowerCase();
    final result = records.where((record) {
      final invoice = record.invoice;
      final searchValues = <String?>[
        invoice.invoiceNumber,
        record.orderReference,
        invoice.orderId?.toString(),
        record.customerName,
        record.customerEmail,
        record.customerPhone,
        record.order?.customerName,
        record.order?.customerEmail,
      ];
      final matchesSearch =
          query.isEmpty ||
          searchValues.whereType<String>().any(
            (value) => value.toLowerCase().contains(query),
          );
      final matchesStatus =
          _status == 'All' || invoice.normalizedStatus == _status.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();
    result.sort(AdminInvoiceRecord.newestFirst);
    return result;
  }

  Future<void> _create() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AdminInvoiceFormScreen()),
    );
    if (changed == true && mounted) {
      _message('Invoice created successfully.');
      await _refresh();
    }
  }

  Future<void> _view(AdminInvoiceRecord record) async {
    if (record.invoice.id == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminInvoiceDetailsScreen(
          invoiceId: record.invoice.id!,
          initialRecord: record,
        ),
      ),
    );
    if (changed == true && mounted) {
      await _refresh();
    }
  }

  Future<void> _edit(AdminInvoiceRecord record) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminInvoiceFormScreen(invoice: record.invoice),
      ),
    );
    if (changed == true && mounted) {
      _message('Invoice updated successfully.');
      await _refresh();
    }
  }

  Future<void> _delete(AdminInvoiceRecord record) async {
    final id = record.invoice.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete invoice?'),
        content: Text(
          'Delete ${record.invoice.displayNumber}? This action cannot be undone.',
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
      await _service.deleteInvoice(_token, id);
      if (!mounted) return;
      _message('Invoice deleted successfully.');
      await _refresh();
    } catch (error) {
      if (mounted) _message('Unable to delete invoice: $error', error: true);
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
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Invoices',
      activeItem: 'Invoices',
      child: FutureBuilder<List<AdminInvoiceRecord>>(
        future: _request,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(error: snapshot.error, onRetry: _refresh);
          }

          final all = snapshot.data ?? const <AdminInvoiceRecord>[];
          final filtered = _filtered(all);
          final pages = filtered.isEmpty ? 0 : (filtered.length / _pageSize).ceil();
          if (pages > 0 && _page >= pages) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _page = pages - 1);
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
                  constraints: const BoxConstraints(maxWidth: 1600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        total: all.length,
                        onCreate: _create,
                        onRefresh: _refresh,
                      ),
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
                        _EmptyState(
                          filtered: all.isNotEmpty,
                          onClear: () => setState(() {
                            _searchController.clear();
                            _status = 'All';
                            _page = 0;
                          }),
                          onCreate: _create,
                        )
                      else ...[
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth >= 1150) {
                              return _Table(
                                records: items,
                                deletingIds: _deletingIds,
                                onView: _view,
                                onEdit: _edit,
                                onDelete: _delete,
                              );
                            }
                            return _Cards(
                              records: items,
                              deletingIds: _deletingIds,
                              onView: _view,
                              onEdit: _edit,
                              onDelete: _delete,
                            );
                          },
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
}

class _Header extends StatelessWidget {
  const _Header({
    required this.total,
    required this.onCreate,
    required this.onRefresh,
  });

  final int total;
  final VoidCallback onCreate;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invoices management',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 5),
        Text(
          '$total invoices',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
      ],
    );
    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        IconButton.filledTonal(
          tooltip: 'Refresh invoices',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create Invoice'),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 12), actions],
          );
        }
        return Row(
          children: [Expanded(child: title), actions],
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.records});

  final List<AdminInvoiceRecord> records;

  @override
  Widget build(BuildContext context) {
    int count(String status) =>
        records.where((record) => record.invoice.normalizedStatus == status).length;
    final cards = [
      AdminStatCard(
        label: 'Total Invoices',
        value: '${records.length}',
        icon: Icons.description_outlined,
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
        label: 'Cancelled',
        value: '${count('cancelled')}',
        icon: Icons.cancel_outlined,
        color: const Color(0xFFDC2626),
      ),
      AdminStatCard(
        label: 'Refunded',
        value: '${count('refunded')}',
        icon: Icons.undo_rounded,
        color: const Color(0xFF7C3AED),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1200
            ? 5
            : constraints.maxWidth >= 720
            ? 3
            : 1;
        const gap = 16.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards.map((card) => SizedBox(width: width, child: card)).toList(),
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
    subtitle: 'Invoices are sorted newest first',
    child: LayoutBuilder(
      builder: (context, constraints) {
        final searchWidth = constraints.maxWidth < 340
            ? constraints.maxWidth
            : 340.0;
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
                  labelText: 'Invoice, order, or customer',
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
                items: const ['All', 'Paid', 'Pending', 'Cancelled', 'Refunded']
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

  final List<AdminInvoiceRecord> records;
  final Set<int> deletingIds;
  final Future<void> Function(AdminInvoiceRecord) onView;
  final Future<void> Function(AdminInvoiceRecord) onEdit;
  final Future<void> Function(AdminInvoiceRecord) onDelete;

  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Invoice list',
    subtitle: 'Invoice records and totals',
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        dataRowMinHeight: 72,
        columns: const [
          DataColumn(label: Text('Invoice')),
          DataColumn(label: Text('Order')),
          DataColumn(label: Text('Customer')),
          DataColumn(label: Text('Payment Method')),
          DataColumn(label: Text('Payment Status')),
          DataColumn(label: Text('Invoice Status')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Total')),
          DataColumn(label: Text('Actions')),
        ],
        rows: records.map((record) {
          final invoice = record.invoice;
          final busy = invoice.id != null && deletingIds.contains(invoice.id);
          return DataRow(
            cells: [
              DataCell(
                Text(
                  invoice.displayNumber,
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
                      invoice.orderId == null
                          ? 'No order'
                          : 'Order #${invoice.orderId}',
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
                  width: 190,
                  child: Text(
                    record.customerName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(invoice.paymentMethod ?? '—')),
              DataCell(adminInvoiceStatusChip(invoice.paymentStatus)),
              DataCell(adminInvoiceStatusChip(invoice.displayStatus)),
              DataCell(Text(adminInvoiceDate(invoice.issueDate))),
              DataCell(Text(adminInvoiceMoney(invoice.totalAmount))),
              DataCell(
                _Actions(
                  record: record,
                  busy: busy,
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

  final List<AdminInvoiceRecord> records;
  final Set<int> deletingIds;
  final Future<void> Function(AdminInvoiceRecord) onView;
  final Future<void> Function(AdminInvoiceRecord) onEdit;
  final Future<void> Function(AdminInvoiceRecord) onDelete;

  @override
  Widget build(BuildContext context) => Column(
    children: records.map((record) {
      final invoice = record.invoice;
      final busy = invoice.id != null && deletingIds.contains(invoice.id);
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: AdminSectionCard(
          title: invoice.displayNumber,
          subtitle: '${record.orderReference} • ${record.customerName}',
          trailing: adminInvoiceStatusChip(invoice.displayStatus),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 18,
                runSpacing: 10,
                children: [
                  _MiniInfo(label: 'Payment', value: invoice.paymentStatus ?? '—'),
                  _MiniInfo(label: 'Method', value: invoice.paymentMethod ?? '—'),
                  _MiniInfo(label: 'Date', value: adminInvoiceDate(invoice.issueDate)),
                  _MiniInfo(label: 'Total', value: adminInvoiceMoney(invoice.totalAmount)),
                ],
              ),
              const SizedBox(height: 14),
              _Actions(
                record: record,
                busy: busy,
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

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.label, required this.value});

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

  final AdminInvoiceRecord record;
  final bool busy;
  final Future<void> Function(AdminInvoiceRecord) onView;
  final Future<void> Function(AdminInvoiceRecord) onEdit;
  final Future<void> Function(AdminInvoiceRecord) onDelete;

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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.filtered,
    required this.onCreate,
    required this.onClear,
  });

  final bool filtered;
  final VoidCallback onCreate;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: filtered ? 'No matching invoices' : 'No invoices',
    subtitle: filtered
        ? 'Adjust the search or status filter.'
        : 'Create the first invoice record.',
    child: Center(
      child: Column(
        children: [
          const Icon(
            Icons.description_outlined,
            size: 52,
            color: Color(0xFF64748B),
          ),
          const SizedBox(height: 12),
          Text(
            filtered
                ? 'No invoices match the current filters.'
                : 'No invoice data is available.',
          ),
          const SizedBox(height: 14),
          FilledButton.tonal(
            onPressed: filtered ? onClear : onCreate,
            child: Text(filtered ? 'Clear filters' : 'Create Invoice'),
          ),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          size: 52,
          color: Color(0xFF64748B),
        ),
        const SizedBox(height: 12),
        const Text('Unable to load invoices.'),
        const SizedBox(height: 6),
        Text(error.toString(), textAlign: TextAlign.center),
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
