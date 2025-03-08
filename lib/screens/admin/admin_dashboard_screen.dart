import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smart_kirana/models/admin_dashboard_model.dart';
import 'package:smart_kirana/providers/admin_provider.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/screens/admin/category_management_screen.dart';
import 'package:smart_kirana/screens/admin/order_management_screen.dart';
import 'package:smart_kirana/screens/admin/product_management_screen.dart';
import 'package:smart_kirana/screens/admin/user_management_screen.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/admin/admin_drawer.dart';
import 'package:smart_kirana/widgets/admin/dashboard_charts.dart';

class AdminDashboardScreen extends StatefulWidget {
  static const String routeName = '/admin-dashboard';

  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = false;
  bool _showCharts = false; // Start with charts disabled for better performance

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<AdminProvider>(
        context,
        listen: false,
      ).fetchDashboardData();
    } catch (e) {
      // Error will be handled by the provider
      debugPrint('Error loading dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final user = authProvider.user;

    // Check if user is admin
    if (user?.role != 'ADMIN') {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Unauthorized Access', style: AppTextStyles.heading1),
              const SizedBox(height: AppPadding.medium),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: Icon(
              _showCharts ? Icons.bar_chart : Icons.bar_chart_outlined,
            ),
            tooltip: _showCharts ? 'Hide Charts' : 'Show Charts',
            onPressed: () {
              setState(() {
                _showCharts = !_showCharts;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: _buildBody(adminProvider),
    );
  }

  Widget _buildBody(AdminProvider adminProvider) {
    if (_isLoading || adminProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (adminProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: ${adminProvider.error}',
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppPadding.medium),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: AppPadding.large),

            const Text('Dashboard Overview', style: AppTextStyles.heading2),
            const SizedBox(height: AppPadding.medium),
            _buildStatsGrid(adminProvider.dashboardData),

            const SizedBox(height: AppPadding.large),
            const Text('Admin Features', style: AppTextStyles.heading2),
            const SizedBox(height: AppPadding.medium),
            _buildFeatureGrid(),

            const SizedBox(height: AppPadding.large),

            // Charts section (conditionally displayed)
            if (_showCharts) ...[
              DashboardCharts(data: adminProvider.dashboardData),
              const SizedBox(height: AppPadding.large),
            ],

            _buildRecentOrdersSection(adminProvider.dashboardData),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final user = Provider.of<AuthProvider>(context).user;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.name ?? 'Admin'}',
              style: AppTextStyles.heading1,
            ),
            const SizedBox(height: 8),
            Text(
              'Email: ${user?.email ?? 'Not available'}',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Role: ${user?.role ?? 'Not available'}',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(AdminDashboardModel data) {
    final currencyFormat = NumberFormat.currency(symbol: '₹');

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          'Total Users',
          data.totalUsers.toString(),
          Icons.people,
          AppColors.primary,
          () => Navigator.pushNamed(context, UserManagementScreen.routeName),
        ),
        _buildStatCard(
          'Total Revenue',
          currencyFormat.format(data.totalRevenue),
          Icons.currency_rupee,
          AppColors.accent,
          () {},
        ),
        _buildStatCard(
          'Total Orders',
          data.totalOrders.toString(),
          Icons.shopping_bag,
          AppColors.secondary,
          () => Navigator.pushNamed(context, OrderManagementScreen.routeName),
        ),
        _buildStatCard(
          'Pending Orders',
          data.pendingOrders.toString(),
          Icons.pending_actions,
          Colors.orange,
          () => Navigator.pushNamed(
            context,
            OrderManagementScreen.routeName,
            arguments: {'filter': 'PENDING'},
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Icon(icon, color: color, size: 24),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppBorderRadius.small),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildFeatureCard(
          'Product Management',
          Icons.inventory,
          () => Navigator.pushNamed(context, ProductManagementScreen.routeName),
        ),
        _buildFeatureCard(
          'User Management',
          Icons.people,
          () => Navigator.pushNamed(context, UserManagementScreen.routeName),
        ),
        _buildFeatureCard(
          'Order Management',
          Icons.shopping_cart,
          () => Navigator.pushNamed(context, OrderManagementScreen.routeName),
        ),
        _buildFeatureCard(
          'Category Management',
          Icons.category,
          () =>
              Navigator.pushNamed(context, CategoryManagementScreen.routeName),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTextStyles.heading3,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentOrdersSection(AdminDashboardModel data) {
    if (data.recentOrders.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Orders', style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No recent orders available',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Orders', style: AppTextStyles.heading2),
            TextButton(
              onPressed:
                  () => Navigator.pushNamed(
                    context,
                    OrderManagementScreen.routeName,
                  ),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount:
              data.recentOrders.length > 5 ? 5 : data.recentOrders.length,
          itemBuilder: (context, index) {
            final order = data.recentOrders[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  'Order #${order.orderId.length > 8 ? order.orderId.substring(0, 8) : order.orderId}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer: ${order.userName}'),
                    Text(
                      'Date: ${DateFormat('MMM d, yyyy').format(order.orderDate)}',
                    ),
                    Text('Status: ${order.status}'),
                  ],
                ),
                trailing: Text(
                  '₹${order.amount.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                onTap: () {
                  // Navigate to order details
                  Navigator.pushNamed(
                    context,
                    OrderManagementScreen.routeName,
                    arguments: {'orderId': order.orderId},
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
