import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../services/admin/admin_payment_service.dart';
import '../../../widgets/admin/admin_section_card.dart';
import '../../../widgets/admin/admin_shell.dart';
import 'admin_payment_form_screen.dart';
import 'admin_payment_widgets.dart';

class AdminPaymentDetailsScreen extends StatefulWidget {
  const AdminPaymentDetailsScreen({
    super.key,
    required this.paymentId,
    this.initialRecord,
  });
  final int paymentId;
  final AdminPaymentRecord? initialRecord;

  @override
  State<AdminPaymentDetailsScreen> createState() =>
      _AdminPaymentDetailsScreenState();
}

class _AdminPaymentDetailsScreenState extends State<AdminPaymentDetailsScreen> {
  AdminPaymentRecord? _record;
  Object? _error;
  bool _loading = true;
  bool _deleting = false;
  bool _loaded = false;
  bool _changed = false;

  String get _token => context.read<AuthProvider>().token ?? '';
  AdminPaymentService get _service => context.read<AdminPaymentService>();

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
      final record = await _service.getPayment(_token, widget.paymentId);
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

  Future<void> _edit() async {
    final payment = _record?.payment;
    if (payment == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminPaymentFormScreen(payment: payment),
      ),
    );
    if (changed == true && mounted) {
      _changed = true;
      await _load(showLoading: false);
      if (mounted) _message('Payment updated successfully.');
    }
  }

  Future<void> _delete() async {
    final payment = _record?.payment;
    if (payment == null || payment.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete payment?'),
        content: Text(
          'Delete ${payment.displayId}? This action cannot be undone.',
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
      await _service.deletePayment(_token, payment.id!);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) _message('Unable to delete payment: $error', error: true);
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
  Widget build(BuildContext context) => AdminShell(
    title: 'Payment Details',
    activeItem: 'Payments',
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
                  constraints: const BoxConstraints(maxWidth: 1250),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        record: _record!,
                        deleting: _deleting,
                        onBack: () => Navigator.of(context).pop(_changed),
                        onEdit: _edit,
                        onDelete: _delete,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        _Warning(
                          error: _error,
                          onRetry: () => _load(showLoading: false),
                        ),
                      ],
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final payment = _PaymentCard(record: _record!);
                          final related = Column(
                            children: [
                              _OrderCard(record: _record!),
                              const SizedBox(height: 18),
                              _InvoiceCard(record: _record!),
                            ],
                          );
                          return constraints.maxWidth < 850
                              ? Column(
                                  children: [
                                    payment,
                                    const SizedBox(height: 18),
                                    related,
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 3, child: payment),
                                    const SizedBox(width: 18),
                                    Expanded(flex: 2, child: related),
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: 18),
                      AdminSectionCard(
                        title: 'Notes',
                        child: Text(
                          _record!.payment.notes ??
                              'No payment notes provided.',
                          style: const TextStyle(
                            height: 1.5,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _Metadata(payment: _record!.payment),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.record,
    required this.deleting,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
  });
  final AdminPaymentRecord record;
  final bool deleting;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final heading = Row(
      children: [
        IconButton.filledTonal(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.payment.displayId,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                record.payment.transactionId ?? 'No transaction ID',
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
                actions,
              ],
            ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.record});
  final AdminPaymentRecord record;
  @override
  Widget build(BuildContext context) {
    final p = record.payment;
    return AdminSectionCard(
      title: 'Payment information',
      subtitle: 'Transaction and settlement details',
      trailing: AdminPaymentStatusChip(status: p.displayStatus),
      child: Column(
        children: [
          _Row('Transaction ID', p.transactionId),
          _Row('Amount', _money(p.amount)),
          _Row('Payment method', p.paymentMethod),
          _Row('Payment status', p.displayStatus),
          _Row('Payment date', _date(p.paymentDate)),
          _Row('Customer', record.customerName),
          _Row('Customer email', record.customerEmail),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.record});
  final AdminPaymentRecord record;
  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Related order',
    child: Column(
      children: [
        _Row('Order reference', record.orderReference),
        _Row('Order ID', record.payment.orderId?.toString()),
        _Row('Order status', record.order?.orderStatus),
        _Row(
          'Order total',
          record.order == null ? null : _money(record.order!.totalAmount),
        ),
      ],
    ),
  );
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.record});
  final AdminPaymentRecord record;
  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Related invoice',
    child: Column(
      children: [
        _Row(
          'Invoice',
          record.invoice?.number ??
              (record.payment.invoiceId == null
                  ? null
                  : 'Invoice #${record.payment.invoiceId}'),
        ),
        _Row('Invoice ID', record.payment.invoiceId?.toString()),
        _Row(
          'Invoice total',
          record.invoice == null ? null : _money(record.invoice!.totalAmount),
        ),
        _Row('Invoice status', record.invoice?.paymentStatus),
      ],
    ),
  );
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.payment});
  final AdminPayment payment;
  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Metadata',
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _Pill('Payment ID', payment.id?.toString()),
        _Pill('Created', _date(payment.createdAt)),
        _Pill('Updated', _date(payment.updatedAt)),
        _Pill('Order ID', payment.orderId?.toString()),
        _Pill('Invoice ID', payment.invoiceId?.toString()),
      ],
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.value);
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

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
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

class _Warning extends StatelessWidget {
  const _Warning({required this.error, required this.onRetry});
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
          child: Text('Showing saved data because refresh failed: $error'),
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
        const Icon(Icons.cloud_off_outlined, size: 50),
        const SizedBox(height: 12),
        const Text('Unable to load payment details.'),
        const SizedBox(height: 6),
        Text(error.toString()),
        const SizedBox(height: 14),
        FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

String _date(DateTime? value) => value == null
    ? '—'
    : '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
String _money(double value) => '৳${value.toStringAsFixed(2)}';
