import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_notifications_screen.dart';
import 'screens/admin/products/admin_products_screen.dart';
import 'screens/admin/categories/admin_categories_screen.dart';
import 'screens/admin/orders/admin_orders_screen.dart';
import 'screens/admin/customers/admin_customers_screen.dart';
import 'screens/admin/reviews/admin_reviews_screen.dart';
import 'screens/admin/returns/admin_returns_screen.dart';
import 'screens/admin/coupons/admin_coupons_screen.dart';
import 'screens/admin/payments/admin_payments_screen.dart';
import 'screens/admin/invoices/admin_invoices_screen.dart';
import 'screens/home/home_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StyleOra',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D4ED8),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
        ),
      ),
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),
        RegisterScreen.routeName: (_) => const RegisterScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
        AdminDashboardScreen.routeName: (_) => const AdminDashboardScreen(),
        AdminNotificationsScreen.routeName: (_) =>
            const AdminNotificationsScreen(),
        AdminProductsScreen.routeName: (_) => const AdminProductsScreen(),
        AdminCategoriesScreen.routeName: (_) => const AdminCategoriesScreen(),
        AdminOrdersScreen.routeName: (_) => const AdminOrdersScreen(),
        AdminCustomersScreen.routeName: (_) => const AdminCustomersScreen(),
        AdminReviewsScreen.routeName: (_) => const AdminReviewsScreen(),
        AdminReturnsScreen.routeName: (_) => const AdminReturnsScreen(),
        AdminCouponsScreen.routeName: (_) => const AdminCouponsScreen(),
        AdminPaymentsScreen.routeName: (_) => const AdminPaymentsScreen(),
        AdminInvoicesScreen.routeName: (_) => const AdminInvoicesScreen(),
      },
    );
  }
}
