import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api_client.dart';
import '../../../core/auth_provider.dart';
import '../../../models/category.dart';
import '../../../services/admin/admin_category_service.dart';
import '../../../widgets/admin/admin_shell.dart';
import '../../../widgets/category_image.dart';

class AdminCategoryFormScreen extends StatefulWidget {
  const AdminCategoryFormScreen({super.key, this.category});

  final Category? category;

  @override
  State<AdminCategoryFormScreen> createState() =>
      _AdminCategoryFormScreenState();
}

class _AdminCategoryFormScreenState extends State<AdminCategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _submitting = false;

  bool get _editing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.category?.categoryTitle ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.category?.description ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.category?.imageUrl ?? '',
    )..addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _imageUrlController.removeListener(_refreshPreview);
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
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
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.category;
    final auth = context.read<AuthProvider>();
    final input = AdminCategoryInput(
      name: _nameController.text,
      description: _descriptionController.text,
      imageUrl: _imageUrlController.text,
      imageBytes: _imageBytes,
      imageName: _imageName,
      createdBy: existing?.createdBy ?? auth.customer?.email,
      stock: existing?.stock,
      tagId: existing?.tagId,
    );

    setState(() => _submitting = true);
    try {
      final service = context.read<AdminCategoryService>();
      final token = auth.token ?? '';
      if (existing?.id == null) {
        await service.createCategory(token, input);
      } else {
        await service.updateCategory(token, existing!.id!, input);
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
    final title = _editing ? 'Edit Category' : 'Add Category';
    final enteredImageUrl = _imageUrlController.text.trim();
    final imageUrl = enteredImageUrl.toLowerCase().startsWith('data:image/')
        ? enteredImageUrl
        : context.read<ApiClient>().normalizeImageUrl(enteredImageUrl);
    return AdminShell(
      title: title,
      activeItem: 'Categories',
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Back to categories',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(
                            _editing
                                ? 'Update category information safely.'
                                : 'Create a new catalog category.',
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
                        final wide = constraints.maxWidth >= 650;
                        final form = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category information',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Category name',
                                prefixIcon: Icon(Icons.category_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  (value?.trim().length ?? 0) < 2
                                  ? 'Enter at least 2 characters'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              minLines: 4,
                              maxLines: 7,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                alignLabelWithHint: true,
                                prefixIcon: Icon(Icons.notes_rounded),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _imageUrlController,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                labelText: 'Image URL',
                                hintText: '/uploads/... or https://...',
                                prefixIcon: Icon(Icons.link_rounded),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Upload JPG, PNG, GIF, or WEBP up to 5 MB, or provide a web image URL.',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.upload_outlined),
                                  label: Text(
                                    _imageBytes == null
                                        ? 'Choose Image'
                                        : 'Replace Image',
                                  ),
                                ),
                                if (_imageName != null)
                                  Text(
                                    _imageName!,
                                    style: const TextStyle(
                                      color: Color(0xFF475569),
                                      fontSize: 12,
                                    ),
                                  ),
                                if (_imageBytes != null)
                                  IconButton(
                                    tooltip: 'Discard selected image',
                                    onPressed: () => setState(() {
                                      _imageBytes = null;
                                      _imageName = null;
                                    }),
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                              ],
                            ),
                          ],
                        );
                        final preview = _CategoryImagePreview(
                          imageUrl: imageUrl,
                          imageBytes: _imageBytes,
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (wide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 3, child: form),
                                  const SizedBox(width: 24),
                                  SizedBox(width: 210, child: preview),
                                ],
                              )
                            else ...[
                              form,
                              const SizedBox(height: 22),
                              preview,
                            ],
                            const SizedBox(height: 28),
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
                                        : 'Create Category',
                                  ),
                                ),
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
}

class _CategoryImagePreview extends StatelessWidget {
  const _CategoryImagePreview({required this.imageUrl, this.imageBytes});
  final String imageUrl;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Preview', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 10),
      SizedBox(
        width: 210,
        height: 180,
        child: CategoryImage(
          imageUrl: imageUrl,
          imageBytes: imageBytes,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ],
  );
}
