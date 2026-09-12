import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../services/admin/admin_coupon_service.dart';
import '../../../widgets/admin/admin_section_card.dart';
import '../../../widgets/admin/admin_shell.dart';
import '../../../widgets/admin/admin_stat_card.dart';
import 'admin_coupon_details_screen.dart';
import 'admin_coupon_form_screen.dart';
import 'admin_coupon_widgets.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  static const routeName = '/admin/coupons';

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  static const _pageSize = 8;

  final _searchController = TextEditingController();
  final Set<int> _deletingIds = {};
  Future<List<AdminCoupon>>? _request;
  String _status = 'All';
  int _pageIndex = 0;

  String get _token => context.read<AuthProvider>().token ?? '';
  AdminCouponService get _service => context.read<AdminCouponService>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request ??= _service.getCoupons(_token);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final request = _service.getCoupons(_token);
    setState(() {
      _request = request;
      _pageIndex = 0;
    });
    await request;
  }

  List<AdminCoupon> _filtered(List<AdminCoupon> coupons) {
    final query = _searchController.text.trim().toLowerCase();
    final result = coupons.where((coupon) {
      final matchesSearch =
          query.isEmpty || coupon.displayCode.toLowerCase().contains(query);
      final matchesStatus =
          _status == 'All' || coupon.effectiveStatus == _status;
      return matchesSearch && matchesStatus;
    }).toList();
    result.sort(AdminCoupon.newestFirst);
    return result;
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AdminCouponFormScreen()),
    );
    if (created == true && mounted) {
      _message('Coupon created successfully.');
      await _refresh();
    }
  }

  Future<void> _view(AdminCoupon coupon) async {
    if (coupon.id == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminCouponDetailsScreen(
          couponId: coupon.id!,
          initialCoupon: coupon,
        ),
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  Future<void> _edit(AdminCoupon coupon) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AdminCouponFormScreen(coupon: coupon)),
    );
    if (changed == true && mounted) {
      _message('Coupon updated successfully.');
      await _refresh();
    }
  }

  Future<void> _delete(AdminCoupon coupon) async {
    if (coupon.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete coupon?'),
        content: Text(
          'Delete ${coupon.displayCode}? This action cannot be undone.',
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

    setState(() => _deletingIds.add(coupon.id!));
    try {
      await _service.deleteCoupon(_token, coupon.id!);
      if (!mounted) return;
      _message('Coupon deleted successfully.');
      await _refresh();
    } catch (error) {
      if (mounted) _message('Unable to delete coupon: $error', error: true);
    } finally {
      if (mounted) setState(() => _deletingIds.remove(coupon.id));
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
      title: 'Coupons',
      activeItem: 'Coupons',
      child: FutureBuilder<List<AdminCoupon>>(
        future: _request,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _CouponsError(error: snapshot.error, onRetry: _refresh);
          }
          final coupons = snapshot.data ?? const <AdminCoupon>[];
          final filtered = _filtered(coupons);
          final pageCount = filtered.isEmpty
              ? 0
              : (filtered.length / _pageSize).ceil();
          if (pageCount > 0 && _pageIndex >= pageCount) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _pageIndex = pageCount - 1);
            });
          }
          final page = pageCount == 0 ? 0 : _pageIndex.clamp(0, pageCount - 1);
          final items = filtered
              .skip(page * _pageSize)
              .take(_pageSize)
              .toList();
          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(
                MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        total: coupons.length,
                        onCreate: _create,
                        onRefresh: _refresh,
                      ),
                      const SizedBox(height: 22),
                      _Summary(coupons: coupons),
                      const SizedBox(height: 22),
                      _Filters(
                        controller: _searchController,
                        status: _status,
                        onSearch: () => setState(() => _pageIndex = 0),
                        onStatus: (value) => setState(() {
                          _status = value;
                          _pageIndex = 0;
                        }),
                        onClear: () => setState(() {
                          _searchController.clear();
                          _status = 'All';
                          _pageIndex = 0;
                        }),
                      ),
                      const SizedBox(height: 18),
                      if (filtered.isEmpty)
                        _EmptyState(
                          filtered: coupons.isNotEmpty,
                          onCreate: _create,
                          onClear: () => setState(() {
                            _searchController.clear();
                            _status = 'All';
                            _pageIndex = 0;
                          }),
                        )
                      else ...[
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth >= 1050) {
                              return _CouponTable(
                                coupons: items,
                                deletingIds: _deletingIds,
                                onView: _view,
                                onEdit: _edit,
                                onDelete: _delete,
                              );
                            }
                            return _CouponCards(
                              coupons: items,
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
                            total: filtered.length,
                            onPrevious: page == 0
                                ? null
                                : () => setState(() => _pageIndex--),
                            onNext: page + 1 >= pageCount
                                ? null
                                : () => setState(() => _pageIndex++),
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
          'Coupons management',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 5),
        Text(
          '$total promotional coupons',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
      ],
    );
    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        IconButton.filledTonal(
          tooltip: 'Refresh coupons',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create Coupon'),
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
          children: [
            Expanded(child: title),
            actions,
          ],
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.coupons});
  final List<AdminCoupon> coupons;
  @override
  Widget build(BuildContext context) {
    int count(String status) =>
        coupons.where((coupon) => coupon.effectiveStatus == status).length;
    final cards = [
      AdminStatCard(
        label: 'Total Coupons',
        value: '${coupons.length}',
        icon: Icons.local_offer_outlined,
        color: const Color(0xFF7C3AED),
      ),
      AdminStatCard(
        label: 'Active',
        value: '${count('Active')}',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF059669),
      ),
      AdminStatCard(
        label: 'Inactive',
        value: '${count('Inactive')}',
        icon: Icons.pause_circle_outline,
        color: const Color(0xFF64748B),
      ),
      AdminStatCard(
        label: 'Expired',
        value: '${count('Expired')}',
        icon: Icons.event_busy_outlined,
        color: const Color(0xFFDC2626),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 650
            ? 2
            : 1;
        const gap = 16.0;
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
    subtitle: 'Coupons are sorted newest first',
    child: LayoutBuilder(
      builder: (context, constraints) {
        final searchWidth = constraints.maxWidth < 330
            ? constraints.maxWidth
            : 330.0;
        final statusWidth = constraints.maxWidth < 190
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
                  labelText: 'Search coupon code',
                  prefixIcon: Icon(Icons.search_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: statusWidth,
              child: DropdownButtonFormField<String>(
                key: ValueKey(status),
                initialValue: status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const ['All', 'Active', 'Inactive', 'Expired']
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

class _CouponTable extends StatelessWidget {
  const _CouponTable({
    required this.coupons,
    required this.deletingIds,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });
  final List<AdminCoupon> coupons;
  final Set<int> deletingIds;
  final Future<void> Function(AdminCoupon) onView;
  final Future<void> Function(AdminCoupon) onEdit;
  final Future<void> Function(AdminCoupon) onDelete;
  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Coupon list',
    subtitle: 'Promotion rules and usage',
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        dataRowMinHeight: 70,
        columns: const [
          DataColumn(label: Text('Code')),
          DataColumn(label: Text('Discount')),
          DataColumn(label: Text('Minimum Order')),
          DataColumn(label: Text('Usage')),
          DataColumn(label: Text('Start')),
          DataColumn(label: Text('Expiry')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: coupons
            .map(
              (coupon) => DataRow(
                cells: [
                  DataCell(
                    Text(
                      coupon.displayCode,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  DataCell(
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coupon.displayDiscount,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          coupon.displayDiscountType,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(_money(coupon.minimumOrderAmount))),
                  DataCell(
                    Text(
                      coupon.usageLimited
                          ? '${coupon.usedCount} / ${coupon.usageLimit}'
                          : '${coupon.usedCount} / Unlimited',
                    ),
                  ),
                  DataCell(Text(_date(coupon.startDate))),
                  DataCell(Text(_date(coupon.endDate))),
                  DataCell(
                    AdminCouponStatusChip(status: coupon.effectiveStatus),
                  ),
                  DataCell(
                    _Actions(
                      coupon: coupon,
                      busy:
                          coupon.id != null && deletingIds.contains(coupon.id),
                      onView: onView,
                      onEdit: onEdit,
                      onDelete: onDelete,
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    ),
  );
}

class _CouponCards extends StatelessWidget {
  const _CouponCards({
    required this.coupons,
    required this.deletingIds,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });
  final List<AdminCoupon> coupons;
  final Set<int> deletingIds;
  final Future<void> Function(AdminCoupon) onView;
  final Future<void> Function(AdminCoupon) onEdit;
  final Future<void> Function(AdminCoupon) onDelete;
  @override
  Widget build(BuildContext context) => Column(
    children: coupons
        .map(
          (coupon) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: AdminSectionCard(
              title: coupon.displayCode,
              subtitle:
                  '${coupon.displayDiscount} ${coupon.displayDiscountType.toLowerCase()} discount',
              trailing: AdminCouponStatusChip(status: coupon.effectiveStatus),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 18,
                    runSpacing: 10,
                    children: [
                      _MiniInfo(
                        label: 'Minimum order',
                        value: _money(coupon.minimumOrderAmount),
                      ),
                      _MiniInfo(
                        label: 'Usage',
                        value: coupon.usageLimited
                            ? '${coupon.usedCount}/${coupon.usageLimit}'
                            : '${coupon.usedCount}/Unlimited',
                      ),
                      _MiniInfo(label: 'Expires', value: _date(coupon.endDate)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Actions(
                    coupon: coupon,
                    busy: coupon.id != null && deletingIds.contains(coupon.id),
                    onView: onView,
                    onEdit: onEdit,
                    onDelete: onDelete,
                  ),
                ],
              ),
            ),
          ),
        )
        .toList(),
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
    required this.coupon,
    required this.busy,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });
  final AdminCoupon coupon;
  final bool busy;
  final Future<void> Function(AdminCoupon) onView;
  final Future<void> Function(AdminCoupon) onEdit;
  final Future<void> Function(AdminCoupon) onDelete;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 5,
    runSpacing: 5,
    children: [
      TextButton(
        onPressed: busy ? null : () => onView(coupon),
        child: const Text('View'),
      ),
      TextButton(
        onPressed: busy ? null : () => onEdit(coupon),
        child: const Text('Edit'),
      ),
      TextButton(
        onPressed: busy ? null : () => onDelete(coupon),
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
    title: filtered ? 'No matching coupons' : 'No coupons',
    subtitle: filtered
        ? 'Adjust the search or status filter.'
        : 'Create the first promotional coupon.',
    child: Center(
      child: Column(
        children: [
          const Icon(
            Icons.local_offer_outlined,
            size: 52,
            color: Color(0xFF64748B),
          ),
          const SizedBox(height: 12),
          Text(
            filtered
                ? 'No coupons match the current filters.'
                : 'No coupon data is available.',
          ),
          const SizedBox(height: 14),
          FilledButton.tonal(
            onPressed: filtered ? onClear : onCreate,
            child: Text(filtered ? 'Clear filters' : 'Create Coupon'),
          ),
        ],
      ),
    ),
  );
}

class _CouponsError extends StatelessWidget {
  const _CouponsError({required this.error, required this.onRetry});
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
        const Text('Unable to load coupons.'),
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
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });
  final int page;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  @override
  Widget build(BuildContext context) {
    final pages = (total / _AdminCouponsScreenState._pageSize).ceil();
    return AdminSectionCard(
      title: 'Pagination',
      subtitle: 'Page ${page + 1} of $pages',
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 10,
        runSpacing: 10,
        children: [
          OutlinedButton(onPressed: onPrevious, child: const Text('Previous')),
          FilledButton.tonal(onPressed: onNext, child: const Text('Next')),
        ],
      ),
    );
  }
}

String _date(DateTime? value) => value == null
    ? '—'
    : '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
String _money(double value) => '৳${value.toStringAsFixed(2)}';
