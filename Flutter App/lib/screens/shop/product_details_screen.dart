import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/cart_provider.dart';
import '../../core/wishlist_provider.dart';
import '../../models/product.dart';
import '../../services/catalog_service.dart';
import '../../widgets/product_image.dart';
import 'cart_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late Future<Product> _request;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _request = widget.product.id == null
        ? Future.value(widget.product)
        : context.read<CatalogService>().getProduct(widget.product.id!);
  }

  void _retry() {
    setState(() {
      _request = widget.product.id == null
          ? Future.value(widget.product)
          : context.read<CatalogService>().getProduct(widget.product.id!);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Product Details'),
      actions: [
        Consumer<WishlistProvider>(
          builder: (context, wishlist, _) => IconButton(
            tooltip: wishlist.contains(widget.product)
                ? 'Remove from wishlist'
                : 'Add to wishlist',
            onPressed: () => wishlist.toggle(widget.product),
            icon: Icon(
              wishlist.contains(widget.product)
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: wishlist.contains(widget.product)
                  ? const Color(0xFFDC2626)
                  : null,
            ),
          ),
        ),
        Consumer<CartProvider>(
          builder: (context, cart, _) => Badge(
            isLabelVisible: cart.itemCount > 0,
            label: Text('${cart.itemCount}'),
            child: IconButton(
              tooltip: 'Cart',
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const CartScreen())),
              icon: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
        ),
      ],
    ),
    body: FutureBuilder<Product>(
      future: _request,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 48),
                const SizedBox(height: 12),
                const Text('Unable to load product.'),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: _retry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final product = snapshot.data ?? widget.product;
        final stock = product.stock ?? 0;
        return LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.all(constraints.maxWidth < 600 ? 16 : 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: constraints.maxWidth >= 760
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _ProductPhoto(product: product)),
                          const SizedBox(width: 36),
                          Expanded(
                            child: _ProductInformation(
                              product: product,
                              quantity: _quantity,
                              onQuantity: (value) =>
                                  setState(() => _quantity = value),
                              onAdd: () => _add(product),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProductPhoto(product: product),
                          const SizedBox(height: 22),
                          _ProductInformation(
                            product: product,
                            quantity: _quantity.clamp(1, stock > 0 ? stock : 1),
                            onQuantity: (value) =>
                                setState(() => _quantity = value),
                            onAdd: () => _add(product),
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

  void _add(Product product) {
    final added = context.read<CartProvider>().add(
      product,
      quantity: _quantity,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added ? 'Added to cart.' : 'This product is out of stock.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ProductPhoto extends StatelessWidget {
  const _ProductPhoto({required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 0.9,
    child: ProductImage(
      imageUrl: product.resolvedImageUrl,
      borderRadius: BorderRadius.circular(24),
    ),
  );
}

class _ProductInformation extends StatelessWidget {
  const _ProductInformation({
    required this.product,
    required this.quantity,
    required this.onQuantity,
    required this.onAdd,
  });
  final Product product;
  final int quantity;
  final ValueChanged<int> onQuantity;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final stock = product.stock ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.brand ?? product.category ?? 'StyleOra',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.name ?? 'Untitled product',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          children: [
            Text(
              '৳${product.effectivePrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1D4ED8),
              ),
            ),
            if ((product.discount ?? 0) > 0) ...[
              Text(
                '৳${(product.price ?? 0).toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              Chip(label: Text('-${product.discount!.toStringAsFixed(0)}%')),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: stock > 0
                ? const Color(0xFFECFDF5)
                : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            stock > 0 ? '$stock available' : 'Out of stock',
            style: TextStyle(
              color: stock > 0
                  ? const Color(0xFF047857)
                  : const Color(0xFFB91C1C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          product.description?.trim().isNotEmpty == true
              ? product.description!
              : 'A curated StyleOra product selected for quality, comfort, and everyday style.',
          style: const TextStyle(height: 1.6, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: quantity > 1 ? () => onQuantity(quantity - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '$quantity',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: quantity < stock
                  ? () => onQuantity(quantity + 1)
                  : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: stock > 0 ? onAdd : null,
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Add to Cart'),
            ),
          ),
        ),
      ],
    );
  }
}
