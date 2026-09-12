import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/cart_provider.dart';
import '../../core/wishlist_provider.dart';
import '../../models/product.dart';
import '../../widgets/product_image.dart';
import 'product_details_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Wishlist')),
    body: Consumer<WishlistProvider>(
      builder: (context, wishlist, _) {
        if (wishlist.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_border_rounded,
                  size: 62,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 14),
                Text(
                  'Your wishlist is empty',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Save products to find them here.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1000
                ? 4
                : constraints.maxWidth >= 650
                ? 3
                : constraints.maxWidth >= 430
                ? 2
                : 1;
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: columns == 1 ? 2.5 : .72,
              ),
              itemCount: wishlist.items.length,
              itemBuilder: (context, index) =>
                  _WishlistCard(product: wishlist.items[index]),
            );
          },
        );
      },
    ),
  );
}

class _WishlistCard extends StatelessWidget {
  const _WishlistCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
    ),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProductImage(
                  imageUrl: product.resolvedImageUrl,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                Positioned(
                  right: 7,
                  top: 7,
                  child: IconButton.filledTonal(
                    onPressed: () =>
                        context.read<WishlistProvider>().toggle(product),
                    icon: const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name ?? 'Product',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 7),
                Text(
                  '৳${product.effectivePrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: (product.stock ?? 0) > 0
                        ? () {
                            context.read<CartProvider>().add(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to cart.')),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Add to Cart'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
