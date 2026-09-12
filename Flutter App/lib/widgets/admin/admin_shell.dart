import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import 'admin_sidebar.dart';

const adminNotificationsRoute = '/admin/notifications';

class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.title,
    required this.child,
    this.activeItem = 'Dashboard',
  });

  final String title;
  final Widget child;
  final String activeItem;

  static const _implementedRoutes = <String, String>{
    'Dashboard': '/admin',
    'Products': '/admin/products',
    'Categories': '/admin/categories',
    'Orders': '/admin/orders',
    'Customers': '/admin/customers',
    'Reviews': '/admin/reviews',
    'Returns': '/admin/returns',
    'Coupons': '/admin/coupons',
    'Payments': '/admin/payments',
    'Invoices': adminInvoicesRoute,
  };

  Future<void> _selectItem(
    BuildContext context,
    AdminNavigationItem item, {
    bool closeDrawer = false,
  }) async {
    if (closeDrawer) {
      Navigator.of(context).pop();
    }

    if (item.isLogout) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(LoginScreen.routeName, (_) => false);
      }
      return;
    }

    final route = item.route ?? _implementedRoutes[item.label];
    if (route != null && item.label != activeItem && context.mounted) {
      Navigator.of(context).pushReplacementNamed(route);
      return;
    }

    if (route == null && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${item.label} is coming soon.')),
        );
    }
  }

  void _openNotifications(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(adminNotificationsRoute);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        final content = ColoredBox(
          color: const Color(0xFFF5F7FB),
          child: Column(
            children: [
              if (desktop)
                _DesktopHeader(
                  title: title,
                  onNotifications: () => _openNotifications(context),
                ),
              Expanded(child: child),
            ],
          ),
        );

        if (desktop) {
          return Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 250,
                  child: AdminSidebar(
                    selectedLabel: activeItem,
                    onItemSelected: (item) => _selectItem(context, item),
                  ),
                ),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => _openNotifications(context),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 20,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          drawer: Drawer(
            width: 270,
            child: AdminSidebar(
              selectedLabel: activeItem,
              onItemSelected: (item) =>
                  _selectItem(context, item, closeDrawer: true),
            ),
          ),
          body: content,
        );
      },
    );
  }
}

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({required this.title, required this.onNotifications});

  final String title;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8ECF3))),
      ),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          IconButton(
            tooltip: 'Notifications',
            onPressed: onNotifications,
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 22),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFEFF6FF),
            child: Icon(Icons.person_outline_rounded, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Administrator',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  auth.customer?.email ?? 'Admin account',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
