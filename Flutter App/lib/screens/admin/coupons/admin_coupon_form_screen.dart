import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../services/admin/admin_coupon_service.dart';
import '../../../widgets/admin/admin_section_card.dart';
import '../../../widgets/admin/admin_shell.dart';

class AdminCouponFormScreen extends StatefulWidget {
  const AdminCouponFormScreen({super.key, this.coupon});

  final AdminCoupon? coupon;

  @override
  State<AdminCouponFormScreen> createState() => _AdminCouponFormScreenState();
}

class _AdminCouponFormScreenState extends State<AdminCouponFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _valueController;
  late final TextEditingController _minimumController;
  late final TextEditingController _usageLimitController;
  late final TextEditingController _descriptionController;
  late String _discountType;
  late String _status;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;

  bool get _editing => widget.coupon != null;

  @override
  void initState() {
    super.initState();
    final coupon = widget.coupon;
    _codeController = TextEditingController(text: coupon?.code ?? '');
    _valueController = TextEditingController(
      text: coupon == null ? '' : _compact(coupon.discountValue),
    );
    _minimumController = TextEditingController(
      text: coupon == null ? '0' : _compact(coupon.minimumOrderAmount),
    );
    _usageLimitController = TextEditingController(
      text: coupon == null ? '0' : '${coupon.usageLimit}',
    );
    _descriptionController = TextEditingController(
      text: coupon?.description ?? '',
    );
    _discountType = coupon?.displayDiscountType ?? 'Percentage';
    _status = coupon?.status?.toLowerCase() == 'inactive'
        ? 'Inactive'
        : 'Active';
    _startDate = coupon?.startDate;
    _endDate = coupon?.endDate;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _valueController.dispose();
    _minimumController.dispose();
    _usageLimitController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _endDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      _showError('Select both start and expiry dates.');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      _showError('Expiry date cannot be before the start date.');
      return;
    }

    final discountValue = double.parse(_valueController.text.trim());
    if (_discountType == 'Percentage' && discountValue > 100) {
      _showError('Percentage discount cannot exceed 100%.');
      return;
    }
    final input = AdminCouponInput(
      code: _codeController.text,
      discountType: _discountType,
      discountValue: discountValue,
      minimumOrderAmount: double.parse(_minimumController.text.trim()),
      startDate: _startDate!,
      endDate: _endDate!,
      usageLimit: int.parse(_usageLimitController.text.trim()),
      usedCount: widget.coupon?.usedCount ?? 0,
      status: _status,
      description: _descriptionController.text,
    );

    setState(() => _submitting = true);
    try {
      final service = context.read<AdminCouponService>();
      final token = context.read<AuthProvider>().token ?? '';
      if (widget.coupon?.id == null) {
        await service.createCoupon(token, input);
      } else {
        await service.updateCoupon(token, widget.coupon!.id!, input);
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
    final title = _editing ? 'Edit Coupon' : 'Create Coupon';
    return AdminShell(
      title: title,
      activeItem: 'Coupons',
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(title: title, editing: _editing),
                const SizedBox(height: 22),
                Form(
                  key: _formKey,
                  child: AdminSectionCard(
                    title: 'Coupon configuration',
                    subtitle: 'Define eligibility, dates, usage, and discount',
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 700;
                        final width = wide
                            ? (constraints.maxWidth - 16) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: width,
                              child: TextFormField(
                                controller: _codeController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  labelText: 'Coupon code',
                                  prefixIcon: Icon(
                                    Icons.confirmation_number_outlined,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  final code = value?.trim() ?? '';
                                  if (code.length < 3) {
                                    return 'Enter at least 3 characters';
                                  }
                                  if (!RegExp(
                                    r'^[A-Za-z0-9_-]+$',
                                  ).hasMatch(code)) {
                                    return 'Use letters, numbers, hyphens, or underscores';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: DropdownButtonFormField<String>(
                                initialValue: _discountType,
                                decoration: const InputDecoration(
                                  labelText: 'Discount type',
                                  prefixIcon: Icon(Icons.percent_rounded),
                                  border: OutlineInputBorder(),
                                ),
                                items: const ['Percentage', 'Flat']
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(value),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) => setState(
                                  () => _discountType = value ?? 'Percentage',
                                ),
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: TextFormField(
                                controller: _valueController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText: 'Discount value',
                                  prefixIcon: Icon(
                                    _discountType == 'Percentage'
                                        ? Icons.percent_rounded
                                        : Icons.payments_outlined,
                                  ),
                                  border: const OutlineInputBorder(),
                                ),
                                validator: _positiveNumber,
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: TextFormField(
                                controller: _minimumController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Minimum order amount',
                                  prefixIcon: Icon(
                                    Icons.shopping_cart_checkout_rounded,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                validator: _nonNegativeNumber,
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: _DateField(
                                label: 'Start date',
                                date: _startDate,
                                icon: Icons.event_available_outlined,
                                onTap: _pickStartDate,
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: _DateField(
                                label: 'Expiry date',
                                date: _endDate,
                                icon: Icons.event_busy_outlined,
                                onTap: _pickEndDate,
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: TextFormField(
                                controller: _usageLimitController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Usage limit',
                                  helperText: 'Use 0 for unlimited usage',
                                  prefixIcon: Icon(Icons.data_usage_rounded),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  final parsed = int.tryParse(
                                    value?.trim() ?? '',
                                  );
                                  return parsed == null || parsed < 0
                                      ? 'Enter 0 or a positive whole number'
                                      : null;
                                },
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: DropdownButtonFormField<String>(
                                initialValue: _status,
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                  prefixIcon: Icon(Icons.toggle_on_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                items: const ['Active', 'Inactive']
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(value),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _status = value ?? 'Active'),
                              ),
                            ),
                            SizedBox(
                              width: constraints.maxWidth,
                              child: TextFormField(
                                controller: _descriptionController,
                                minLines: 3,
                                maxLines: 6,
                                maxLength: 2000,
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                  alignLabelWithHint: true,
                                  prefixIcon: Icon(Icons.notes_rounded),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: constraints.maxWidth,
                              child: Wrap(
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
                                    label: Text(
                                      _editing
                                          ? 'Save Changes'
                                          : 'Create Coupon',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
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

  String? _positiveNumber(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    return parsed == null || parsed <= 0
        ? 'Enter a number greater than 0'
        : null;
  }

  String? _nonNegativeNumber(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    return parsed == null || parsed < 0 ? 'Enter 0 or a positive number' : null;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.editing});
  final String title;
  final bool editing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton.filledTonal(
        tooltip: 'Back to coupons',
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
                  ? 'Update campaign rules and availability.'
                  : 'Create a new promotion for StyleOra customers.',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    ],
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
      child: Text(date == null ? 'Select date' : _formatDate(date!)),
    ),
  );
}

String _formatDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

String _compact(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);
