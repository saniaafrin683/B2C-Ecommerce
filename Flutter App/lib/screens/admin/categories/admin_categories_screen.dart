import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api_client.dart';
import '../../../core/api_exception.dart';
import '../../../core/auth_provider.dart';
import '../../../models/category.dart';
import '../../../services/admin/admin_category_service.dart';
import '../../../widgets/admin/admin_shell.dart';
import '../../../widgets/category_image.dart';
import 'admin_category_form_screen.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  static const routeName = '/admin/categories';

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final _searchController = TextEditingController();
  Future<List<Category>>? _request;
  final Set<int> _deletingIds = {};

  String get _token => context.read<AuthProvider>().token ?? '';
  AdminCategoryService get _service => context.read<AdminCategoryService>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request ??= _service.getCategories(_token);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final request = _service.getCategories(_token);
    setState(() {
      _request = request;
    });
    await request;
  }

  List<Category> _filtered(List<Category> categories) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return categories;
    return categories
        .where(
          (category) =>
              category.categoryTitle?.toLowerCase().contains(query) == true,
        )
        .toList();
  }

  Future<void> _openForm({Category? category}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminCategoryFormScreen(category: category),
      ),
    );
    if (changed == true && mounted) {
      await _refresh();
      if (mounted) {
        _showMessage(
          category == null
              ? 'Category created successfully.'
              : 'Category updated successfully.',
        );
      }
    }
  }

  Future<void> _delete(Category category) async {
    final id = category.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          'Delete “${category.categoryTitle ?? 'this category'}”? Categories used by products or subcategories cannot be deleted.',
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

    setState(() => _deletingIds.add(id));
    try {
      await _service.deleteCategory(_token, id);
      if (!mounted) return;
      _showMessage('Category deleted successfully.');
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException && error.statusCode == 409
          ? 'This category cannot be deleted because products or subcategories are using it.'
          : error.toString();
      _showMessage(message, error: true);
    } finally {
      if (mounted) setState(() => _deletingIds.remove(id));
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? const Color(0xFFB91C1C) : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Categories',
      activeItem: 'Categories',
      child: FutureBuilder<List<Category>>(
        future: _request,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _CategoryError(error: snapshot.error, onRetry: _refresh);
          }
          final allCategories = snapshot.data ?? const [];
          final categories = _filtered(allCategories);
          return RefreshIndicator(
            onRefresh: _refresh,
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
                      _CategoryHeader(
                        count: allCategories.length,
                        onAdd: () => _openForm(),
                      ),
                      const SizedBox(height: 22),
                      _CategorySearch(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 18),
                      if (categories.isEmpty)
                        const _EmptyCategories()
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth >= 760) {
                              return _CategoryTable(
                                categories: categories,
                                deletingIds: _deletingIds,
                                onEdit: (category) =>
                                    _openForm(category: category),
                                onDelete: _delete,
                              );
                            }
                            return _CategoryCards(
                              categories: categories,
                              deletingIds: _deletingIds,
                              onEdit: (category) =>
                                  _openForm(category: category),
                              onDelete: _delete,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.count, required this.onAdd});
  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Management',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 5),
        Text(
          '$count categories in your catalog',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
      ],
    );
    final action = FilledButton.icon(
      onPressed: onAdd,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add Category'),
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 520
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [heading, const SizedBox(height: 12), action],
            )
          : Row(
              children: [
                Expanded(child: heading),
                const SizedBox(width: 12),
                action,
              ],
            ),
    );
  }
}

class _CategorySearch extends StatelessWidget {
  const _CategorySearch({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8ECF3)),
    ),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          labelText: 'Search categories',
          hintText: 'Search by category name',
          prefixIcon: Icon(Icons.search_rounded),
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
    ),
  );
}

class _CategoryTable extends StatelessWidget {
  const _CategoryTable({
    required this.categories,
    required this.deletingIds,
    required this.onEdit,
    required this.onDelete,
  });
  final List<Category> categories;
  final Set<int> deletingIds;
  final ValueChanged<Category> onEdit;
  final ValueChanged<Category> onDelete;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8ECF3)),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          horizontalMargin: 20,
          columnSpacing: 34,
          columns: const [
            DataColumn(label: Text('CATEGORY')),
            DataColumn(label: Text('DESCRIPTION')),
            DataColumn(label: Text('PRODUCT COUNT')),
            DataColumn(label: Text('ACTIONS')),
          ],
          rows: categories
              .map(
                (category) => DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 250,
                        child: _CategoryIdentity(category: category),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 360,
                        child: Text(
                          category.description ?? '—',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                    ),
                    const DataCell(Text('—')),
                    DataCell(
                      _CategoryActions(
                        category: category,
                        deleting: deletingIds.contains(category.id),
                        onEdit: onEdit,
                        onDelete: onDelete,
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    ),
  );
}

class _CategoryCards extends StatelessWidget {
  const _CategoryCards({
    required this.categories,
    required this.deletingIds,
    required this.onEdit,
    required this.onDelete,
  });
  final List<Category> categories;
  final Set<int> deletingIds;
  final ValueChanged<Category> onEdit;
  final ValueChanged<Category> onDelete;

  @override
  Widget build(BuildContext context) => Column(
    children: categories
        .map(
          (category) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8ECF3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CategoryIdentity(category: category),
                if (category.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    category.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
                const Divider(height: 26),
                Row(
                  children: [
                    const Text(
                      'Products: —',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                    const Spacer(),
                    _CategoryActions(
                      category: category,
                      deleting: deletingIds.contains(category.id),
                      onEdit: onEdit,
                      onDelete: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
        .toList(),
  );
}

class _CategoryIdentity extends StatelessWidget {
  const _CategoryIdentity({required this.category});
  final Category category;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 54,
        height: 54,
        child: CategoryImage(
          imageUrl: _resolvedCategoryImage(context, category.imageUrl),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Text(
          category.categoryTitle ?? 'Unnamed category',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

String _resolvedCategoryImage(BuildContext context, String? imageUrl) {
  final value = imageUrl?.trim() ?? '';
  if (value.toLowerCase().startsWith('data:image/')) {
    return value;
  }
  return context.read<ApiClient>().normalizeImageUrl(value);
}

class _CategoryActions extends StatelessWidget {
  const _CategoryActions({
    required this.category,
    required this.deleting,
    required this.onEdit,
    required this.onDelete,
  });
  final Category category;
  final bool deleting;
  final ValueChanged<Category> onEdit;
  final ValueChanged<Category> onDelete;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'Edit',
        visualDensity: VisualDensity.compact,
        onPressed: () => onEdit(category),
        icon: const Icon(
          Icons.edit_outlined,
          size: 20,
          color: Color(0xFF2563EB),
        ),
      ),
      if (deleting)
        const Padding(
          padding: EdgeInsets.all(9),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )
      else
        IconButton(
          tooltip: 'Delete',
          visualDensity: VisualDensity.compact,
          onPressed: () => onDelete(category),
          icon: const Icon(
            Icons.delete_outline_rounded,
            size: 20,
            color: Color(0xFFDC2626),
          ),
        ),
    ],
  );
}

class _EmptyCategories extends StatelessWidget {
  const _EmptyCategories();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8ECF3)),
    ),
    child: const Column(
      children: [
        Icon(Icons.category_outlined, size: 52, color: Color(0xFF94A3B8)),
        SizedBox(height: 14),
        Text(
          'No categories found',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 5),
        Text(
          'Try changing your search or add a category.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      ],
    ),
  );
}

class _CategoryError extends StatelessWidget {
  const _CategoryError({required this.error, required this.onRetry});
  final Object? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: Color(0xFF64748B),
          ),
          const SizedBox(height: 12),
          const Text(
            'Unable to load categories.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
