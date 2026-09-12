import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api_client.dart';
import '../../../core/auth_provider.dart';
import '../../../models/product.dart';
import '../../../services/admin/admin_product_service.dart';
import '../../../widgets/admin/admin_shell.dart';
import '../../../widgets/product_image.dart';
import 'admin_product_form_screen.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  static const routeName = '/admin/products';

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _searchController = TextEditingController();
  Future<_ProductListData>? _request;
  String _category = 'All';
  _StockFilter _stockFilter = _StockFilter.all;
  final Set<int> _deletingIds = {};

  String get _token => context.read<AuthProvider>().token ?? '';
  AdminProductService get _service => context.read<AdminProductService>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request ??= _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_ProductListData> _load() async {
    final results = await Future.wait([
      _service.getProducts(_token),
      _service.getCategories(_token),
    ]);
    final products = results[0] as List<Product>;
    final categories = (results[1] as List<String>).toSet()
      ..addAll(
        products
            .map((product) => product.category?.trim())
            .whereType<String>()
            .where((value) => value.isNotEmpty),
      );
    final sortedCategories = categories.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return _ProductListData(products, sortedCategories);
  }

  Future<void> _refresh() async {
    final request = _load();
    setState(() {
      _request = request;
    });
    await request;
  }

  List<Product> _filtered(List<Product> products) {
    final query = _searchController.text.trim().toLowerCase();
    return products.where((product) {
      final matchesSearch =
          query.isEmpty ||
          [product.name, product.brand, product.category]
              .whereType<String>()
              .any((value) => value.toLowerCase().contains(query));
      final matchesCategory =
          _category == 'All' ||
          product.category?.toLowerCase() == _category.toLowerCase();
      final stock = product.stock ?? 0;
      final matchesStock = switch (_stockFilter) {
        _StockFilter.all => true,
        _StockFilter.inStock => stock >= 10,
        _StockFilter.lowStock => stock > 0 && stock < 10,
        _StockFilter.outOfStock => stock <= 0,
      };
      return matchesSearch && matchesCategory && matchesStock;
    }).toList();
  }

  Future<void> _openForm({Product? product, bool readOnly = false}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            AdminProductFormScreen(product: product, readOnly: readOnly),
      ),
    );
    if (changed == true && mounted) {
      await _refresh();
      if (mounted) {
        _showMessage(
          product == null
              ? 'Product created successfully.'
              : 'Product updated successfully.',
        );
      }
    }
  }

  Future<void> _delete(Product product) async {
    final id = product.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text(
          'Delete “${product.name ?? 'this product'}”? This action cannot be undone.',
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
      await _service.deleteProduct(_token, id);
      if (!mounted) return;
      _showMessage('Product deleted successfully.');
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(error.toString(), error: true);
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
      title: 'Products',
      activeItem: 'Products',
      child: FutureBuilder<_ProductListData>(
        future: _request,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ProductError(error: snapshot.error, onRetry: _refresh);
          }

          final data = snapshot.data ?? const _ProductListData([], []);
          final products = _filtered(data.products);
          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(
                MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PageHeader(
                        total: data.products.length,
                        onAdd: () => _openForm(),
                      ),
                      const SizedBox(height: 22),
                      _Filters(
                        controller: _searchController,
                        categories: data.categories,
                        category: _category,
                        stockFilter: _stockFilter,
                        onSearch: (_) => setState(() {}),
                        onCategory: (value) =>
                            setState(() => _category = value),
                        onStock: (value) =>
                            setState(() => _stockFilter = value),
                      ),
                      const SizedBox(height: 18),
                      if (products.isEmpty)
                        const _EmptyProducts()
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth >= 820) {
                              return _ProductTable(
                                products: products,
                                deletingIds: _deletingIds,
                                onView: (product) =>
                                    _openForm(product: product, readOnly: true),
                                onEdit: (product) =>
                                    _openForm(product: product),
                                onDelete: _delete,
                              );
                            }
                            return _ProductCards(
                              products: products,
                              deletingIds: _deletingIds,
                              onView: (product) =>
                                  _openForm(product: product, readOnly: true),
                              onEdit: (product) => _openForm(product: product),
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

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.total, required this.onAdd});
  final int total;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Management',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 5),
        Text(
          '$total products in your catalog',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
      ],
    );
    final action = FilledButton.icon(
      onPressed: onAdd,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add Product'),
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

class _Filters extends StatelessWidget {
  const _Filters({
    required this.controller,
    required this.categories,
    required this.category,
    required this.stockFilter,
    required this.onSearch,
    required this.onCategory,
    required this.onStock,
  });

  final TextEditingController controller;
  final List<String> categories;
  final String category;
  final _StockFilter stockFilter;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onCategory;
  final ValueChanged<_StockFilter> onStock;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8ECF3)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _searchField(),
              const SizedBox(height: 12),
              _categoryField(),
              const SizedBox(height: 12),
              _stockField(),
            ],
          );
        }

        return Row(
          key: const ValueKey('active-admin-products-filter-row'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _searchField()),
            const SizedBox(width: 16),
            SizedBox(width: 220, child: _categoryField()),
            const SizedBox(width: 16),
            SizedBox(width: 220, child: _stockField()),
          ],
        );
      },
    ),
  );

  Widget _searchField() => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 52),
    child: TextField(
      controller: controller,
      onChanged: onSearch,
      decoration: const InputDecoration(
        labelText: 'Search products',
        hintText: 'Name, brand, or category',
        prefixIcon: Icon(Icons.search_rounded),
        border: OutlineInputBorder(),
        isDense: true,
      ),
    ),
  );

  Widget _categoryField() => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 52),
    child: DropdownButtonFormField<String>(
      initialValue: category,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: ['All', ...categories]
          .map(
            (value) => DropdownMenuItem(
              value: value,
              child: Text(value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (value) => value == null ? null : onCategory(value),
    ),
  );

  Widget _stockField() => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 52),
    child: DropdownButtonFormField<_StockFilter>(
      initialValue: stockFilter,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Stock status',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: _StockFilter.values
          .map(
            (value) => DropdownMenuItem(value: value, child: Text(value.label)),
          )
          .toList(),
      onChanged: (value) => value == null ? null : onStock(value),
    ),
  );
}

class _ProductTable extends StatelessWidget {
  const _ProductTable({
    required this.products,
    required this.deletingIds,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });
  final List<Product> products;
  final Set<int> deletingIds;
  final ValueChanged<Product> onView;
  final ValueChanged<Product> onEdit;
  final ValueChanged<Product> onDelete;

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
          horizontalMargin: 18,
          columnSpacing: 28,
          columns: const [
            DataColumn(label: Text('PRODUCT')),
            DataColumn(label: Text('BRAND')),
            DataColumn(label: Text('CATEGORY')),
            DataColumn(label: Text('PRICE')),
            DataColumn(label: Text('STOCK')),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('ACTIONS')),
          ],
          rows: products
              .map(
                (product) => DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 230,
                        child: _ProductIdentity(product: product),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: Text(
                          product.brand ?? '—',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 110,
                        child: Text(
                          product.category ?? '—',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(_Price(product: product)),
                    DataCell(Text('${product.stock ?? 0}')),
                    DataCell(_StockBadge(stock: product.stock ?? 0)),
                    DataCell(
                      _Actions(
                        product: product,
                        deleting: deletingIds.contains(product.id),
                        onView: onView,
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

class _ProductCards extends StatelessWidget {
  const _ProductCards({
    required this.products,
    required this.deletingIds,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });
  final List<Product> products;
  final Set<int> deletingIds;
  final ValueChanged<Product> onView;
  final ValueChanged<Product> onEdit;
  final ValueChanged<Product> onDelete;

  @override
  Widget build(BuildContext context) => Column(
    children: products
        .map(
          (product) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8ECF3)),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: ProductImage(
                        imageUrl: context.read<ApiClient>().normalizeImageUrl(
                          product.imageUrl,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name ?? 'Unnamed product',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            [
                              product.brand,
                              product.category,
                            ].whereType<String>().join(' • '),
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _Price(product: product),
                              const Spacer(),
                              _StockBadge(stock: product.stock ?? 0),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Text(
                      '${product.stock ?? 0} units',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    const Spacer(),
                    _Actions(
                      product: product,
                      deleting: deletingIds.contains(product.id),
                      onView: onView,
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

class _ProductIdentity extends StatelessWidget {
  const _ProductIdentity({required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 48,
        height: 48,
        child: ProductImage(
          imageUrl: context.read<ApiClient>().normalizeImageUrl(
            product.imageUrl,
          ),
          borderRadius: BorderRadius.circular(9),
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Text(
          product.name ?? 'Unnamed product',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

class _Price extends StatelessWidget {
  const _Price({required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) {
    final discounted = (product.discount ?? 0) > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _money(product.effectivePrice),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (discounted)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _money(product.price ?? 0),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '-${_number(product.discount ?? 0)}%',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFB91C1C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.stock});
  final int stock;
  @override
  Widget build(BuildContext context) {
    final (label, color) = stock <= 0
        ? ('Out of Stock', const Color(0xFFDC2626))
        : stock < 10
        ? ('Low Stock', const Color(0xFFD97706))
        : ('In Stock', const Color(0xFF059669));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.product,
    required this.deleting,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });
  final Product product;
  final bool deleting;
  final ValueChanged<Product> onView;
  final ValueChanged<Product> onEdit;
  final ValueChanged<Product> onDelete;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'View',
        visualDensity: VisualDensity.compact,
        onPressed: () => onView(product),
        icon: const Icon(Icons.visibility_outlined, size: 19),
      ),
      IconButton(
        tooltip: 'Edit',
        visualDensity: VisualDensity.compact,
        onPressed: () => onEdit(product),
        icon: const Icon(
          Icons.edit_outlined,
          size: 19,
          color: Color(0xFF2563EB),
        ),
      ),
      deleting
          ? const Padding(
              padding: EdgeInsets.all(9),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : IconButton(
              tooltip: 'Delete',
              visualDensity: VisualDensity.compact,
              onPressed: () => onDelete(product),
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 19,
                color: Color(0xFFDC2626),
              ),
            ),
    ],
  );
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();
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
        Icon(Icons.inventory_2_outlined, size: 52, color: Color(0xFF94A3B8)),
        SizedBox(height: 14),
        Text(
          'No products found',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 5),
        Text(
          'Try changing your search or filters.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      ],
    ),
  );
}

class _ProductError extends StatelessWidget {
  const _ProductError({required this.error, required this.onRetry});
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
            'Unable to load products.',
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

enum _StockFilter {
  all('All'),
  inStock('In Stock'),
  lowStock('Low Stock'),
  outOfStock('Out of Stock');

  const _StockFilter(this.label);
  final String label;
}

class _ProductListData {
  const _ProductListData(this.products, this.categories);
  final List<Product> products;
  final List<String> categories;
}

String _money(double value) => '৳${value.toStringAsFixed(2)}';
String _number(double value) => value == value.roundToDouble()
    ? '${value.toInt()}'
    : value.toStringAsFixed(1);
