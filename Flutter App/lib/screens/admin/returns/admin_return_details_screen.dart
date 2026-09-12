import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../services/admin/admin_order_service.dart';
import '../../../services/admin/admin_return_service.dart';
import '../../../widgets/admin/admin_section_card.dart';
import '../../../widgets/admin/admin_shell.dart';
import '../../../widgets/product_image.dart';
import 'admin_returns_screen.dart';

class AdminReturnDetailsScreen extends StatefulWidget {
  const AdminReturnDetailsScreen({
    super.key,
    required this.returnId,
    this.initialRecord,
  });

  final int returnId;
  final AdminReturnRecord? initialRecord;

  @override
  State<AdminReturnDetailsScreen> createState() =>
      _AdminReturnDetailsScreenState();
}

class _AdminReturnDetailsScreenState extends State<AdminReturnDetailsScreen> {
  AdminReturnRecord? _record;
  Object? _error;
  bool _loading = true;
  bool _updating = false;
  bool _changed = false;
  bool _loaded = false;

  String get _token => context.read<AuthProvider>().token ?? '';
  AdminReturnService get _service => context.read<AdminReturnService>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    if (widget.initialRecord != null) {
      _record = widget.initialRecord;
      _loading = false;
    }
    _load(showLoading: widget.initialRecord == null);
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final record = await _service.getReturn(_token, widget.returnId);
      if (!mounted) return;
      setState(() {
        _record = record;
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

  Future<void> _updateStatus(String status) async {
    final record = _record;
    if (record?.request.id == null) return;
    final confirmed = await _confirm(
      title: '$status return?',
      message:
          '$status ${record!.request.displayId} for ${record.customerName}?',
      action: status,
      destructive: status == 'Rejected',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _updating = true);
    try {
      await _service.updateStatus(_token, record.request.id!, status);
      if (!mounted) return;
      _changed = true;
      await _load(showLoading: false);
      if (mounted) _message('Return marked ${status.toLowerCase()}.');
    } catch (error) {
      if (mounted) _message('Unable to update return: $error', error: true);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _updateNote() async {
    final record = _record;
    if (record?.request.id == null) return;
    final controller = TextEditingController(
      text: record!.request.adminNote ?? record.request.note ?? '',
    );
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update admin note?'),
        content: TextField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'Admin note',
            hintText: 'Add processing or resolution details',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Confirm update'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note == null || !mounted) return;

    setState(() => _updating = true);
    try {
      await _service.updateStatus(
        _token,
        record.request.id!,
        record.request.displayStatus,
        note: note,
      );
      if (!mounted) return;
      _changed = true;
      await _load(showLoading: false);
      if (mounted) _message('Admin note updated.');
    } catch (error) {
      if (mounted) _message('Unable to update admin note: $error', error: true);
    } finally {
      if (mounted) setState(() => _updating = false);
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

  void _back() => Navigator.of(context).pop(_changed);

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Return Details',
      activeItem: 'Returns',
      child: _loading && _record == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _record == null
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
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailsHeader(
                          record: _record!,
                          updating: _updating,
                          onBack: _back,
                          onApprove: () => _updateStatus('Approved'),
                          onReject: () => _updateStatus('Rejected'),
                          onComplete: () => _updateStatus('Completed'),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          _RefreshWarning(
                            error: _error,
                            onRetry: () => _load(showLoading: false),
                          ),
                        ],
                        const SizedBox(height: 20),
                        _StatusTimeline(record: _record!),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final left = Column(
                              children: [
                                _ReturnInformation(record: _record!),
                                const SizedBox(height: 18),
                                _ProductsCard(record: _record!),
                              ],
                            );
                            final right = Column(
                              children: [
                                _CustomerCard(record: _record!),
                                const SizedBox(height: 18),
                                _OrderCard(record: _record!),
                                const SizedBox(height: 18),
                                _NotesCard(
                                  record: _record!,
                                  updating: _updating,
                                  onUpdate: _updateNote,
                                ),
                              ],
                            );
                            if (constraints.maxWidth < 980) {
                              return Column(
                                children: [
                                  left,
                                  const SizedBox(height: 18),
                                  right,
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: left),
                                const SizedBox(width: 18),
                                Expanded(flex: 2, child: right),
                              ],
                            );
                          },
                        ),
                        if (_record!.request.imageUrls.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _AttachmentsCard(record: _record!),
                        ],
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

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({
    required this.record,
    required this.updating,
    required this.onBack,
    required this.onApprove,
    required this.onReject,
    required this.onComplete,
  });
  final AdminReturnRecord record;
  final bool updating;
  final VoidCallback onBack;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final status = record.request.normalizedStatus;
    final title = Row(
      children: [
        IconButton.filledTonal(
          tooltip: 'Back to returns',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.request.displayId,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Order ${record.orderReference} • ${record.customerName}',
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
        FilledButton.tonal(
          onPressed: updating || status == 'approved' ? null : onApprove,
          child: const Text('Approve'),
        ),
        OutlinedButton(
          onPressed: updating || status == 'rejected' ? null : onReject,
          child: const Text('Reject'),
        ),
        FilledButton(
          onPressed: updating || status == 'completed' ? null : onComplete,
          child: updating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Mark Completed'),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 780) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 12), actions],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            actions,
          ],
        );
      },
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.record});
  final AdminReturnRecord record;

  @override
  Widget build(BuildContext context) {
    final current = record.request.normalizedStatus;
    final steps = current == 'rejected'
        ? const ['Pending', 'Rejected']
        : const ['Pending', 'Approved', 'Completed'];
    final currentIndex = steps.indexWhere(
      (step) => step.toLowerCase() == current,
    );
    return AdminSectionCard(
      title: 'Return timeline',
      subtitle: 'Current processing stage',
      trailing: ReturnStatusChip(status: record.request.displayStatus),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final vertical = constraints.maxWidth < 620;
          Widget buildStep(MapEntry<int, String> entry) {
            final reached = entry.key <= (currentIndex < 0 ? 0 : currentIndex);
            return Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: reached
                        ? _statusColor(entry.value)
                        : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    reached ? Icons.check_rounded : Icons.circle_outlined,
                    size: 17,
                    color: reached ? Colors.white : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontWeight: reached ? FontWeight.w700 : FontWeight.w500,
                      color: reached
                          ? const Color(0xFF111827)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            );
          }

          final stepEntries = steps.asMap().entries;
          if (vertical) {
            return Column(
              children: stepEntries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: buildStep(entry),
                    ),
                  )
                  .toList(),
            );
          }
          return Row(
            children: stepEntries
                .map((entry) => Expanded(child: buildStep(entry)))
                .toList(),
          );
        },
      ),
    );
  }
}

class _ReturnInformation extends StatelessWidget {
  const _ReturnInformation({required this.record});
  final AdminReturnRecord record;

  @override
  Widget build(BuildContext context) {
    final request = record.request;
    return AdminSectionCard(
      title: 'Return information',
      subtitle: 'Reason, dates, and refund details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.reason ?? 'No reason was supplied.',
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 18),
          _InfoRow(
            label: 'Requested date',
            value: _formatDateTime(request.requestedAt),
          ),
          _InfoRow(
            label: 'Approved date',
            value: _formatDateTime(request.approvedAt),
          ),
          _InfoRow(
            label: 'Last updated',
            value: _formatDateTime(request.updatedAt),
          ),
          _InfoRow(label: 'Refund amount', value: _money(request.refundAmount)),
        ],
      ),
    );
  }
}

class _ProductsCard extends StatelessWidget {
  const _ProductsCard({required this.record});
  final AdminReturnRecord record;

  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Products',
    subtitle: 'Items included in this return request',
    child: record.products.isEmpty
        ? Text(
            record.productSummary,
            style: const TextStyle(color: Color(0xFF64748B)),
          )
        : Column(
            children: record.products
                .map((item) => _ProductRow(item: item))
                .toList(),
          ),
  );
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.item});
  final AdminOrderItem item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: ProductImage(
            imageUrl: item.imageUrl ?? '',
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name ?? 'Product #${item.productId ?? '—'}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  'Qty ${item.quantity}',
                  if (item.size != null) 'Size ${item.size}',
                  if (item.color != null) item.color!,
                ].join(' • '),
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 4),
              Text(
                '৳${item.lineTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.record});
  final AdminReturnRecord record;

  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Customer information',
    child: Column(
      children: [
        _InfoRow(label: 'Name', value: record.customerName),
        _InfoRow(label: 'Email', value: record.customerEmail),
        _InfoRow(label: 'Phone', value: record.order?.customerPhone),
        _InfoRow(
          label: 'Customer ID',
          value: record.request.customerId?.toString(),
        ),
      ],
    ),
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.record});
  final AdminReturnRecord record;

  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Order information',
    child: Column(
      children: [
        _InfoRow(label: 'Order', value: record.orderReference),
        _InfoRow(label: 'Order ID', value: record.request.orderId?.toString()),
        _InfoRow(label: 'Order status', value: record.order?.orderStatus),
        _InfoRow(label: 'Payment status', value: record.order?.paymentStatus),
        _InfoRow(
          label: 'Order total',
          value: record.order == null
              ? null
              : '৳${record.order!.totalAmount.toStringAsFixed(2)}',
        ),
      ],
    ),
  );
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({
    required this.record,
    required this.updating,
    required this.onUpdate,
  });
  final AdminReturnRecord record;
  final bool updating;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Notes',
    subtitle: 'Customer and processing notes supplied by the API',
    trailing: TextButton.icon(
      onPressed: updating ? null : onUpdate,
      icon: const Icon(Icons.edit_note_rounded),
      label: const Text('Update admin note'),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer note',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          record.request.note ?? 'No customer note provided.',
          style: const TextStyle(height: 1.45, color: Color(0xFF475569)),
        ),
        const Divider(height: 28),
        const Text('Admin note', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          record.request.adminNote ?? 'No admin note provided.',
          style: const TextStyle(height: 1.45, color: Color(0xFF475569)),
        ),
      ],
    ),
  );
}

class _AttachmentsCard extends StatelessWidget {
  const _AttachmentsCard({required this.record});
  final AdminReturnRecord record;

  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Return images',
    subtitle: 'Customer-provided attachments',
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      children: record.request.imageUrls
          .map(
            (url) => SizedBox(
              width: 180,
              height: 150,
              child: ProductImage(
                imageUrl: url,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 126,
          child: Text(label, style: const TextStyle(color: Color(0xFF64748B))),
        ),
        Expanded(
          child: Text(
            value?.trim().isNotEmpty == true ? value! : '—',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
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
          size: 52,
          color: Color(0xFF64748B),
        ),
        const SizedBox(height: 12),
        const Text('Unable to load return details.'),
        const SizedBox(height: 6),
        Text(error.toString(), textAlign: TextAlign.center),
        const SizedBox(height: 14),
        FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

Color _statusColor(String status) => switch (status.toLowerCase()) {
  'approved' => const Color(0xFF2563EB),
  'rejected' => const Color(0xFFDC2626),
  'completed' => const Color(0xFF059669),
  _ => const Color(0xFFF59E0B),
};

String _formatDateTime(DateTime? date) {
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
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute $period';
}

String _money(double? value) =>
    value == null ? '—' : '৳${value.toStringAsFixed(2)}';
