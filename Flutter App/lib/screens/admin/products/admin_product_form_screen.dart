import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../models/product.dart';
import '../../../services/admin/admin_product_service.dart';
import '../../../widgets/admin/admin_shell.dart';
import '../../../widgets/product_image.dart';

class AdminProductFormScreen extends StatefulWidget {
  const AdminProductFormScreen({
    super.key,
    this.product,
    this.readOnly = false,
  });

  final Product? product;
  final bool readOnly;

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _discountController;
  late final TextEditingController _stockController;
  Future<List<String>>? _categories;
  String? _category;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _submitting = false;

  bool get _editing => widget.product != null;
  String get _title => widget.readOnly
      ? 'View Product'
      : _editing
      ? 'Edit Product'
      : 'Add Product';

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _brandController = TextEditingController(text: product?.brand ?? '');
    _descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    _priceController = TextEditingController(
      text: _initialNumber(product?.price),
    );
    _discountController = TextEditingController(
      text: _initialNumber(product?.discount ?? 0),
    );
    _stockController = TextEditingController(text: '${product?.stock ?? 0}');
    _category = product?.category;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _categories ??= context.read<AdminProductService>().getCategories(
      context.read<AuthProvider>().token ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'webp'],
      withData: true,
    );
    if (result == null || !mounted) return;
    final file = result.files.single;
    if (file.size > 5 * 1024 * 1024) {
      _showError('Image must be 5 MB or smaller.');
      return;
    }
    if (file.bytes == null) {
      _showError('Unable to read the selected image.');
      return;
    }
    setState(() {
      _imageBytes = file.bytes;
      _imageName = file.name;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _category == null) return;
    final price = double.parse(_priceController.text.trim());
    final discount = double.parse(_discountController.text.trim());
    final stock = int.parse(_stockController.text.trim());
    final existing = widget.product;
    final categoryChanged =
        existing?.category?.trim().toLowerCase() !=
        _category!.trim().toLowerCase();
    final input = AdminProductInput(
      name: _nameController.text.trim(),
      brand: _brandController.text.trim(),
      category: _category!.trim(),
      description: _descriptionController.text.trim(),
      price: price,
      discount: discount,
      stock: stock,
      imageUrl: existing?.imageUrl,
      imageBytes: _imageBytes,
      imageName: _imageName,
      subCategoryId: categoryChanged ? null : existing?.subCategoryId,
      subCategory: categoryChanged ? null : existing?.subCategory,
      weight: existing?.weight,
      gender: existing?.gender,
      tagNumber: existing?.tagNumber,
      tag: existing?.tag,
      tax: existing?.tax,
    );

    setState(() => _submitting = true);
    try {
      final service = context.read<AdminProductService>();
      final token = context.read<AuthProvider>().token ?? '';
      if (existing?.id == null) {
        await service.createProduct(token, input);
      } else {
        await service.updateProduct(token, existing!.id!, input);
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
    return AdminShell(
      title: _title,
      activeItem: 'Products',
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Back to products',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(
                            widget.readOnly
                                ? 'Product details'
                                : _editing
                                ? 'Update catalog information safely.'
                                : 'Create a new product in your catalog.',
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  padding: EdgeInsets.all(
                    MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE8ECF3)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 720;
                        final fields = _formFields();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Product information',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 20),
                            if (wide) ...[
                              _fieldRow(fields[0], fields[1]),
                              const SizedBox(height: 16),
                              _fieldRow(fields[2], fields[3]),
                              const SizedBox(height: 16),
                              _fieldRow(fields[4], fields[5]),
                            ] else
                              ...fields.expand(
                                (field) => [field, const SizedBox(height: 16)],
                              ),
                            const SizedBox(height: 2),
                            TextFormField(
                              controller: _descriptionController,
                              enabled: !widget.readOnly,
                              minLines: 4,
                              maxLines: 7,
                              decoration: _decoration(
                                'Description',
                                Icons.notes_rounded,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 18),
                            Text(
                              'Product image',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            _ImagePicker(
                              bytes: _imageBytes,
                              fileName: _imageName,
                              existingUrl:
                                  widget.product?.resolvedImageUrl ?? '',
                              readOnly: widget.readOnly,
                              onPick: _pickImage,
                              onRemove: () => setState(() {
                                _imageBytes = null;
                                _imageName = null;
                              }),
                            ),
                            const SizedBox(height: 26),
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                OutlinedButton(
                                  onPressed: _submitting
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  child: Text(
                                    widget.readOnly ? 'Close' : 'Cancel',
                                  ),
                                ),
                                if (!widget.readOnly) ...[
                                  FilledButton.icon(
                                    onPressed: _submitting ? null : _submit,
                                    icon: _submitting
                                        ? const SizedBox(
                                            width: 17,
                                            height: 17,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            _editing
                                                ? Icons.save_outlined
                                                : Icons.add_rounded,
                                          ),
                                    label: Text(
                                      _editing
                                          ? 'Save Changes'
                                          : 'Create Product',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _formFields() => [
    TextFormField(
      controller: _nameController,
      enabled: !widget.readOnly,
      decoration: _decoration('Product name', Icons.inventory_2_outlined),
      validator: (value) => (value?.trim().length ?? 0) < 2
          ? 'Enter at least 2 characters'
          : null,
    ),
    TextFormField(
      controller: _brandController,
      enabled: !widget.readOnly,
      decoration: _decoration('Brand', Icons.sell_outlined),
    ),
    FutureBuilder<List<String>>(
      future: _categories,
      builder: (context, snapshot) {
        final categories = {...?snapshot.data, ?_category}.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        return DropdownButtonFormField<String>(
          initialValue: _category,
          isExpanded: true,
          decoration: _decoration('Category', Icons.category_outlined).copyWith(
            suffixIcon: snapshot.connectionState == ConnectionState.waiting
                ? const Padding(
                    padding: EdgeInsets.all(13),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          items: categories
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: widget.readOnly
              ? null
              : (value) => setState(() => _category = value),
          validator: (value) => value == null ? 'Select a category' : null,
        );
      },
    ),
    TextFormField(
      controller: _stockController,
      enabled: !widget.readOnly,
      keyboardType: TextInputType.number,
      decoration: _decoration('Stock quantity', Icons.warehouse_outlined),
      validator: (value) {
        final number = int.tryParse(value?.trim() ?? '');
        return number == null || number < 0 ? 'Enter a valid quantity' : null;
      },
    ),
    TextFormField(
      controller: _priceController,
      enabled: !widget.readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _decoration('Price (৳)', Icons.payments_outlined),
      validator: (value) {
        final number = double.tryParse(value?.trim() ?? '');
        return number == null || number < 0 ? 'Enter a valid price' : null;
      },
    ),
    TextFormField(
      controller: _discountController,
      enabled: !widget.readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _decoration('Discount (%)', Icons.percent_rounded),
      validator: (value) {
        final number = double.tryParse(value?.trim() ?? '');
        return number == null || number < 0 || number > 100
            ? 'Enter a value from 0 to 100'
            : null;
      },
    ),
  ];

  Widget _fieldRow(Widget first, Widget second) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: first),
      const SizedBox(width: 16),
      Expanded(child: second),
    ],
  );

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: const OutlineInputBorder(),
  );

  static String _initialNumber(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? '${value.toInt()}'
        : value.toStringAsFixed(2);
  }
}

class _ImagePicker extends StatelessWidget {
  const _ImagePicker({
    required this.bytes,
    required this.fileName,
    required this.existingUrl,
    required this.readOnly,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? bytes;
  final String? fileName;
  final String existingUrl;
  final bool readOnly;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 18,
    runSpacing: 14,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      SizedBox(
        width: 150,
        height: 150,
        child: bytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(bytes!, fit: BoxFit.cover),
              )
            : ProductImage(
                imageUrl: existingUrl,
                borderRadius: BorderRadius.circular(14),
              ),
      ),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fileName ??
                  (existingUrl.isEmpty
                      ? 'No image selected'
                      : 'Current product image'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'JPG, PNG, GIF, or WEBP. Maximum size 5 MB.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            if (!readOnly) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.upload_outlined),
                    label: Text(bytes == null ? 'Choose Image' : 'Replace'),
                  ),
                  if (bytes != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Discard selected image',
                      onPressed: onRemove,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    ],
  );
}
