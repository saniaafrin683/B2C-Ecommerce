import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/product_page_response.dart';
import '../../services/catalog_service.dart';
import '../../widgets/product_card.dart';
import '../shop/product_details_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, this.initialQuery, this.initialCategory});

  final String? initialQuery;
  final String? initialCategory;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late final TextEditingController _queryController;
  late Future<ProductPageResponse> _future;
  String? _activeQuery;
  String? _activeCategory;
  int _page = 0;
  final int _size = 12;

  CatalogService get _catalogService => context.read<CatalogService>();

  @override
  void initState() {
    super.initState();
    _activeQuery = widget.initialQuery?.trim();
    _activeCategory = widget.initialCategory?.trim();
    _queryController = TextEditingController(text: _activeQuery ?? '');
    _future = _loadProducts();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<ProductPageResponse> _loadProducts() {
    final query = _activeQuery;
    final category = _activeCategory;
    if (query != null && query.isNotEmpty) {
      return _catalogService.searchProducts(
        query: query,
        category: category,
        page: _page,
        size: _size,
        sortBy: 'id',
        sortDir: 'desc',
      );
    }

    if (category != null && category.isNotEmpty) {
      return _catalogService.searchByCategory(
        category: category,
        page: _page,
        size: _size,
        sortBy: 'id',
        sortDir: 'desc',
      );
    }

    return _catalogService.getProductsPage(
      page: _page,
      size: _size,
      sortBy: 'id',
      sortDir: 'desc',
    );
  }

  void _submitSearch([String? value]) {
    setState(() {
      _page = 0;
      final trimmed = (value ?? _queryController.text).trim();
      _activeQuery = trimmed.isEmpty ? null : trimmed;
      _future = _loadProducts();
    });
  }

  void _retry() {
    setState(() {
      _future = _loadProducts();
    });
  }

  void _loadNextPage(ProductPageResponse response) {
    if (_page + 1 >= response.totalPages) {
      return;
    }
    setState(() {
      _page += 1;
      _future = _loadProducts();
    });
  }

  void _loadPreviousPage() {
    if (_page <= 0) {
      return;
    }
    setState(() {
      _page -= 1;
      _future = _loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            _SearchBar(controller: _queryController, onSearch: _submitSearch),
            if (_activeCategory != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text('Category: $_activeCategory'),
                  onDeleted: () {
                    setState(() {
                      _activeCategory = null;
                      _future = _loadProducts();
                    });
                  },
                ),
              ),
            ],
            const SizedBox(height: 14),
            Expanded(
              child: FutureBuilder<ProductPageResponse>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _LoadingState();
                  }

                  if (snapshot.hasError) {
                    return _ErrorState(
                      message: _errorMessage(snapshot.error),
                      onRetry: _retry,
                    );
                  }

                  final response = snapshot.data;
                  final products = response?.content ?? const [];
                  if (products.isEmpty) {
                    return _EmptyState(
                      title: _activeQuery == null && _activeCategory == null
                          ? 'No products yet'
                          : 'No matches found',
                      message: _activeQuery == null && _activeCategory == null
                          ? 'The catalog is currently empty.'
                          : 'Try a different keyword or clear the search.',
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth >= 1200
                                ? 5
                                : constraints.maxWidth >= 900
                                ? 4
                                : constraints.maxWidth >= 640
                                ? 3
                                : 2;
                            final childAspectRatio = constraints.maxWidth >= 900
                                ? 0.68
                                : constraints.maxWidth >= 640
                                ? 0.64
                                : 0.58;

                            return GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: products.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: childAspectRatio,
                                  ),
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return ProductCard(
                                  product: product,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailsScreen(
                                        product: product,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _PaginationBar(
                        currentPage: response?.page ?? 0,
                        totalPages: response?.totalPages ?? 0,
                        onPrevious: _page > 0 ? _loadPreviousPage : null,
                        onNext:
                            response != null && _page + 1 < response.totalPages
                            ? () => _loadNextPage(response)
                            : null,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _errorMessage(Object? error) {
    if (error is ApiException) {
      return error.message;
    }
    return error?.toString() ?? 'Failed to load products.';
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onSearch});

  final TextEditingController controller;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: onSearch,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search products',
        prefixIcon: const Icon(Icons.search),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 52,
            color: Colors.black38,
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 52, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            'Unable to load products',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onPrevious,
            child: const Text('Previous'),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${currentPage + 1} / ${totalPages == 0 ? 1 : totalPages}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(onPressed: onNext, child: const Text('Next')),
        ),
      ],
    );
  }
}
