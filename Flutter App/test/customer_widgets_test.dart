import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:styleora_flutter/core/api_client.dart';
import 'package:styleora_flutter/core/cart_provider.dart';
import 'package:styleora_flutter/core/wishlist_provider.dart';
import 'package:styleora_flutter/models/product.dart';
import 'package:styleora_flutter/services/catalog_service.dart';
import 'package:styleora_flutter/widgets/product_card.dart';
import 'package:styleora_flutter/screens/shop/cart_screen.dart';
import 'package:styleora_flutter/screens/shop/product_details_screen.dart';

void main() {
  const product = Product(
    id: 1,
    name: 'Responsive Demo Product',
    brand: 'StyleOra',
    category: 'Fashion',
    description: 'A product used to verify narrow customer layouts.',
    price: 1200,
    discount: 10,
    stock: 5,
  );

  testWidgets('product details fits a narrow mobile viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => WishlistProvider()),
          Provider<CatalogService>(
            create: (_) => CatalogService(
              apiClient: ApiClient(
                httpClient: MockClient((request) async {
                  return http.Response(
                    '''
                    {
                      "id": 1,
                      "name": "Responsive Demo Product",
                      "brand": "StyleOra",
                      "category": "Fashion",
                      "description": "A product used to verify narrow customer layouts.",
                      "price": 1200,
                      "discount": 10,
                      "stock": 5
                    }
                    ''',
                    200,
                    headers: {'content-type': 'application/json'},
                  );
                }),
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: ProductDetailsScreen(product: product)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add to Cart'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cart fits a narrow mobile viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cart = CartProvider()
      ..add(const Product(id: 1, name: 'Cart Product', price: 500, stock: 3));

    await tester.pumpWidget(
      ChangeNotifierProvider<CartProvider>.value(
        value: cart,
        child: const MaterialApp(home: CartScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Proceed to Checkout'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cart screen shows items added through the shared provider', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cart = CartProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CartProvider>.value(value: cart),
          ChangeNotifierProvider(create: (_) => WishlistProvider()),
          Provider<CatalogService>(
            create: (_) => CatalogService(
              apiClient: ApiClient(
                httpClient: MockClient((request) async {
                  return http.Response(
                    '''
                    {
                      "id": 1,
                      "name": "Responsive Demo Product",
                      "brand": "StyleOra",
                      "category": "Fashion",
                      "description": "A product used to verify narrow customer layouts.",
                      "price": 1200,
                      "discount": 10,
                      "stock": 5
                    }
                    ''',
                    200,
                    headers: {'content-type': 'application/json'},
                  );
                }),
              ),
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: product,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    final addButton = find.byIcon(Icons.shopping_bag_outlined).first;
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(cart.itemCount, 1);
    expect(cart.items.single.product.name, product.name);

    await tester.pumpWidget(
      ChangeNotifierProvider<CartProvider>.value(
        value: cart,
        child: const MaterialApp(home: CartScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Responsive Demo Product'), findsOneWidget);
    expect(find.text('Proceed to Checkout'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
