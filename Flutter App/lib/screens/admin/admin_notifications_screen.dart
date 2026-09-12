import 'package:flutter/material.dart';

import '../../widgets/admin/admin_shell.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  static const routeName = adminNotificationsRoute;

  @override
  Widget build(BuildContext context) {
    return const AdminShell(
      title: 'Notifications',
      activeItem: '',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Color(0xFF94A3B8)),
            SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                color: Color(0xFF475569),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
