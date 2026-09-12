import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/cart_provider.dart';
import '../core/wishlist_provider.dart';
import '../models/product.dart';
import 'product_image.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = product.resolvedImageUrl;
    final hasDiscount = (product.discount ?? 0) > 0;
    final stock = product.stock ?? 0;

    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProductImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      backgroundColor: const Color(0xFFF1F5F9),
                    ),
                    if (stock <= 0)
                      const Positioned(
                        left: 12,
                        top: 12,
                        child: _Badge(
                          label: 'Out',
                          backgroundColor: Color(0xFF991B1B),
                        ),
                      )
                    else if (stock < 10)
                      Positioned(
                        left: 12,
                        top: 12,
                        child: _Badge(
                          label: '$stock left',
                          backgroundColor: const Color(0xFFB45309),
                        ),
                      ),
                    if (hasDiscount)
                      Positioned(
                        right: 12,
                        top: 12,
                        child: _Badge(
                          label: '-${product.discount!.toStringAsFixed(0)}%',
                          backgroundColor: const Color(0xFF1D4ED8),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name ?? 'Untitled product',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _buildSubtitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          '৳${product.effectivePrice.toStringAsFixed(2)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '৳${(product.price ?? 0).toStringAsFixed(2)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.black45,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        children: [
                          Consumer<WishlistProvider>(
                            builder: (context, wishlist, _) {
                              final selected = wishlist.contains(product);
                              return IconButton(
                                tooltip: selected
                                    ? 'Remove from wishlist'
                                    : 'Add to wishlist',
                                onPressed: stock <= 0
                                    ? null
                                    : () => wishlist.toggle(product),
                                icon: Icon(
                                  selected
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: selected
                                      ? const Color(0xFFBE123C)
                                      : const Color(0xFF0F172A),
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFF8FAFC),
                                  foregroundColor: const Color(0xFF0F172A),
                                  minimumSize: const Size(40, 40),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _CartActionButton(
                              product: product,
                              stock: stock,
                              width: constraints.maxWidth,
                              onAdd: () => _addToCart(context, product),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _DetailsArrowButton(onTap: onTap),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String?>[
      product.brand,
      product.category,
    ].where((value) => value != null && value.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'StyleOra' : parts.join(' | ');
  }

  void _addToCart(BuildContext context, Product product) {
    final added = context.read<CartProvider>().add(product);
    if (added) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to cart'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _CartActionButton extends StatelessWidget {
  const _CartActionButton({
    required this.product,
    required this.stock,
    required this.width,
    required this.onAdd,
  });

  final Product product;
  final int stock;
  final double width;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    if (width < 450) {
      return Align(
        alignment: Alignment.center,
        child: IconButton.filled(
          tooltip: 'Add to cart',
          onPressed: stock <= 0 ? null : onAdd,
          icon: const Icon(Icons.shopping_bag_outlined, size: 16),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            minimumSize: const Size(40, 40),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: stock <= 0 ? null : onAdd,
      icon: const Icon(Icons.shopping_bag_outlined, size: 16),
      label: Text(width < 600 ? 'Add' : 'Add to Cart'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFCBD5E1),
        disabledForegroundColor: Colors.white70,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        minimumSize: const Size(0, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _DetailsArrowButton extends StatelessWidget {
  const _DetailsArrowButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(9),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.backgroundColor});

  final String label;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
