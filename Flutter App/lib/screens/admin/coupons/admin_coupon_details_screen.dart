import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../services/admin/admin_coupon_service.dart';
import '../../../widgets/admin/admin_section_card.dart';
import '../../../widgets/admin/admin_shell.dart';
import 'admin_coupon_form_screen.dart';
import 'admin_coupon_widgets.dart';

class AdminCouponDetailsScreen extends StatefulWidget {
  const AdminCouponDetailsScreen({
    super.key,
    required this.couponId,
    this.initialCoupon,
  });

  final int couponId;
  final AdminCoupon? initialCoupon;

  @override
  State<AdminCouponDetailsScreen> createState() =>
      _AdminCouponDetailsScreenState();
}

class _AdminCouponDetailsScreenState extends State<AdminCouponDetailsScreen> {
  AdminCoupon? _coupon;
  Object? _error;
  bool _loading = true;
  bool _deleting = false;
  bool _loaded = false;
  bool _changed = false;

  String get _token => context.read<AuthProvider>().token ?? '';
  AdminCouponService get _service => context.read<AdminCouponService>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    if (widget.initialCoupon != null) {
      _coupon = widget.initialCoupon;
      _loading = false;
    }
    _load(showLoading: widget.initialCoupon == null);
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final coupon = await _service.getCoupon(_token, widget.couponId);
      if (!mounted) return;
      setState(() {
        _coupon = coupon;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  Future<void> _edit() async {
    final coupon = _coupon;
    if (coupon == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AdminCouponFormScreen(coupon: coupon)),
    );
    if (changed == true && mounted) {
      _changed = true;
      await _load(showLoading: false);
      if (mounted) _message('Coupon updated successfully.');
    }
  }

  Future<void> _delete() async {
    final coupon = _coupon;
    if (coupon == null || coupon.id == null) return;
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

    setState(() => _deleting = true);
    try {
      await _service.deleteCoupon(_token, coupon.id!);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) _message('Unable to delete coupon: $error', error: true);
    } finally {
      if (mounted) setState(() => _deleting = false);
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
      title: 'Coupon Details',
      activeItem: 'Coupons',
      child: _loading && _coupon == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _coupon == null
          ? _DetailsError(error: _error, onRetry: _load)
          : RefreshIndicator(
              onRefresh: () => _load(showLoading: false),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(
                          coupon: _coupon!,
                          deleting: _deleting,
                          onBack: () => Navigator.of(context).pop(_changed),
                          onEdit: _edit,
                          onDelete: _delete,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          _RefreshWarning(
                            error: _error,
                            onRetry: () => _load(showLoading: false),
                          ),
                        ],
                        const SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final overview = _OverviewCard(coupon: _coupon!);
                            final usage = _UsageCard(coupon: _coupon!);
                            if (constraints.maxWidth < 800) {
                              return Column(
                                children: [
                                  overview,
                                  const SizedBox(height: 18),
                                  usage,
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: overview),
                                const SizedBox(width: 18),
                                Expanded(flex: 2, child: usage),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        _DescriptionCard(coupon: _coupon!),
                        const SizedBox(height: 18),
                        _MetadataCard(coupon: _coupon!),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.coupon,
    required this.deleting,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
  });
  final AdminCoupon coupon;
  final bool deleting;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final heading = Row(
      children: [
        IconButton.filledTonal(
          tooltip: 'Back to coupons',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                coupon.displayCode,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '${coupon.displayDiscount} ${coupon.displayDiscountType.toLowerCase()} discount',
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.tonalIcon(
          onPressed: deleting ? null : onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit'),
        ),
        OutlinedButton.icon(
          onPressed: deleting ? null : onDelete,
          icon: deleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline),
          label: const Text('Delete'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFDC2626),
          ),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 650
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [heading, const SizedBox(height: 12), actions],
            )
          : Row(
              children: [
                Expanded(child: heading),
                const SizedBox(width: 12),
                actions,
              ],
            ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.coupon});
  final AdminCoupon coupon;

  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Coupon overview',
    subtitle: 'Discount and eligibility rules',
    trailing: AdminCouponStatusChip(status: coupon.effectiveStatus),
    child: Column(
      children: [
        _InfoRow(label: 'Coupon code', value: coupon.displayCode),
        _InfoRow(label: 'Discount type', value: coupon.displayDiscountType),
        _InfoRow(label: 'Discount value', value: coupon.displayDiscount),
        _InfoRow(
          label: 'Minimum order',
          value: _money(coupon.minimumOrderAmount),
        ),
        _InfoRow(label: 'Start date', value: _formatDate(coupon.startDate)),
        _InfoRow(label: 'Expiry date', value: _formatDate(coupon.endDate)),
        _InfoRow(label: 'Configured status', value: coupon.status),
      ],
    ),
  );
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.coupon});
  final AdminCoupon coupon;

  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Usage information',
    subtitle: coupon.usageLimited
        ? '${coupon.usedCount} of ${coupon.usageLimit} uses'
        : '${coupon.usedCount} uses • Unlimited',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${coupon.usedCount}',
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(color: const Color(0xFF111827)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Successful redemptions',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 18),
        LinearProgressIndicator(
          value: coupon.usageLimited ? coupon.usageProgress : null,
          minHeight: 10,
          borderRadius: BorderRadius.circular(20),
        ),
        const SizedBox(height: 10),
        Text(
          coupon.usageLimited
              ? '${coupon.usageLimit - coupon.usedCount > 0 ? coupon.usageLimit - coupon.usedCount : 0} uses remaining'
              : 'No usage limit configured',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.coupon});
  final AdminCoupon coupon;
  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Description',
    child: Text(
      coupon.description ?? 'No description provided.',
      style: const TextStyle(height: 1.5, color: Color(0xFF334155)),
    ),
  );
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.coupon});
  final AdminCoupon coupon;
  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Metadata',
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _Meta(label: 'Coupon ID', value: coupon.id?.toString()),
        _Meta(label: 'Created', value: _formatDate(coupon.createdAt)),
        _Meta(label: 'Updated', value: _formatDate(coupon.updatedAt)),
        _Meta(label: 'Effective status', value: coupon.effectiveStatus),
      ],
    ),
  );
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});
  final String label;
  final String? value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 3),
        Text(
          value?.trim().isNotEmpty == true ? value! : '—',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String? value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: const TextStyle(color: Color(0xFF64748B))),
        ),
        Expanded(
          child: Text(
            value?.trim().isNotEmpty == true ? value! : '—',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _RefreshWarning extends StatelessWidget {
  const _RefreshWarning({required this.error, required this.onRetry});
  final Object? error;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.sync_problem_rounded, color: Color(0xFFB91C1C)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Showing saved data because refresh failed: $error',
            style: const TextStyle(color: Color(0xFF991B1B)),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class _DetailsError extends StatelessWidget {
  const _DetailsError({required this.error, required this.onRetry});
  final Object? error;
  final Future<void> Function({bool showLoading}) onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          size: 50,
          color: Color(0xFF64748B),
        ),
        const SizedBox(height: 12),
        const Text('Unable to load coupon details.'),
        const SizedBox(height: 6),
        Text(error.toString()),
        const SizedBox(height: 14),
        FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

String _formatDate(DateTime? value) => value == null
    ? '—'
    : '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
String _money(double value) => '৳${value.toStringAsFixed(2)}';
