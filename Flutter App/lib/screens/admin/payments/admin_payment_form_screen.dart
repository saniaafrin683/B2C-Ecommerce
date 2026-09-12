import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../services/admin/admin_payment_service.dart';
import '../../../widgets/admin/admin_section_card.dart';
import '../../../widgets/admin/admin_shell.dart';

class AdminPaymentFormScreen extends StatefulWidget {
  const AdminPaymentFormScreen({super.key, required this.payment});
  final AdminPayment payment;

  @override
  State<AdminPaymentFormScreen> createState() => _AdminPaymentFormScreenState();
}

class _AdminPaymentFormScreenState extends State<AdminPaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _transactionController;
  late final TextEditingController _notesController;
  late String _status;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _transactionController = TextEditingController(
      text: widget.payment.transactionId ?? '',
    );
    _notesController = TextEditingController(text: widget.payment.notes ?? '');
    final current = widget.payment.displayStatus;
    _status = const ['Paid', 'Pending', 'Failed', 'Refunded'].contains(current)
        ? current
        : 'Pending';
  }

  @override
  void dispose() {
    _transactionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || widget.payment.id == null) return;
    final input = widget.payment.toInput(
      status: _status,
      transactionId: _transactionController.text,
      notes: _notesController.text,
    );
    setState(() => _submitting = true);
    try {
      await context.read<AdminPaymentService>().updatePayment(
        context.read<AuthProvider>().token ?? '',
        widget.payment.id!,
        input,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) _error(error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _error(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), backgroundColor: const Color(0xFFB91C1C)),
      );
  }

  @override
  Widget build(BuildContext context) => AdminShell(
    title: 'Edit Payment',
    activeItem: 'Payments',
    child: SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Back to payment',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit ${widget.payment.displayId}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const Text(
                          'Update payment status and transaction metadata.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Form(
                key: _formKey,
                child: AdminSectionCard(
                  title: 'Payment update',
                  subtitle:
                      'Linked order, invoice, amount, method, and date remain unchanged',
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(
                          labelText: 'Payment status',
                          prefixIcon: Icon(Icons.payments_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const ['Paid', 'Pending', 'Failed', 'Refunded']
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _status = value ?? 'Pending'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _transactionController,
                        decoration: const InputDecoration(
                          labelText: 'Transaction ID',
                          prefixIcon: Icon(Icons.receipt_long_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => (value?.trim().isEmpty ?? true)
                            ? 'Transaction ID is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        minLines: 4,
                        maxLines: 8,
                        maxLength: 2000,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        alignment: WrapAlignment.end,
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
                            label: const Text('Save Changes'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
