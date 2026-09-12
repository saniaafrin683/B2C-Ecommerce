import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_provider.dart';
import '../../core/cart_provider.dart';
import '../../models/cart_item.dart';
import '../../services/customer_commerce_service.dart';
import '../../widgets/product_image.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponController = TextEditingController();
  bool _applying = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon(CartProvider cart) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    setState(() => _applying = true);
    try {
      final auth = context.read<AuthProvider>();
      final coupon = await context.read<CustomerCommerceService>().applyCoupon(
        auth.token ?? '',
        code,
        cart.items,
      );
      cart.applyCoupon(coupon);
      if (mounted) _message(coupon.message ?? 'Coupon applied.');
    } catch (error) {
      if (mounted) _message(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  void _message(String text, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: error ? const Color(0xFFB91C1C) : null,
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your Cart')),
    body: Consumer<CartProvider>(
      builder: (context, cart, _) {
        if (cart.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 64,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 14),
                Text(
                  'Your cart is empty',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Add something you love to continue.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Continue Shopping'),
                ),
              ],
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final summary = _CartSummary(
              cart: cart,
              couponController: _couponController,
              applying: _applying,
              onApply: () => _applyCoupon(cart),
            );
            return SingleChildScrollView(
              padding: EdgeInsets.all(constraints.maxWidth < 600 ? 16 : 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: constraints.maxWidth >= 850
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _CartItemsList(
                                items: cart.items,
                                cart: cart,
                              ),
                            ),
                            const SizedBox(width: 24),
                            SizedBox(width: 360, child: summary),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _CartItemsList(items: cart.items, cart: cart),
                            const SizedBox(height: 20),
                            summary,
                          ],
                        ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

class _CartItemsList extends StatelessWidget {
  const _CartItemsList({required this.items, required this.cart});

  final List<CartItem> items;
  final CartProvider cart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Cart Items (${items.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return _CartItemCard(
              key: ValueKey(item.product.id ?? item.product.name ?? index),
              item: item,
              cart: cart,
            );
          },
        ),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({super.key, required this.item, required this.cart});
  final CartItem item;
  final CartProvider cart;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final image = SizedBox(
          width: 76,
          height: 76,
          child: ProductImage(
            imageUrl: item.product.resolvedImageUrl,
            borderRadius: BorderRadius.circular(12),
          ),
        );
        final info = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.product.name ?? 'Product',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              '৳${item.product.effectivePrice.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFF1D4ED8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );
        final quantity = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.filledTonal(
              visualDensity: VisualDensity.compact,
              onPressed: () =>
                  cart.setQuantity(item.product.id!, item.quantity - 1),
              icon: const Icon(Icons.remove, size: 17),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '${item.quantity}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton.filledTonal(
              visualDensity: VisualDensity.compact,
              onPressed: item.quantity < (item.product.stock ?? 0)
                  ? () => cart.setQuantity(item.product.id!, item.quantity + 1)
                  : null,
              icon: const Icon(Icons.add, size: 17),
            ),
          ],
        );
        if (constraints.maxWidth < 360) {
          return Column(
            children: [
              Row(
                children: [
                  image,
                  const SizedBox(width: 12),
                  Expanded(child: info),
                  IconButton(
                    tooltip: 'Remove',
                    onPressed: () => cart.remove(item.product.id!),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  quantity,
                  const Spacer(),
                  Text(
                    '৳${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            image,
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [info, const SizedBox(height: 8), quantity],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Remove',
                  onPressed: () => cart.remove(item.product.id!),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFDC2626),
                  ),
                ),
                Text(
                  '৳${item.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({
    required this.cart,
    required this.couponController,
    required this.applying,
    required this.onApply,
  });
  final CartProvider cart;
  final TextEditingController couponController;
  final bool applying;
  final VoidCallback onApply;
  static const shipping = 80.0;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Summary', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 18),
        if (cart.coupon == null)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: couponController,
                  decoration: const InputDecoration(
                    labelText: 'Coupon code',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: applying ? null : onApply,
                child: applying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Apply'),
              ),
            ],
          )
        else
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.local_offer_outlined,
              color: Color(0xFF059669),
            ),
            title: Text(
              cart.coupon!.code,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('Coupon applied'),
            trailing: IconButton(
              onPressed: cart.removeCoupon,
              icon: const Icon(Icons.close),
            ),
          ),
        const Divider(height: 28),
        _SummaryRow('Regular subtotal', cart.regularSubtotal),
        if (cart.productDiscount > 0)
          _SummaryRow('Product savings', -cart.productDiscount, green: true),
        _SummaryRow('Subtotal', cart.subtotal),
        if (cart.couponDiscount > 0)
          _SummaryRow('Coupon discount', -cart.couponDiscount, green: true),
        _SummaryRow('Delivery', shipping),
        const Divider(height: 26),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Total',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '৳${cart.totalWithShipping(shipping).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1D4ED8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CheckoutScreen(shippingCost: shipping),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 13),
              child: Text('Proceed to Checkout'),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.green = false});
  final String label;
  final double value;
  final bool green;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Color(0xFF64748B))),
        ),
        Text(
          '${value < 0 ? '-' : ''}৳${value.abs().toStringAsFixed(2)}',
          style: TextStyle(
            color: green ? const Color(0xFF059669) : null,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
