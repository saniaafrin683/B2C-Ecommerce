import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:styleora_flutter/core/api_client.dart';
import 'package:styleora_flutter/core/auth_provider.dart';
import 'package:styleora_flutter/core/session_manager.dart';
import 'package:styleora_flutter/core/cart_provider.dart';
import 'package:styleora_flutter/core/wishlist_provider.dart';
import 'package:styleora_flutter/main.dart';
import 'package:styleora_flutter/services/admin/admin_dashboard_service.dart';
import 'package:styleora_flutter/services/admin/admin_product_service.dart';
import 'package:styleora_flutter/services/admin/admin_category_service.dart';
import 'package:styleora_flutter/services/admin/admin_order_service.dart';
import 'package:styleora_flutter/services/auth_service.dart';
import 'package:styleora_flutter/services/catalog_service.dart';
import 'package:styleora_flutter/services/customer_commerce_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens login when no session exists', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final apiClient = ApiClient();
    final sessionManager = SessionManager();
    final authService = AuthService(apiClient: apiClient);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SessionManager>.value(value: sessionManager),
          Provider<ApiClient>.value(value: apiClient),
          Provider<AuthService>.value(value: authService),
          Provider<CatalogService>(
            create: (_) => CatalogService(apiClient: apiClient),
          ),
          Provider<AdminDashboardService>(
            create: (_) => AdminDashboardService(apiClient: apiClient),
          ),
          Provider<AdminProductService>(
            create: (_) => AdminProductService(apiClient: apiClient),
          ),
          Provider<AdminCategoryService>(
            create: (_) => AdminCategoryService(apiClient: apiClient),
          ),
          Provider<AdminOrderService>(
            create: (_) => AdminOrderService(apiClient: apiClient),
          ),
          Provider<CustomerCommerceService>(
            create: (_) => CustomerCommerceService(apiClient: apiClient),
          ),
          ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
          ChangeNotifierProvider<WishlistProvider>(
            create: (_) => WishlistProvider(),
          ),
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(
              authService: authService,
              sessionManager: sessionManager,
            ),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
