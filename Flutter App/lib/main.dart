import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/api_client.dart';
import 'core/auth_provider.dart';
import 'core/session_manager.dart';
import 'core/cart_provider.dart';
import 'core/wishlist_provider.dart';
import 'services/auth_service.dart';
import 'services/catalog_service.dart';
import 'services/admin/admin_dashboard_service.dart';
import 'services/admin/admin_product_service.dart';
import 'services/admin/admin_category_service.dart';
import 'services/admin/admin_order_service.dart';
import 'services/admin/admin_customer_service.dart';
import 'services/admin/admin_review_service.dart';
import 'services/admin/admin_return_service.dart';
import 'services/admin/admin_coupon_service.dart';
import 'services/admin/admin_payment_service.dart';
import 'services/admin/admin_invoice_service.dart';
import 'services/customer_commerce_service.dart';

export 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sessionManager = SessionManager();
  final apiClient = ApiClient();
  final authService = AuthService(apiClient: apiClient);
  final catalogService = CatalogService(apiClient: apiClient);
  final adminDashboardService = AdminDashboardService(apiClient: apiClient);
  final adminProductService = AdminProductService(apiClient: apiClient);
  final adminCategoryService = AdminCategoryService(apiClient: apiClient);
  final adminOrderService = AdminOrderService(apiClient: apiClient);
  final adminCustomerService = AdminCustomerService(apiClient: apiClient);
  final adminReviewService = AdminReviewService(apiClient: apiClient);
  final adminReturnService = AdminReturnService(
    apiClient: apiClient,
    adminOrderService: adminOrderService,
  );
  final adminCouponService = AdminCouponService(apiClient: apiClient);
  final adminPaymentService = AdminPaymentService(
    apiClient: apiClient,
    adminOrderService: adminOrderService,
  );
  final adminInvoiceService = AdminInvoiceService(
    apiClient: apiClient,
    adminOrderService: adminOrderService,
  );
  final customerCommerceService = CustomerCommerceService(apiClient: apiClient);

  runApp(
    MultiProvider(
      providers: [
        Provider<SessionManager>.value(value: sessionManager),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthService>.value(value: authService),
        Provider<CatalogService>.value(value: catalogService),
        Provider<AdminDashboardService>.value(value: adminDashboardService),
        Provider<AdminProductService>.value(value: adminProductService),
        Provider<AdminCategoryService>.value(value: adminCategoryService),
        Provider<AdminOrderService>.value(value: adminOrderService),
        Provider<AdminCustomerService>.value(value: adminCustomerService),
        Provider<AdminReviewService>.value(value: adminReviewService),
        Provider<AdminReturnService>.value(value: adminReturnService),
        Provider<AdminCouponService>.value(value: adminCouponService),
        Provider<AdminPaymentService>.value(value: adminPaymentService),
        Provider<AdminInvoiceService>.value(value: adminInvoiceService),
        Provider<CustomerCommerceService>.value(value: customerCommerceService),
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
}
