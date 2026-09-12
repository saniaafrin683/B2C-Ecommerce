import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api_client.dart';
import '../../../core/auth_provider.dart';
import '../../../services/admin/admin_invoice_service.dart';
import '../../../widgets/admin/admin_section_card.dart';
import '../../../widgets/admin/admin_shell.dart';
import '../../../widgets/product_image.dart';
import 'admin_invoice_form_screen.dart';
import 'admin_invoice_widgets.dart';

class AdminInvoiceDetailsScreen extends StatefulWidget {
  const AdminInvoiceDetailsScreen({
    super.key,
    required this.invoiceId,
    this.initialRecord,
  });

  final int invoiceId;
  final AdminInvoiceRecord? initialRecord;

  @override
  State<AdminInvoiceDetailsScreen> createState() =>
      _AdminInvoiceDetailsScreenState();
}

class _AdminInvoiceDetailsScreenState extends State<AdminInvoiceDetailsScreen> {
  AdminInvoiceRecord? _record;
  Object? _error;
  bool _loading = true;
  bool _deleting = false;
  bool _loaded = false;
  bool _changed = false;

  String get _token => context.read<AuthProvider>().token ?? '';
  AdminInvoiceService get _service => context.read<AdminInvoiceService>();

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
      final record = await _service.getInvoice(_token, widget.invoiceId);
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
    final invoice = _record?.invoice;
    if (invoice == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AdminInvoiceFormScreen(invoice: invoice)),
    );
    if (changed == true && mounted) {
      _changed = true;
      await _load(showLoading: false);
      if (mounted) _message('Invoice updated successfully.');
    }
  }

  Future<void> _delete() async {
    final invoice = _record?.invoice;
    if (invoice == null || invoice.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete invoice?'),
        content: Text(
          'Delete ${invoice.displayNumber}? This action cannot be undone.',
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
      await _service.deleteInvoice(_token, invoice.id!);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) _message('Unable to delete invoice: $error', error: true);
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
      title: 'Invoice Details',
      activeItem: 'Invoices',
      child: _loading && _record == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _record == null
          ? _ErrorState(error: _error, onRetry: _load)
          : RefreshIndicator(
              onRefresh: () => _load(showLoading: false),
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
                            final summary = _InvoiceSummaryCard(
                              record: _record!,
                            );
                            final side = Column(
                              children: [
                                _CustomerCard(record: _record!),
                                const SizedBox(height: 18),
                                _OrderCard(record: _record!),
                              ],
                            );
                            if (constraints.maxWidth < 900) {
                              return Column(
                                children: [
                                  summary,
                                  const SizedBox(height: 18),
                                  side,
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: summary),
                                const SizedBox(width: 18),
                                Expanded(flex: 2, child: side),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        _ProductsCard(record: _record!),
                        const SizedBox(height: 18),
                        _TotalsCard(record: _record!),
                        const SizedBox(height: 18),
                        _NotesCard(record: _record!),
                        const SizedBox(height: 18),
                        _MetadataCard(record: _record!),
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
    required this.record,
    required this.deleting,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminInvoiceRecord record;
  final bool deleting;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final heading = Row(
      children: [
        IconButton.filledTonal(
          tooltip: 'Back to invoices',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.invoice.displayNumber,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 5),
              Text(
                'Order ${record.orderReference}',
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
              children: [Expanded(child: heading), const SizedBox(width: 12), actions],
            ),
    );
  }
}

class _InvoiceSummaryCard extends StatelessWidget {
  const _InvoiceSummaryCard({required this.record});

  final AdminInvoiceRecord record;

  @override
  Widget build(BuildContext context) {
    final invoice = record.invoice;
    return AdminSectionCard(
      title: 'Invoice information',
      subtitle: 'Billing, payment, and totals',
      trailing: adminInvoiceStatusChip(invoice.displayStatus),
      child: Column(
        children: [
          _Row('Invoice number', invoice.invoiceNumber),
          _Row('Order reference', record.orderReference),
          _Row('Order ID', invoice.orderId?.toString()),
          _Row('Payment status', invoice.paymentStatus),
          _Row('Invoice status', invoice.displayStatus),
          _Row('Payment method', invoice.paymentMethod),
          _Row('Issue date', adminInvoiceDate(invoice.issueDate)),
          _Row('Due date', adminInvoiceDate(invoice.dueDate)),
          _Row('Subtotal', adminInvoiceMoney(invoice.subtotal)),
          _Row('Regular subtotal', adminInvoiceMoney(invoice.regularSubtotal)),
          _Row(
            'Product discount',
            adminInvoiceMoney(invoice.productDiscountTotal),
          ),
          _Row(
            'After product discount',
            adminInvoiceMoney(invoice.subtotalAfterProductDiscount),
          ),
          _Row('Tax', adminInvoiceMoney(invoice.tax)),
          _Row('Discount', adminInvoiceMoney(invoice.discount)),
          _Row('Coupon discount', adminInvoiceMoney(invoice.couponDiscount)),
          _Row('Shipping charge', adminInvoiceMoney(invoice.shippingCost)),
          _Row('Grand total', adminInvoiceMoney(invoice.totalAmount)),
          if (invoice.couponCode != null) _Row('Coupon code', invoice.couponCode),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.record});

  final AdminInvoiceRecord record;

  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Customer information',
    child: Column(
      children: [
        _Row('Name', record.customerName),
        _Row('Email', record.customerEmail),
        _Row('Phone', record.customerPhone),
        _Row('Billing address', record.invoice.billingAddress),
      ],
    ),
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.record});

  final AdminInvoiceRecord record;

  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Order information',
    child: Column(
      children: [
        _Row('Order reference', record.orderReference),
        _Row('Order ID', record.invoice.orderId?.toString()),
        _Row('Order total', record.order == null ? null : adminInvoiceMoney(record.order!.totalAmount)),
        _Row('Order payment status', record.order?.paymentStatus),
        _Row('Order status', record.order?.orderStatus),
      ],
    ),
  );
}

class _ProductsCard extends StatelessWidget {
  const _ProductsCard({required this.record});

  final AdminInvoiceRecord record;

  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Products',
    subtitle: 'Items linked to the invoice order',
    child: record.items.isEmpty
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 22),
            child: Center(child: Text('No order items are available.')),
          )
        : Column(
            children: record.items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final image = SizedBox(
                          width: 62,
                          height: 62,
                          child: ProductImage(
                            imageUrl: context.read<ApiClient>().normalizeImageUrl(
                              item.imageUrl,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                        final content = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name ?? 'Unnamed product',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (item.size != null) 'Size: ${item.size}',
                                if (item.color != null) 'Color: ${item.color}',
                              ].join(' • '),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        );
                        final quantity = Text(
                          '${item.quantity} × ${adminInvoiceMoney(item.unitPrice)}',
                          style: const TextStyle(color: Color(0xFF64748B)),
                        );
                        final total = Text(
                          adminInvoiceMoney(item.lineTotal),
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        );
                        if (constraints.maxWidth < 560) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  image,
                                  const SizedBox(width: 13),
                                  Expanded(child: content),
                                ],
                              ),
                              const SizedBox(height: 9),
                              Row(
                                children: [quantity, const Spacer(), total],
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            image,
                            const SizedBox(width: 13),
                            Expanded(child: content),
                            const SizedBox(width: 10),
                            quantity,
                            const SizedBox(width: 18),
                            SizedBox(width: 90, child: total),
                          ],
                        );
                      },
                    ),
                  ),
                )
                .toList(),
          ),
  );
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.record});

  final AdminInvoiceRecord record;

  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Totals',
    subtitle: 'Invoice subtotal and adjustments',
    child: Column(
      children: [
        _Row('Subtotal', adminInvoiceMoney(record.invoice.subtotal)),
        _Row(
          'Regular subtotal',
          adminInvoiceMoney(record.invoice.regularSubtotal),
        ),
        _Row(
          'Product discount total',
          adminInvoiceMoney(record.invoice.productDiscountTotal),
        ),
        _Row('Subtotal after product discount', adminInvoiceMoney(record.invoice.subtotalAfterProductDiscount)),
        _Row('Tax', adminInvoiceMoney(record.invoice.tax)),
        _Row('Discount', adminInvoiceMoney(record.invoice.discount)),
        _Row('Coupon discount', adminInvoiceMoney(record.invoice.couponDiscount)),
        _Row('Shipping charge', adminInvoiceMoney(record.invoice.shippingCost)),
        _Row('Grand total', adminInvoiceMoney(record.invoice.totalAmount)),
      ],
    ),
  );
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.record});

  final AdminInvoiceRecord record;

  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Notes',
    child: Text(
      record.invoice.notes?.trim().isNotEmpty == true
          ? record.invoice.notes!.trim()
          : 'No invoice notes provided.',
      style: const TextStyle(height: 1.5, color: Color(0xFF334155)),
    ),
  );
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.record});

  final AdminInvoiceRecord record;

  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: 'Metadata',
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _Meta(label: 'Invoice ID', value: record.invoice.id?.toString()),
        _Meta(label: 'Order ID', value: record.invoice.orderId?.toString()),
        _Meta(label: 'Coupon code', value: record.invoice.couponCode),
        _Meta(label: 'Payment status', value: record.invoice.paymentStatus),
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
          width: 150,
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object? error;
  final Future<void> Function({bool showLoading}) onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_off_outlined, size: 50, color: Color(0xFF64748B)),
        const SizedBox(height: 12),
        const Text('Unable to load invoice details.'),
        const SizedBox(height: 6),
        Text(error.toString()),
        const SizedBox(height: 14),
        FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
