import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../services/admin/admin_return_service.dart';
import '../../../widgets/admin/admin_section_card.dart';
import '../../../widgets/admin/admin_shell.dart';
import '../../../widgets/admin/admin_stat_card.dart';
import '../../../widgets/product_image.dart';
import 'admin_return_details_screen.dart';

class AdminReturnsScreen extends StatefulWidget {
  const AdminReturnsScreen({super.key});

  static const routeName = '/admin/returns';

  @override
  State<AdminReturnsScreen> createState() => _AdminReturnsScreenState();
}

class _AdminReturnsScreenState extends State<AdminReturnsScreen> {
  static const _pageSize = 8;

  final _searchController = TextEditingController();
  final Set<int> _busyIds = {};
  Future<List<AdminReturnRecord>>? _request;
  String _status = 'All';
  String _sort = 'Newest First';
  int _pageIndex = 0;

  String get _token => context.read<AuthProvider>().token ?? '';
  AdminReturnService get _service => context.read<AdminReturnService>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request ??= _service.getReturns(_token);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final request = _service.getReturns(_token);
    setState(() {
      _request = request;
      _pageIndex = 0;
    });
    await request;
  }

  List<AdminReturnRecord> _filtered(List<AdminReturnRecord> records) {
    final query = _searchController.text.trim().toLowerCase();
    final result = records.where((record) {
      final request = record.request;
      final searchValues = [
        request.id?.toString(),
        request.displayId,
        request.orderId?.toString(),
        record.orderReference,
        record.customerName,
        record.customerEmail,
      ];
      final matchesSearch =
          query.isEmpty ||
          searchValues.whereType<String>().any(
            (value) => value.toLowerCase().contains(query),
          );
      final matchesStatus =
          _status == 'All' || request.normalizedStatus == _status.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();
    result.sort((a, b) {
      final comparison = (b.request.requestedAt ?? DateTime(1970)).compareTo(
        a.request.requestedAt ?? DateTime(1970),
      );
      return _sort == 'Newest First' ? comparison : -comparison;
    });
    return result;
  }

  Future<void> _open(AdminReturnRecord record) async {
    final id = record.request.id;
    if (id == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            AdminReturnDetailsScreen(returnId: id, initialRecord: record),
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  Future<void> _updateStatus(AdminReturnRecord record, String status) async {
    final id = record.request.id;
    if (id == null) return;
    final confirmed = await _confirm(
      title: '$status return?',
      message:
          '$status ${record.request.displayId} for ${record.customerName}?',
      action: status,
      destructive: status == 'Rejected',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyIds.add(id));
    var succeeded = false;
    try {
      await _service.updateStatus(_token, id, status);
      succeeded = true;
      if (mounted) _message('Return marked ${status.toLowerCase()}.');
    } catch (error) {
      if (mounted) _message('Unable to update return: $error', error: true);
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
    if (succeeded && mounted) {
      try {
        await _refresh();
      } catch (error) {
        if (mounted) {
          _message(
            'Return updated, but the list could not refresh: $error',
            error: true,
          );
        }
      }
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String action,
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
            child: Text(action),
          ),
        ],
      ),
    );
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
      title: 'Returns',
      activeItem: 'Returns',
      child: FutureBuilder<List<AdminReturnRecord>>(
        future: _request,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ReturnsError(error: snapshot.error, onRetry: _refresh);
          }
          final records = snapshot.data ?? const <AdminReturnRecord>[];
          final filtered = _filtered(records);
          final pageCount = filtered.isEmpty
              ? 0
              : (filtered.length / _pageSize).ceil();
          if (pageCount > 0 && _pageIndex >= pageCount) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _pageIndex = pageCount - 1);
            });
          }
          final safePage = pageCount == 0
              ? 0
              : _pageIndex.clamp(0, pageCount - 1);
          final start = safePage * _pageSize;
          final pageItems = filtered.skip(start).take(_pageSize).toList();

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
                      _Header(total: records.length, onRefresh: _refresh),
                      const SizedBox(height: 22),
                      _Summary(records: records),
                      const SizedBox(height: 22),
                      _Filters(
                        searchController: _searchController,
                        status: _status,
                        sort: _sort,
                        onSearch: () => setState(() => _pageIndex = 0),
                        onStatus: (value) => setState(() {
                          _status = value;
                          _pageIndex = 0;
                        }),
                        onSort: (value) => setState(() {
                          _sort = value;
                          _pageIndex = 0;
                        }),
                        onClear: () => setState(() {
                          _searchController.clear();
                          _status = 'All';
                          _sort = 'Newest First';
                          _pageIndex = 0;
                        }),
                      ),
                      const SizedBox(height: 18),
                      if (filtered.isEmpty)
                        _EmptyState(
                          filtered: records.isNotEmpty,
                          onClear: () => setState(() {
                            _searchController.clear();
                            _status = 'All';
                            _sort = 'Newest First';
                            _pageIndex = 0;
                          }),
                        )
                      else ...[
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth >= 1180) {
                              return _ReturnsTable(
                                records: pageItems,
                                busyIds: _busyIds,
                                onView: _open,
                                onUpdate: _updateStatus,
                              );
                            }
                            return _ReturnCards(
                              records: pageItems,
                              busyIds: _busyIds,
                              onView: _open,
                              onUpdate: _updateStatus,
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        _Pagination(
                          pageIndex: safePage,
                          total: filtered.length,
                          onPrevious: safePage == 0
                              ? null
                              : () => setState(() => _pageIndex--),
                          onNext: safePage + 1 >= pageCount
                              ? null
                              : () => setState(() => _pageIndex++),
                        ),
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
              'Returns management',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 5),
            Text(
              '$total return requests',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      IconButton.filledTonal(
        tooltip: 'Refresh returns',
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.records});
  final List<AdminReturnRecord> records;

  @override
  Widget build(BuildContext context) {
    int count(String status) => records
        .where((record) => record.request.normalizedStatus == status)
        .length;
    final cards = [
      AdminStatCard(
        label: 'Total Returns',
        value: '${records.length}',
        icon: Icons.assignment_return_outlined,
        color: const Color(0xFF475569),
      ),
      AdminStatCard(
        label: 'Pending',
        value: '${count('pending')}',
        icon: Icons.schedule_rounded,
        color: const Color(0xFFF59E0B),
      ),
      AdminStatCard(
        label: 'Approved',
        value: '${count('approved')}',
        icon: Icons.verified_outlined,
        color: const Color(0xFF2563EB),
      ),
      AdminStatCard(
        label: 'Rejected',
        value: '${count('rejected')}',
        icon: Icons.cancel_outlined,
        color: const Color(0xFFDC2626),
      ),
      AdminStatCard(
        label: 'Completed',
        value: '${count('completed')}',
        icon: Icons.task_alt_rounded,
        color: const Color(0xFF059669),
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
    required this.searchController,
    required this.status,
    required this.sort,
    required this.onSearch,
    required this.onStatus,
    required this.onSort,
    required this.onClear,
  });
  final TextEditingController searchController;
  final String status;
  final String sort;
  final VoidCallback onSearch;
  final ValueChanged<String> onStatus;
  final ValueChanged<String> onSort;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Search and filters',
    subtitle: 'Find returns by return ID, order ID, or customer',
    child: LayoutBuilder(
      builder: (context, constraints) {
        final searchWidth = constraints.maxWidth < 340
            ? constraints.maxWidth
            : 340.0;
        final fieldWidth = constraints.maxWidth < 190
            ? constraints.maxWidth
            : 190.0;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: searchWidth,
              child: TextField(
                controller: searchController,
                onChanged: (_) => onSearch(),
                decoration: const InputDecoration(
                  labelText: 'Search returns',
                  prefixIcon: Icon(Icons.search_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: DropdownButtonFormField<String>(
                key: ValueKey(status),
                initialValue: status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items:
                    const [
                          'All',
                          'Pending',
                          'Approved',
                          'Rejected',
                          'Completed',
                        ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                onChanged: (value) => onStatus(value ?? 'All'),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: DropdownButtonFormField<String>(
                key: ValueKey(sort),
                initialValue: sort,
                decoration: const InputDecoration(
                  labelText: 'Sort',
                  border: OutlineInputBorder(),
                ),
                items: const ['Newest First', 'Oldest First']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) => onSort(value ?? 'Newest First'),
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

class _ReturnsTable extends StatelessWidget {
  const _ReturnsTable({
    required this.records,
    required this.busyIds,
    required this.onView,
    required this.onUpdate,
  });
  final List<AdminReturnRecord> records;
  final Set<int> busyIds;
  final Future<void> Function(AdminReturnRecord) onView;
  final Future<void> Function(AdminReturnRecord, String) onUpdate;

  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Return requests',
    subtitle: 'Review and process customer returns',
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        dataRowMinHeight: 76,
        dataRowMaxHeight: 96,
        columns: const [
          DataColumn(label: Text('Return / Order')),
          DataColumn(label: Text('Customer')),
          DataColumn(label: Text('Product')),
          DataColumn(label: Text('Qty')),
          DataColumn(label: Text('Reason')),
          DataColumn(label: Text('Requested')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Refund')),
          DataColumn(label: Text('Actions')),
        ],
        rows: records.map((record) {
          final request = record.request;
          final busy = request.id != null && busyIds.contains(request.id);
          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 125,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.displayId,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        record.orderReference,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
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
                        record.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        record.customerEmail ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(_ProductSummary(record: record)),
              DataCell(Text(record.quantity == 0 ? '—' : '${record.quantity}')),
              DataCell(
                SizedBox(
                  width: 190,
                  child: Text(
                    request.reason ?? '—',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(_formatDate(request.requestedAt))),
              DataCell(ReturnStatusChip(status: request.displayStatus)),
              DataCell(Text(_money(request.refundAmount))),
              DataCell(
                _Actions(
                  record: record,
                  busy: busy,
                  onView: onView,
                  onUpdate: onUpdate,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    ),
  );
}

class _ReturnCards extends StatelessWidget {
  const _ReturnCards({
    required this.records,
    required this.busyIds,
    required this.onView,
    required this.onUpdate,
  });
  final List<AdminReturnRecord> records;
  final Set<int> busyIds;
  final Future<void> Function(AdminReturnRecord) onView;
  final Future<void> Function(AdminReturnRecord, String) onUpdate;

  @override
  Widget build(BuildContext context) => Column(
    children: records.map((record) {
      final request = record.request;
      final busy = request.id != null && busyIds.contains(request.id);
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: AdminSectionCard(
          title: request.displayId,
          subtitle:
              'Order ${record.orderReference} • ${_formatDate(request.requestedAt)}',
          trailing: ReturnStatusChip(status: request.displayStatus),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductSummary(record: record),
              const SizedBox(height: 12),
              Text(
                record.customerName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                record.customerEmail ?? '—',
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              Text(
                request.reason ?? '—',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              _Actions(
                record: record,
                busy: busy,
                onView: onView,
                onUpdate: onUpdate,
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );
}

class _ProductSummary extends StatelessWidget {
  const _ProductSummary({required this.record});
  final AdminReturnRecord record;

  @override
  Widget build(BuildContext context) {
    final image = record.products.isEmpty
        ? ''
        : record.products.first.imageUrl ?? '';
    return SizedBox(
      width: 230,
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: ProductImage(
              imageUrl: image,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.productSummary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  record.quantity == 0
                      ? 'Quantity unavailable'
                      : 'Quantity ${record.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.record,
    required this.busy,
    required this.onView,
    required this.onUpdate,
  });
  final AdminReturnRecord record;
  final bool busy;
  final Future<void> Function(AdminReturnRecord) onView;
  final Future<void> Function(AdminReturnRecord, String) onUpdate;

  @override
  Widget build(BuildContext context) {
    final status = record.request.normalizedStatus;
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        TextButton(
          onPressed: busy ? null : () => onView(record),
          child: const Text('View'),
        ),
        TextButton(
          onPressed: busy || status == 'approved'
              ? null
              : () => onUpdate(record, 'Approved'),
          child: const Text('Approve'),
        ),
        TextButton(
          onPressed: busy || status == 'rejected'
              ? null
              : () => onUpdate(record, 'Rejected'),
          child: const Text('Reject'),
        ),
        TextButton(
          onPressed: busy || status == 'completed'
              ? null
              : () => onUpdate(record, 'Completed'),
          child: const Text('Complete'),
        ),
      ],
    );
  }
}

class ReturnStatusChip extends StatelessWidget {
  const ReturnStatusChip({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status.toLowerCase()) {
      'approved' => const Color(0xFF2563EB),
      'rejected' => const Color(0xFFDC2626),
      'completed' => const Color(0xFF059669),
      _ => const Color(0xFFF59E0B),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtered, required this.onClear});
  final bool filtered;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: filtered ? 'No matching returns' : 'No return requests',
    subtitle: filtered
        ? 'Adjust the search or status filter.'
        : 'Customer return requests will appear here.',
    child: Center(
      child: Column(
        children: [
          const Icon(
            Icons.assignment_return_outlined,
            size: 52,
            color: Color(0xFF64748B),
          ),
          const SizedBox(height: 12),
          Text(
            filtered
                ? 'No results match the current filters.'
                : 'The return queue is empty.',
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

class _ReturnsError extends StatelessWidget {
  const _ReturnsError({required this.error, required this.onRetry});
  final Object? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 52,
            color: Color(0xFF64748B),
          ),
          const SizedBox(height: 12),
          const Text('Unable to load returns.'),
          const SizedBox(height: 6),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.pageIndex,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });
  final int pageIndex;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final pageCount = (total / _AdminReturnsScreenState._pageSize).ceil();
    final start = pageIndex * _AdminReturnsScreenState._pageSize + 1;
    final end = (start + _AdminReturnsScreenState._pageSize - 1).clamp(
      start,
      total,
    );
    return AdminSectionCard(
      title: 'Pagination',
      subtitle: 'Showing $start-$end of $total returns',
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          Text('Page ${pageIndex + 1} of $pageCount'),
          OutlinedButton(onPressed: onPrevious, child: const Text('Previous')),
          FilledButton.tonal(onPressed: onNext, child: const Text('Next')),
        ],
      ),
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '—';
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
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _money(double? value) =>
    value == null ? '—' : '৳${value.toStringAsFixed(2)}';
