import 'package:flutter/material.dart';

const adminInvoicesRoute = '/admin/invoices';

class AdminNavigationItem {
  const AdminNavigationItem(
    this.label,
    this.icon, {
    this.route,
    this.isLogout = false,
  });

  final String label;
  final IconData icon;
  final String? route;
  final bool isLogout;
}

const adminNavigationItems = <AdminNavigationItem>[
  AdminNavigationItem('Dashboard', Icons.grid_view_rounded, route: '/admin'),
  AdminNavigationItem(
    'Products',
    Icons.inventory_2_outlined,
    route: '/admin/products',
  ),
  AdminNavigationItem(
    'Categories',
    Icons.category_outlined,
    route: '/admin/categories',
  ),
  AdminNavigationItem(
    'Orders',
    Icons.receipt_long_outlined,
    route: '/admin/orders',
  ),
  AdminNavigationItem(
    'Customers',
    Icons.people_outline_rounded,
    route: '/admin/customers',
  ),
  AdminNavigationItem(
    'Reviews',
    Icons.rate_review_outlined,
    route: '/admin/reviews',
  ),
  AdminNavigationItem(
    'Returns',
    Icons.assignment_return_outlined,
    route: '/admin/returns',
  ),
  AdminNavigationItem(
    'Coupons',
    Icons.local_offer_outlined,
    route: '/admin/coupons',
  ),
  AdminNavigationItem(
    'Payments',
    Icons.payments_outlined,
    route: '/admin/payments',
  ),
  AdminNavigationItem(
    'Invoices',
    Icons.description_outlined,
    route: adminInvoicesRoute,
  ),
  AdminNavigationItem('Logout', Icons.logout_rounded, isLogout: true),
];

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.onItemSelected,
    required this.selectedLabel,
  });

  final ValueChanged<AdminNavigationItem> onItemSelected;
  final String selectedLabel;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF111827),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 18, 20),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'StyleOra',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'ADMIN CONSOLE',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 9,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF263244), height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                itemCount: adminNavigationItems.length,
                separatorBuilder: (_, index) => index == 9
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: Color(0xFF263244), height: 1),
                      )
                    : const SizedBox(height: 3),
                itemBuilder: (context, index) {
                  final item = adminNavigationItems[index];
                  final selected = item.label == selectedLabel;
                  return Material(
                    color: selected
                        ? const Color(0xFF2563EB)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                      leading: Icon(
                        item.icon,
                        size: 21,
                        color: selected
                            ? Colors.white
                            : item.isLogout
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFF94A3B8),
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : item.isLogout
                              ? const Color(0xFFFCA5A5)
                              : const Color(0xFFCBD5E1),
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                      onTap: () => onItemSelected(item),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
