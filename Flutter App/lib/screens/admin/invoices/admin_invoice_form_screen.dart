import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../services/admin/admin_invoice_service.dart';
import '../../../widgets/admin/admin_section_card.dart';
import '../../../widgets/admin/admin_shell.dart';
import 'admin_invoice_widgets.dart';

class AdminInvoiceFormScreen extends StatefulWidget {
  const AdminInvoiceFormScreen({super.key, this.invoice});

  final AdminInvoice? invoice;

  @override
  State<AdminInvoiceFormScreen> createState() => _AdminInvoiceFormScreenState();
}

class _AdminInvoiceFormScreenState extends State<AdminInvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _invoiceNumberController;
  late final TextEditingController _orderIdController;
  late final TextEditingController _orderReferenceController;
  late final TextEditingController _customerNameController;
  late final TextEditingController _customerEmailController;
  late final TextEditingController _customerPhoneController;
  late final TextEditingController _billingAddressController;
  late final TextEditingController _subtotalController;
  late final TextEditingController _regularSubtotalController;
  late final TextEditingController _productDiscountTotalController;
  late final TextEditingController _subtotalAfterProductDiscountController;
  late final TextEditingController _taxController;
  late final TextEditingController _discountController;
  late final TextEditingController _couponDiscountController;
  late final TextEditingController _couponCodeController;
  late final TextEditingController _shippingCostController;
  late final TextEditingController _totalAmountController;
  late final TextEditingController _paymentMethodController;
  late final TextEditingController _notesController;

  late String _paymentStatus;
  DateTime? _issueDate;
  DateTime? _dueDate;
  bool _submitting = false;

  bool get _editing => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    final invoice = widget.invoice;
    _invoiceNumberController = TextEditingController(
      text: invoice?.invoiceNumber ?? '',
    );
    _orderIdController = TextEditingController(
      text: invoice?.orderId?.toString() ?? '',
    );
    _orderReferenceController = TextEditingController(
      text: invoice?.orderReference ?? '',
    );
    _customerNameController = TextEditingController(
      text: invoice?.customerName ?? '',
    );
    _customerEmailController = TextEditingController(
      text: invoice?.customerEmail ?? '',
    );
    _customerPhoneController = TextEditingController(
      text: invoice?.customerPhone ?? '',
    );
    _billingAddressController = TextEditingController(
      text: invoice?.billingAddress ?? '',
    );
    _subtotalController = TextEditingController(
      text: invoice == null ? '0' : _compact(invoice.subtotal),
    );
    _regularSubtotalController = TextEditingController(
      text: invoice == null ? '0' : _compact(invoice.regularSubtotal),
    );
    _productDiscountTotalController = TextEditingController(
      text: invoice == null ? '0' : _compact(invoice.productDiscountTotal),
    );
    _subtotalAfterProductDiscountController = TextEditingController(
      text: invoice == null
          ? '0'
          : _compact(invoice.subtotalAfterProductDiscount),
    );
    _taxController = TextEditingController(
      text: invoice == null ? '0' : _compact(invoice.tax),
    );
    _discountController = TextEditingController(
      text: invoice == null ? '0' : _compact(invoice.discount),
    );
    _couponDiscountController = TextEditingController(
      text: invoice == null ? '0' : _compact(invoice.couponDiscount),
    );
    _couponCodeController = TextEditingController(
      text: invoice?.couponCode ?? '',
    );
    _shippingCostController = TextEditingController(
      text: invoice == null ? '0' : _compact(invoice.shippingCost),
    );
    _totalAmountController = TextEditingController(
      text: invoice == null ? '0' : _compact(invoice.totalAmount),
    );
    _paymentMethodController = TextEditingController(
      text: invoice?.paymentMethod ?? '',
    );
    _notesController = TextEditingController(text: invoice?.notes ?? '');
    _paymentStatus = invoice?.paymentStatus?.trim().isNotEmpty == true
        ? invoice!.paymentStatus!.trim()
        : 'Pending';
    _issueDate = invoice?.issueDate ?? DateTime.now();
    _dueDate = invoice?.dueDate ?? _issueDate;
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _orderIdController.dispose();
    _orderReferenceController.dispose();
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _billingAddressController.dispose();
    _subtotalController.dispose();
    _regularSubtotalController.dispose();
    _productDiscountTotalController.dispose();
    _subtotalAfterProductDiscountController.dispose();
    _taxController.dispose();
    _discountController.dispose();
    _couponDiscountController.dispose();
    _couponCodeController.dispose();
    _shippingCostController.dispose();
    _totalAmountController.dispose();
    _paymentMethodController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickIssueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        _issueDate = picked;
        _dueDate ??= picked;
      });
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? _issueDate ?? DateTime.now(),
      firstDate: _issueDate ?? DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final issueDate = _issueDate;
    final dueDate = _dueDate;
    if (issueDate == null || dueDate == null) {
      _showError('Select both issue and due dates.');
      return;
    }
    if (dueDate.isBefore(issueDate)) {
      _showError('Due date cannot be before the issue date.');
      return;
    }

    final orderId = _parseInt(_orderIdController.text);
    final input = AdminInvoiceInput(
      invoiceNumber: _invoiceNumberController.text,
      orderId: orderId,
      orderReference: _orderReferenceController.text,
      customerName: _customerNameController.text,
      customerEmail: _customerEmailController.text,
      customerPhone: _customerPhoneController.text,
      billingAddress: _billingAddressController.text,
      subtotal: _parseDouble(_subtotalController.text),
      regularSubtotal: _parseDouble(_regularSubtotalController.text),
      productDiscountTotal: _parseDouble(_productDiscountTotalController.text),
      subtotalAfterProductDiscount:
          _parseDouble(_subtotalAfterProductDiscountController.text),
      tax: _parseDouble(_taxController.text),
      discount: _parseDouble(_discountController.text),
      couponDiscount: _parseDouble(_couponDiscountController.text),
      couponCode: _couponCodeController.text,
      shippingCost: _parseDouble(_shippingCostController.text),
      totalAmount: _parseDouble(_totalAmountController.text),
      paymentStatus: _paymentStatus,
      paymentMethod: _paymentMethodController.text,
      issueDate: issueDate,
      dueDate: dueDate,
      notes: _notesController.text,
    );

    setState(() => _submitting = true);
    try {
      final service = context.read<AdminInvoiceService>();
      final token = context.read<AuthProvider>().token ?? '';
      if (widget.invoice?.id == null) {
        await service.createInvoice(token, input);
      } else {
        await service.updateInvoice(token, widget.invoice!.id!, input);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) _showError(error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final title = _editing ? 'Edit Invoice' : 'Create Invoice';
    return AdminShell(
      title: title,
      activeItem: 'Invoices',
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(title: title, editing: _editing),
                const SizedBox(height: 22),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _SectionCard(
                        title: 'Invoice basics',
                        subtitle: 'Identity, order linkage, and status',
                        child: _BasicSection(
                          invoiceNumberController: _invoiceNumberController,
                          orderIdController: _orderIdController,
                          orderReferenceController: _orderReferenceController,
                          paymentStatus: _paymentStatus,
                          issueDate: _issueDate,
                          dueDate: _dueDate,
                          onPaymentStatusChanged: (value) =>
                              setState(() => _paymentStatus = value),
                          onIssueDate: _pickIssueDate,
                          onDueDate: _pickDueDate,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionCard(
                        title: 'Customer information',
                        subtitle: 'Billing and contact details',
                        child: _CustomerSection(
                          customerNameController: _customerNameController,
                          customerEmailController: _customerEmailController,
                          customerPhoneController: _customerPhoneController,
                          billingAddressController: _billingAddressController,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionCard(
                        title: 'Totals and adjustments',
                        subtitle: 'Amounts captured on the invoice',
                        child: _TotalsSection(
                          subtotalController: _subtotalController,
                          regularSubtotalController: _regularSubtotalController,
                          productDiscountTotalController:
                              _productDiscountTotalController,
                          subtotalAfterProductDiscountController:
                              _subtotalAfterProductDiscountController,
                          taxController: _taxController,
                          discountController: _discountController,
                          couponDiscountController: _couponDiscountController,
                          couponCodeController: _couponCodeController,
                          shippingCostController: _shippingCostController,
                          totalAmountController: _totalAmountController,
                          paymentMethodController: _paymentMethodController,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionCard(
                        title: 'Notes',
                        subtitle: 'Optional administrative notes',
                        child: TextFormField(
                          controller: _notesController,
                          minLines: 4,
                          maxLines: 8,
                          maxLength: 2000,
                          decoration: const InputDecoration(
                            labelText: 'Invoice notes',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.notes_rounded),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            OutlinedButton(
                              onPressed: _submitting
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            FilledButton.icon(
                              onPressed: _submitting ? null : _submit,
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                _editing ? 'Save Changes' : 'Create Invoice',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int? _parseInt(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  double _parseDouble(String value) => double.tryParse(value.trim()) ?? 0;

  String _compact(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(2);
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.editing});

  final String title;
  final bool editing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton.filledTonal(
        tooltip: 'Back to invoices',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            Text(
              editing
                  ? 'Update invoice details and totals.'
                  : 'Create a new invoice record for the admin ledger.',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    ],
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => AdminSectionCard(
    title: title,
    subtitle: subtitle,
    child: child,
  );
}

class _BasicSection extends StatelessWidget {
  const _BasicSection({
    required this.invoiceNumberController,
    required this.orderIdController,
    required this.orderReferenceController,
    required this.paymentStatus,
    required this.issueDate,
    required this.dueDate,
    required this.onPaymentStatusChanged,
    required this.onIssueDate,
    required this.onDueDate,
  });

  final TextEditingController invoiceNumberController;
  final TextEditingController orderIdController;
  final TextEditingController orderReferenceController;
  final String paymentStatus;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final ValueChanged<String> onPaymentStatusChanged;
  final VoidCallback onIssueDate;
  final VoidCallback onDueDate;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 700;
      final width = wide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(
            width: width,
            child: TextFormField(
              controller: invoiceNumberController,
              decoration: const InputDecoration(
                labelText: 'Invoice number',
                prefixIcon: Icon(Icons.description_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                return text.isEmpty ? 'Enter an invoice number' : null;
              },
            ),
          ),
          SizedBox(
            width: width,
            child: TextFormField(
              controller: orderIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Order ID',
                prefixIcon: Icon(Icons.receipt_long_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            width: width,
            child: TextFormField(
              controller: orderReferenceController,
              decoration: const InputDecoration(
                labelText: 'Order reference',
                prefixIcon: Icon(Icons.tag_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            width: width,
            child: DropdownButtonFormField<String>(
              initialValue: paymentStatus,
              decoration: const InputDecoration(
                labelText: 'Payment status',
                prefixIcon: Icon(Icons.payments_outlined),
                border: OutlineInputBorder(),
              ),
              items: const ['Paid', 'Pending', 'Cancelled', 'Refunded']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) =>
                  onPaymentStatusChanged(value ?? 'Pending'),
            ),
          ),
          SizedBox(
            width: width,
            child: _DateField(
              label: 'Issue date',
              date: issueDate,
              icon: Icons.event_available_outlined,
              onTap: onIssueDate,
            ),
          ),
          SizedBox(
            width: width,
            child: _DateField(
              label: 'Due date',
              date: dueDate,
              icon: Icons.event_busy_outlined,
              onTap: onDueDate,
            ),
          ),
        ],
      );
    },
  );
}

class _CustomerSection extends StatelessWidget {
  const _CustomerSection({
    required this.customerNameController,
    required this.customerEmailController,
    required this.customerPhoneController,
    required this.billingAddressController,
  });

  final TextEditingController customerNameController;
  final TextEditingController customerEmailController;
  final TextEditingController customerPhoneController;
  final TextEditingController billingAddressController;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 700;
      final width = wide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(
            width: width,
            child: TextFormField(
              controller: customerNameController,
              decoration: const InputDecoration(
                labelText: 'Customer name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            width: width,
            child: TextFormField(
              controller: customerEmailController,
              decoration: const InputDecoration(
                labelText: 'Customer email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            width: width,
            child: TextFormField(
              controller: customerPhoneController,
              decoration: const InputDecoration(
                labelText: 'Customer phone',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            width: constraints.maxWidth,
            child: TextFormField(
              controller: billingAddressController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Billing address',
                prefixIcon: Icon(Icons.location_on_outlined),
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _TotalsSection extends StatelessWidget {
  const _TotalsSection({
    required this.subtotalController,
    required this.regularSubtotalController,
    required this.productDiscountTotalController,
    required this.subtotalAfterProductDiscountController,
    required this.taxController,
    required this.discountController,
    required this.couponDiscountController,
    required this.couponCodeController,
    required this.shippingCostController,
    required this.totalAmountController,
    required this.paymentMethodController,
  });

  final TextEditingController subtotalController;
  final TextEditingController regularSubtotalController;
  final TextEditingController productDiscountTotalController;
  final TextEditingController subtotalAfterProductDiscountController;
  final TextEditingController taxController;
  final TextEditingController discountController;
  final TextEditingController couponDiscountController;
  final TextEditingController couponCodeController;
  final TextEditingController shippingCostController;
  final TextEditingController totalAmountController;
  final TextEditingController paymentMethodController;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 700;
      final width = wide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(
            width: width,
            child: _moneyField(
              controller: subtotalController,
              label: 'Subtotal',
              icon: Icons.payments_outlined,
            ),
          ),
          SizedBox(
            width: width,
            child: _moneyField(
              controller: regularSubtotalController,
              label: 'Regular subtotal',
              icon: Icons.price_change_outlined,
            ),
          ),
          SizedBox(
            width: width,
            child: _moneyField(
              controller: productDiscountTotalController,
              label: 'Product discount total',
              icon: Icons.local_offer_outlined,
            ),
          ),
          SizedBox(
            width: width,
            child: _moneyField(
              controller: subtotalAfterProductDiscountController,
              label: 'Subtotal after product discount',
              icon: Icons.calculate_outlined,
            ),
          ),
          SizedBox(
            width: width,
            child: _moneyField(
              controller: taxController,
              label: 'Tax',
              icon: Icons.request_quote_outlined,
            ),
          ),
          SizedBox(
            width: width,
            child: _moneyField(
              controller: discountController,
              label: 'Discount',
              icon: Icons.discount_outlined,
            ),
          ),
          SizedBox(
            width: width,
            child: _moneyField(
              controller: couponDiscountController,
              label: 'Coupon discount',
              icon: Icons.redeem_outlined,
            ),
          ),
          SizedBox(
            width: width,
            child: _moneyField(
              controller: shippingCostController,
              label: 'Shipping charge',
              icon: Icons.local_shipping_outlined,
            ),
          ),
          SizedBox(
            width: width,
            child: _moneyField(
              controller: totalAmountController,
              label: 'Grand total',
              icon: Icons.summarize_outlined,
            ),
          ),
          SizedBox(
            width: width,
            child: TextFormField(
              controller: couponCodeController,
              decoration: const InputDecoration(
                labelText: 'Coupon code',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            width: width,
            child: TextFormField(
              controller: paymentMethodController,
              decoration: const InputDecoration(
                labelText: 'Payment method',
                prefixIcon: Icon(Icons.credit_card_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _moneyField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    ),
    validator: (value) {
      final parsed = double.tryParse(value?.trim() ?? '');
      return parsed == null || parsed < 0 ? 'Enter 0 or a positive number' : null;
    },
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      child: Text(date == null ? 'Select date' : adminInvoiceDate(date)),
    ),
  );
}
