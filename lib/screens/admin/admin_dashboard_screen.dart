import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smart_kirana/models/admin_dashboard_model.dart';
import 'package:smart_kirana/providers/admin_provider.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/screens/admin/category_management_screen.dart';
import 'package:smart_kirana/screens/admin/expiring_soon_screen.dart';
import 'package:smart_kirana/screens/admin/low_stock_screen.dart';
import 'package:smart_kirana/screens/admin/order_management_screen.dart';
import 'package:smart_kirana/screens/admin/product_management_screen.dart';
import 'package:smart_kirana/screens/admin/recommendation_management_screen.dart';
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
    // debugPrint('AdminDashboardScreen initState called');

    // Use a small delay to ensure the widget is fully built before loading data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // debugPrint('AdminDashboardScreen post-frame callback');
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // debugPrint('AdminDashboardScreen didChangeDependencies called');

    // Check if admin provider is available and initialized
    // final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    // final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // debugPrint('Admin check: ${authProvider.user?.role == 'ADMIN'}');
    // debugPrint('Admin provider available: ${adminProvider.hashCode}');
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
      // debugPrint('Error loading dashboard data: $e');
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
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show quick action menu
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppBorderRadius.large),
              ),
            ),
            builder: (context) => _buildQuickActionMenu(),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
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
      // debugPrint('Building admin dashboard content');

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
                    // debugPrint('Error building welcome card: $e');
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
                    // debugPrint('Error building charts: $e');
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
              const SizedBox(height: AppPadding.medium),

              // Dashboard Overview
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppPadding.small),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(26),
                              borderRadius: BorderRadius.circular(
                                AppBorderRadius.small,
                              ),
                            ),
                            child: const Icon(
                              Icons.dashboard,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
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
                      Divider(
                        color: AppColors.primary.withAlpha(51),
                        thickness: 1,
                      ),
                      const SizedBox(height: AppPadding.small),
                      Builder(
                        builder: (context) {
                          try {
                            return _buildStatsGrid(adminProvider.dashboardData);
                          } catch (e) {
                            // debugPrint('Error building stats grid: $e');
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
              ),

              const SizedBox(height: AppPadding.medium),

              // Admin Features
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppPadding.small),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withAlpha(26),
                              borderRadius: BorderRadius.circular(
                                AppBorderRadius.small,
                              ),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 12),
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
                      Divider(
                        color: AppColors.secondary.withAlpha(51),
                        thickness: 1,
                      ),
                      const SizedBox(height: AppPadding.small),
                      Builder(
                        builder: (context) {
                          try {
                            return _buildFeatureGrid();
                          } catch (e) {
                            // debugPrint('Error building feature grid: $e');
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
              ),

              const SizedBox(height: AppPadding.medium),

              // Recent Orders
              Builder(
                builder: (context) {
                  try {
                    return _buildRecentOrdersSection(
                      adminProvider.dashboardData,
                    );
                  } catch (e) {
                    // debugPrint('Error building recent orders: $e');
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
      // debugPrint('Error building admin dashboard: $e');
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
    final now = DateTime.now();
    String greeting = "Good Morning";

    if (now.hour >= 12 && now.hour < 17) {
      greeting = "Good Afternoon";
    } else if (now.hour >= 17) {
      greeting = "Good Evening";
    }

    return Card(
      elevation: 2, // Reduced elevation
      margin: const EdgeInsets.symmetric(vertical: 8), // Smaller margin
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppBorderRadius.small,
        ), // Smaller radius
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primary.withAlpha(179)],
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.small),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.small), // Reduced padding
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // More compact
                  children: [
                    Row(
                      children: [
                        Text(
                          greeting,
                          style: AppTextStyles.bodyMedium.copyWith(
                            // Smaller text
                            color: Colors.white.withAlpha(230),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51),
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.small,
                            ),
                          ),
                          child: Text(
                            user?.role ?? 'ADMIN',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10, // Smaller font
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.name ?? 'Admin',
                      style: AppTextStyles.heading3.copyWith(
                        // Smaller heading
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const CircleAvatar(
                radius: 20, // Smaller avatar
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 24,
                  color: AppColors.primary,
                ), // Smaller icon
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(AdminDashboardModel data) {
    final currencyFormat = NumberFormat.currency(symbol: '₹');

    return GridView.count(
      crossAxisCount: 2, // Changed from 2 to 4 for more compact layout
      crossAxisSpacing: 8, // Reduced spacing
      mainAxisSpacing: 8, // Reduced spacing
      shrinkWrap: true,
      childAspectRatio: 1.2, // Adjust aspect ratio for better fit
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
            arguments: {'filter': 'pending'},
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
      elevation: 2, // Reduced elevation
      margin: const EdgeInsets.all(4), // Smaller margin
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppBorderRadius.small,
        ), // Smaller radius
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Reduced padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center, // Center alignment
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 16), // Smaller icon
                  const SizedBox(width: 4),
                  Text(
                    title,
                    style: AppTextStyles.bodySmall.copyWith(
                      // Smaller text
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8), // Reduced spacing
              Text(
                value,
                style: AppTextStyles.bodyLarge.copyWith(
                  // Smaller heading
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4), // Reduced spacing
              // Animated progress indicator
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800), // Faster animation
                builder: (context, value, child) {
                  return Container(
                    height: 2, // Thinner line
                    width: 40 * value, // Shorter line
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.small,
                      ),
                    ),
                  );
                },
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
      crossAxisSpacing: 8, // Reduced spacing
      mainAxisSpacing: 8, // Reduced spacing
      shrinkWrap: true,
      childAspectRatio: 0.9, // Adjust aspect ratio for better fit
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildFeatureCard(
          'Products',
          Icons.inventory,
          () => Navigator.pushNamed(context, ProductManagementScreen.routeName),
        ),
        _buildFeatureCard(
          'Categories',
          Icons.category,
          () =>
              Navigator.pushNamed(context, CategoryManagementScreen.routeName),
        ),
        _buildFeatureCard(
          'Users',
          Icons.people,
          () => Navigator.pushNamed(context, UserManagementScreen.routeName),
        ),
        _buildFeatureCard(
          'Expiring Soon',
          Icons.schedule,
          () => Navigator.pushNamed(context, ExpiringSoonScreen.routeName),
        ),
        _buildFeatureCard(
          'Low Stock',
          Icons.warning_amber,
          () => Navigator.pushNamed(context, LowStockScreen.routeName),
        ),
        _buildFeatureCard(
          'Recommendations',
          Icons.recommend,
          () => Navigator.pushNamed(
            context,
            RecommendationManagementScreen.routeName,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2, // Reduced elevation
      margin: const EdgeInsets.all(4), // Smaller margin
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppBorderRadius.small,
        ), // Smaller radius
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Reduced padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: AppColors.primary,
              ), // Smaller icon without container
              const SizedBox(height: 8), // Reduced spacing
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  // Smaller text
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // New method for quick action menu
  Widget _buildQuickActionMenu() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Quick Actions', style: AppTextStyles.heading2),
            const SizedBox(height: AppPadding.medium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionButton(
                  'Add Product',
                  Icons.add_shopping_cart,
                  () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      ProductManagementScreen.routeName,
                      arguments: {'action': 'add'},
                    );
                  },
                ),
                _buildQuickActionButton(
                  'Add Category',
                  Icons.category_outlined,
                  () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      CategoryManagementScreen.routeName,
                      arguments: {'action': 'add'},
                    );
                  },
                ),
                _buildQuickActionButton('View Orders', Icons.shopping_bag, () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, OrderManagementScreen.routeName);
                }),
                _buildQuickActionButton('Expiring Soon', Icons.schedule, () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, ExpiringSoonScreen.routeName);
                }),
              ],
            ),
            const SizedBox(height: AppPadding.large),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper method to get color based on order status
  Color _getOrderStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'PROCESSING':
        return Colors.blue;
      case 'OUTFORDELIVERY':
        return Colors.purple;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                onTap: () {
                  // Navigate to order details
                  Navigator.pushNamed(
                    context,
                    OrderManagementScreen.routeName,
                    arguments: {'orderId': order.orderId},
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(AppPadding.medium),
                  child: Row(
                    children: [
                      // Order status indicator
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getOrderStatusColor(order.status),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Order details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${order.orderId.length > 8 ? order.orderId.substring(0, 8) : order.orderId}',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Customer: ${order.userName}',
                              style: AppTextStyles.bodySmall,
                            ),
                            Text(
                              'Date: ${DateFormat('MMM d, yyyy').format(order.orderDate)}',
                              style: AppTextStyles.bodySmall,
                            ),
                            Row(
                              children: [
                                Text(
                                  'Status: ',
                                  style: AppTextStyles.bodySmall,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getOrderStatusColor(
                                      order.status,
                                    ).withAlpha(26),
                                    borderRadius: BorderRadius.circular(
                                      AppBorderRadius.small,
                                    ),
                                  ),
                                  child: Text(
                                    order.status,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: _getOrderStatusColor(order.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Order amount
                      Text(
                        '₹${order.amount.toStringAsFixed(2)}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
