import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_provider.dart';
import '../../services/admin/admin_dashboard_service.dart';
import '../../widgets/admin/admin_dashboard_charts.dart';
import '../../widgets/admin/admin_section_card.dart';
import '../../widgets/admin/admin_shell.dart';
import '../../widgets/admin/admin_stat_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  static const routeName = '/admin';

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Future<AdminDashboardData>? _dashboard;
  bool _refreshing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dashboard ??= _load();
  }

  Future<AdminDashboardData> _load() {
    final token = context.read<AuthProvider>().token ?? '';
    return context.read<AdminDashboardService>().loadDashboard(token);
  }

  Future<void> _refresh() async {
    if (_refreshing) return;

    setState(() => _refreshing = true);

    try {
      final data = await _load();
      if (!mounted) return;

      setState(() {
        _dashboard = Future.value(data);
        _refreshing = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _refreshing = false);
      final message = error is AdminDashboardException
          ? error.toString()
          : 'Dashboard could not be refreshed. Your existing data is still shown.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Dashboard',
      activeItem: 'Dashboard',
      child: FutureBuilder<AdminDashboardData>(
        future: _dashboard,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const _DashboardLoading();
          }
          if (snapshot.hasError && !snapshot.hasData) {
            return _DashboardError(error: snapshot.error, onRetry: _refresh);
          }
          final data = snapshot.data;
          return data == null
              ? _DashboardError(error: snapshot.error, onRetry: _refresh)
              : _DashboardBody(
                  data: data,
                  refreshing: _refreshing,
                  onRefresh: _refresh,
                );
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.data,
    required this.refreshing,
    required this.onRefresh,
  });

  final AdminDashboardData data;
  final bool refreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(refreshing: refreshing, onRefresh: onRefresh),
                const SizedBox(height: 24),
                _Stats(data: data),
                const SizedBox(height: 24),
                const _QuickActions(),
                const SizedBox(height: 24),
                _Trends(data: data),
                const SizedBox(height: 24),
                _Distributions(data: data),
                const SizedBox(height: 24),
                _Products(data: data),
                const SizedBox(height: 24),
                _RecentActivity(data: data),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.refreshing, required this.onRefresh});

  final bool refreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Store analytics',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Sales performance, operations, and items needing attention.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      ],
    );
    final refreshButton = FilledButton.tonalIcon(
      onPressed: refreshing ? null : onRefresh,
      icon: refreshing
          ? const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh_rounded),
      label: Text(refreshing ? 'Refreshing' : 'Refresh'),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [heading, const SizedBox(height: 12), refreshButton],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: heading),
            const SizedBox(width: 12),
            refreshButton,
          ],
        );
      },
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.data});

  final AdminDashboardData data;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _stat(
        context,
        'Total Products',
        '${data.totalProducts}',
        Icons.inventory_2_outlined,
        const Color(0xFF2563EB),
        '/admin/products',
      ),
      _stat(
        context,
        'Total Orders',
        '${data.totalOrders}',
        Icons.shopping_bag_outlined,
        const Color(0xFF7C3AED),
        '/admin/orders',
      ),
      _stat(
        context,
        'Total Customers',
        '${data.totalCustomers}',
        Icons.people_outline,
        const Color(0xFF0891B2),
        '/admin/customers',
      ),
      _stat(
        context,
        'Total Revenue',
        _money(data.totalRevenue),
        Icons.trending_up,
        const Color(0xFF059669),
        null,
      ),
      _stat(
        context,
        'Pending Orders',
        '${data.pendingOrders}',
        Icons.schedule,
        const Color(0xFFF59E0B),
        '/admin/orders',
      ),
      _stat(
        context,
        'Low Stock Products',
        '${data.lowStockProducts}',
        Icons.inventory_outlined,
        const Color(0xFFEA580C),
        '/admin/products',
      ),
      _stat(
        context,
        'Pending Returns',
        '${data.pendingReturns}',
        Icons.assignment_return_outlined,
        const Color(0xFFDC2626),
        '/admin/returns',
      ),
      _stat(
        context,
        'Pending Reviews',
        '${data.pendingReviews}',
        Icons.rate_review_outlined,
        const Color(0xFFDB2777),
        '/admin/reviews',
      ),
      _stat(
        context,
        'Paid Payments',
        '${data.paidPayments}',
        Icons.verified_outlined,
        const Color(0xFF0F766E),
        '/admin/payments',
      ),
      _stat(
        context,
        'Pending Invoices',
        '${data.pendingInvoices}',
        Icons.description_outlined,
        const Color(0xFF9333EA),
        '/admin/invoices',
      ),
    ];
    return _Grid(minWidth: 225, maxColumns: 5, children: cards);
  }

  Widget _stat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    String? route,
  ) {
    return AdminStatCard(
      label: label,
      value: value,
      icon: icon,
      color: color,
      onTap: route == null ? null : () => _open(context, route),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  static const actions = [
    (
      'Manage Products',
      Icons.inventory_2_outlined,
      Color(0xFF2563EB),
      '/admin/products',
    ),
    (
      'Manage Orders',
      Icons.receipt_long_outlined,
      Color(0xFF7C3AED),
      '/admin/orders',
    ),
    (
      'Manage Customers',
      Icons.people_outline,
      Color(0xFF0891B2),
      '/admin/customers',
    ),
    (
      'Manage Reviews',
      Icons.rate_review_outlined,
      Color(0xFFDB2777),
      '/admin/reviews',
    ),
    (
      'Manage Returns',
      Icons.assignment_return_outlined,
      Color(0xFFDC2626),
      '/admin/returns',
    ),
    (
      'Manage Coupons',
      Icons.local_offer_outlined,
      Color(0xFF059669),
      '/admin/coupons',
    ),
    (
      'Manage Payments',
      Icons.payments_outlined,
      Color(0xFF0F766E),
      '/admin/payments',
    ),
    (
      'Manage Invoices',
      Icons.description_outlined,
      Color(0xFF9333EA),
      '/admin/invoices',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'Quick actions',
      subtitle: 'Open a management workspace',
      child: _Grid(
        minWidth: 165,
        maxColumns: 4,
        children: actions.map((action) {
          return Material(
            color: action.$3.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => _open(context, action.$4),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: action.$3.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(action.$2, color: action.$3, size: 20),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        action.$1,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF94A3B8),
                      size: 19,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Trends extends StatelessWidget {
  const _Trends({required this.data});

  final AdminDashboardData data;

  @override
  Widget build(BuildContext context) {
    return _Grid(
      minWidth: 420,
      maxColumns: 2,
      children: [
        AdminSectionCard(
          title: 'Monthly revenue trend',
          subtitle: 'Gross order value by month',
          trailing: const _Badge(label: 'Revenue', color: Color(0xFF2563EB)),
          child: AdminTrendChart(
            points: data.revenueTrend,
            color: const Color(0xFF2563EB),
            currency: true,
          ),
        ),
        AdminSectionCard(
          title: 'Monthly orders trend',
          subtitle: 'Order volume by month',
          trailing: const _Badge(label: 'Orders', color: Color(0xFF7C3AED)),
          child: AdminTrendChart(
            points: data.ordersTrend,
            color: const Color(0xFF7C3AED),
          ),
        ),
      ],
    );
  }
}

class _Distributions extends StatelessWidget {
  const _Distributions({required this.data});

  final AdminDashboardData data;

  static const colors = [
    Color(0xFF2563EB),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
  ];

  @override
  Widget build(BuildContext context) {
    return _Grid(
      minWidth: 285,
      maxColumns: 3,
      children: [
        _distribution(
          'Order status',
          'Current order distribution',
          data.orderStatuses,
        ),
        _distribution(
          'Payment status',
          'Payment processing health',
          data.paymentStatuses,
        ),
        _distribution(
          'Returns status',
          'Return request outcomes',
          data.returnStatuses,
        ),
      ],
    );
  }

  Widget _distribution(
    String title,
    String subtitle,
    List<AdminDistributionItem> items,
  ) {
    return AdminSectionCard(
      title: title,
      subtitle: subtitle,
      child: AdminDistributionChart(items: items, colors: colors),
    );
  }
}

class _Products extends StatelessWidget {
  const _Products({required this.data});

  final AdminDashboardData data;

  @override
  Widget build(BuildContext context) {
    return _Grid(
      minWidth: 420,
      maxColumns: 2,
      children: [
        AdminSectionCard(
          title: 'Top selling products',
          subtitle: 'Products ranked by units sold',
          trailing: _Link(label: 'View products', route: '/admin/products'),
          child: _TopProducts(items: data.topProducts),
        ),
        AdminSectionCard(
          title: 'Low stock products',
          subtitle: 'Inventory requiring replenishment',
          trailing: _Link(label: 'Manage stock', route: '/admin/products'),
          child: _ItemList(
            emptyIcon: Icons.inventory_2_outlined,
            emptyMessage: 'Inventory looks healthy.',
            items: data.lowStockItems.map((item) {
              final critical = item.stock <= 2;
              final color = critical
                  ? const Color(0xFFDC2626)
                  : const Color(0xFFEA580C);
              return _ActivityItem(
                icon: Icons.inventory_2_outlined,
                color: color,
                title: item.name,
                subtitle: critical ? 'Critical stock level' : 'Reorder soon',
                status: '${item.stock} left',
                statusColor: color,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _TopProducts extends StatelessWidget {
  const _TopProducts({required this.items});

  final List<AdminTopProduct> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _Empty(
        icon: Icons.leaderboard_outlined,
        message: 'No product sales data available yet.',
      );
    }
    final maximum = items.fold<int>(
      1,
      (value, item) => math.max(value, item.quantity),
    );
    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.quantity} sold',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _money(item.revenue),
                    style: const TextStyle(
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: item.quantity / maximum,
                  minHeight: 6,
                  color: const Color(0xFF2563EB),
                  backgroundColor: const Color(0xFFEFF6FF),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.data});

  final AdminDashboardData data;

  @override
  Widget build(BuildContext context) {
    final paymentItems = data.recentPayments
        .map(
          (item) => _ActivityItem(
            icon: Icons.payments_outlined,
            color: const Color(0xFF0F766E),
            title: item.customerName ?? item.displayId,
            subtitle:
                '${item.displayId} · ${item.paymentMethod ?? 'Method unavailable'}',
            amount: _money(item.amount),
            status: item.displayStatus,
            statusColor: _statusColor(item.displayStatus),
          ),
        )
        .toList();
    final invoiceItems = data.recentInvoices
        .map(
          (item) => _ActivityItem(
            icon: Icons.description_outlined,
            color: const Color(0xFF9333EA),
            title: item.displayNumber,
            subtitle:
                item.customerName ??
                item.orderReference ??
                'Customer unavailable',
            amount: _money(item.totalAmount),
            status: item.paymentStatus ?? item.displayStatus,
            statusColor: _statusColor(item.paymentStatus ?? item.displayStatus),
          ),
        )
        .toList();
    final returnItems = data.recentReturns
        .map(
          (item) => _ActivityItem(
            icon: Icons.assignment_return_outlined,
            color: const Color(0xFFDC2626),
            title: item.displayId,
            subtitle:
                item.customerName ??
                item.orderReference ??
                'Order #${item.orderId ?? '—'}',
            status: item.displayStatus,
            statusColor: _statusColor(item.displayStatus),
          ),
        )
        .toList();
    final reviewItems = data.pendingReviewItems
        .map(
          (item) => _ActivityItem(
            icon: Icons.rate_review_outlined,
            color: const Color(0xFFDB2777),
            title: item.displayProductName,
            subtitle: '${item.displayCustomerName} · ${item.displayTitle}',
            amount: '★ ${item.rating ?? 0}',
            status: 'Pending',
            statusColor: const Color(0xFFF59E0B),
          ),
        )
        .toList();

    return _Grid(
      minWidth: 420,
      maxColumns: 2,
      children: [
        _activity(
          'Recent payments',
          'Latest payment activity',
          'View all',
          '/admin/payments',
          Icons.payments_outlined,
          paymentItems,
        ),
        _activity(
          'Recent invoices',
          'Latest issued invoices',
          'View all',
          '/admin/invoices',
          Icons.description_outlined,
          invoiceItems,
        ),
        _activity(
          'Recent returns',
          'Newest return requests',
          'View all',
          '/admin/returns',
          Icons.assignment_return_outlined,
          returnItems,
        ),
        _activity(
          'Pending reviews',
          'Feedback awaiting moderation',
          'Moderate',
          '/admin/reviews',
          Icons.rate_review_outlined,
          reviewItems,
        ),
      ],
    );
  }

  Widget _activity(
    String title,
    String subtitle,
    String link,
    String route,
    IconData emptyIcon,
    List<_ActivityItem> items,
  ) {
    return AdminSectionCard(
      title: title,
      subtitle: subtitle,
      trailing: _Link(label: link, route: route),
      child: _ItemList(
        items: items,
        emptyIcon: emptyIcon,
        emptyMessage: 'No records available yet.',
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  const _ItemList({
    required this.items,
    required this.emptyIcon,
    required this.emptyMessage,
  });

  final List<_ActivityItem> items;
  final IconData emptyIcon;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _Empty(icon: emptyIcon, message: emptyMessage);
    }
    return Column(
      children: List.generate(
        items.length,
        (index) => _ActivityRow(
          item: items[index],
          divider: index != items.length - 1,
        ),
      ),
    );
  }
}

class _ActivityItem {
  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    this.amount,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final String? amount;
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item, required this.divider});

  final _ActivityItem item;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: divider
            ? const Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (item.amount != null) ...[
                Text(
                  item.amount!,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
              ],
              _Badge(label: item.status, color: item.statusColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 105),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.label, required this.route});

  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _open(context, route),
      child: Text(label),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.children,
    required this.minWidth,
    required this.maxColumns,
  });

  final List<Widget> children;
  final double minWidth;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    const gap = 18.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final possible = ((constraints.maxWidth + gap) / (minWidth + gap))
            .floor();
        final columns = possible.clamp(1, maxColumns);
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF94A3B8), size: 30),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1540),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Skeleton(width: 230, height: 30),
              const SizedBox(height: 10),
              const _Skeleton(width: 420, height: 15),
              const SizedBox(height: 26),
              _Grid(
                minWidth: 225,
                maxColumns: 5,
                children: List.generate(10, (_) => const _Skeleton(height: 88)),
              ),
              const SizedBox(height: 24),
              _Grid(
                minWidth: 420,
                maxColumns: 2,
                children: List.generate(2, (_) => const _Skeleton(height: 300)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({this.width, required this.height});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF2F7), Color(0xFFF8FAFC), Color(0xFFEFF2F7)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.error, required this.onRetry});

  final Object? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error is AdminDashboardException
        ? error.toString()
        : 'Dashboard data could not be loaded. Check your connection and try again.';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8ECF3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: Color(0xFF64748B),
              ),
              const SizedBox(height: 14),
              Text(
                'Unable to refresh analytics',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _open(BuildContext context, String route) {
  Navigator.of(context).pushNamed(route);
}

Color _statusColor(String? status) {
  final value = status?.trim().toLowerCase() ?? '';
  if (const {
    'paid',
    'completed',
    'approved',
    'success',
    'delivered',
  }.contains(value)) {
    return const Color(0xFF059669);
  }
  if (const {'rejected', 'cancelled', 'failed', 'overdue'}.contains(value)) {
    return const Color(0xFFDC2626);
  }
  if (value == 'refunded') return const Color(0xFF7C3AED);
  return const Color(0xFFF59E0B);
}

String _money(double value) => '৳${value.toStringAsFixed(2)}';
