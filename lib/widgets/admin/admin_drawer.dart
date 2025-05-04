import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/screens/admin/admin_dashboard_screen.dart';
import 'package:smart_kirana/screens/admin/category_management_screen.dart';
import 'package:smart_kirana/screens/admin/low_stock_screen.dart';
import 'package:smart_kirana/screens/admin/order_management_screen.dart';
import 'package:smart_kirana/screens/admin/product_management_screen.dart';
import 'package:smart_kirana/screens/admin/recommendation_management_screen.dart';
import 'package:smart_kirana/screens/admin/user_management_screen.dart';
import 'package:smart_kirana/screens/home/home_screen.dart';
import 'package:smart_kirana/utils/constants.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart Kirana',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Admin Panel',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name !=
                  AdminDashboardScreen.routeName) {
                Navigator.pushReplacementNamed(
                  context,
                  AdminDashboardScreen.routeName,
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Products'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, ProductManagementScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Categories'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, CategoryManagementScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Users'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, UserManagementScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('Orders'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, OrderManagementScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber),
            title: const Text('Low Stock'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, LowStockScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.recommend),
            title: const Text('Recommendations'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                RecommendationManagementScreen.routeName,
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.store),
            title: const Text('Go to Store'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                HomeScreen.routeName,
                (route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
