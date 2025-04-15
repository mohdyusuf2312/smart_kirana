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
  String? _localError;

  @override
  void initState() {
    super.initState();
    debugPrint('AdminDashboardScreen initState called');

    // Use a small delay to ensure the widget is fully built before loading data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('AdminDashboardScreen post-frame callback');
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('AdminDashboardScreen didChangeDependencies called');

    // Check if admin provider is available and initialized
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    debugPrint('Admin check: ${authProvider.user?.role == 'ADMIN'}');
    debugPrint('Admin provider available: ${adminProvider.hashCode}');
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _localError = null;
    });

    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);

      // Check if the user is admin before proceeding
      if (!adminProvider.isAdmin) {
        setState(() {
          _localError = 'Unauthorized access. Admin privileges required.';
          _isLoading = false;
        });
        return;
      }

      await adminProvider.fetchDashboardData();

      // Check if there was an error in the provider
      if (adminProvider.error != null) {
        setState(() {
          _localError = adminProvider.error;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      setState(() {
        _localError = 'Failed to load dashboard data: ${e.toString()}';
      });
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

    // Show local error or provider error
    final error = _localError ?? adminProvider.error;
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $error',
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

    // Wrap everything in a try-catch to identify rendering issues
    try {
      debugPrint('Building admin dashboard content');

      return RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppPadding.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              Builder(
                builder: (context) {
                  try {
                    return _buildWelcomeCard();
                  } catch (e) {
                    debugPrint('Error building welcome card: $e');
                    return const Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(AppPadding.medium),
                        child: Text('Welcome to Admin Dashboard'),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: AppPadding.large),

              // Charts section (always displayed)
              Builder(
                builder: (context) {
                  try {
                    return DashboardCharts(data: adminProvider.dashboardData);
                  } catch (e) {
                    debugPrint('Error building charts: $e');
                    return const Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(AppPadding.medium),
                        child: Text('Charts unavailable'),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: AppPadding.large),

              // Dashboard Overview
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(13), // 0.05 * 255 = ~13
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                ),
                padding: const EdgeInsets.all(AppPadding.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.dashboard, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Dashboard Overview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.primary, thickness: 1),
                    const SizedBox(height: AppPadding.small),
                    Builder(
                      builder: (context) {
                        try {
                          return _buildStatsGrid(adminProvider.dashboardData);
                        } catch (e) {
                          debugPrint('Error building stats grid: $e');
                          return const Card(
                            elevation: 2,
                            child: Padding(
                              padding: EdgeInsets.all(AppPadding.medium),
                              child: Text('Stats unavailable'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppPadding.large),

              // Admin Features
              Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(13), // 0.05 * 255 = ~13
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                ),
                padding: const EdgeInsets.all(AppPadding.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.admin_panel_settings,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Admin Features',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.secondary, thickness: 1),
                    const SizedBox(height: AppPadding.small),
                    Builder(
                      builder: (context) {
                        try {
                          return _buildFeatureGrid();
                        } catch (e) {
                          debugPrint('Error building feature grid: $e');
                          return const Card(
                            elevation: 2,
                            child: Padding(
                              padding: EdgeInsets.all(AppPadding.medium),
                              child: Text('Features unavailable'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppPadding.large),

              // Recent Orders
              Builder(
                builder: (context) {
                  try {
                    return _buildRecentOrdersSection(
                      adminProvider.dashboardData,
                    );
                  } catch (e) {
                    debugPrint('Error building recent orders: $e');
                    return const Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(AppPadding.medium),
                        child: Text('Recent orders unavailable'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error building admin dashboard: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Error rendering dashboard',
              style: TextStyle(color: AppColors.error, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              e.toString(),
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
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
              style: TextButton.styleFrom(
                minimumSize: Size.zero, // Reset the minimum size
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
