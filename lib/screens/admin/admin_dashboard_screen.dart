import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
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
import 'package:smart_kirana/widgets/admin/analytics_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  static const String routeName = '/admin-dashboard';

  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch dashboard data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Check if user is admin
    if (authProvider.user?.role != 'ADMIN') {
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
      appBar: AppBar(title: const Text('Admin Dashboard')),
      drawer: const AdminDrawer(),
      body:
          adminProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : adminProvider.error != null
              ? Center(
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
                      onPressed: () => adminProvider.fetchDashboardData(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: () => adminProvider.fetchDashboardData(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppPadding.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dashboard Overview',
                        style: AppTextStyles.heading1,
                      ),
                      const SizedBox(height: AppPadding.medium),
                      _buildAnalyticsCards(adminProvider.dashboardData),
                      const SizedBox(height: AppPadding.large),
                      _buildCharts(adminProvider.dashboardData),
                      const SizedBox(height: AppPadding.large),
                      _buildRecentOrders(adminProvider.dashboardData),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildAnalyticsCards(AdminDashboardModel data) {
    final currencyFormat = NumberFormat.currency(symbol: '₹');

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppPadding.medium,
      mainAxisSpacing: AppPadding.medium,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        AnalyticsCard(
          title: 'Total Users',
          value: data.totalUsers.toString(),
          icon: Icons.people,
          color: AppColors.primary,
          onTap:
              () =>
                  Navigator.pushNamed(context, UserManagementScreen.routeName),
        ),
        AnalyticsCard(
          title: 'Total Revenue',
          value: currencyFormat.format(data.totalRevenue),
          icon: Icons.currency_rupee,
          color: AppColors.accent,
          onTap: () {},
        ),
        AnalyticsCard(
          title: 'Total Orders',
          value: data.totalOrders.toString(),
          icon: Icons.shopping_bag,
          color: AppColors.secondary,
          onTap:
              () =>
                  Navigator.pushNamed(context, OrderManagementScreen.routeName),
        ),
        AnalyticsCard(
          title: 'Pending Orders',
          value: data.pendingOrders.toString(),
          icon: Icons.pending_actions,
          color: Colors.orange,
          onTap:
              () => Navigator.pushNamed(
                context,
                OrderManagementScreen.routeName,
                arguments: {'filter': 'PENDING'},
              ),
        ),
      ],
    );
  }

  // Flag to enable/disable charts
  bool get enableCharts => true; // or use a runtime flag/provider

  Widget _buildCharts(AdminDashboardModel data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Revenue (Last 7 Days)', style: AppTextStyles.heading2),
        const SizedBox(height: AppPadding.medium),
        Container(
          constraints: const BoxConstraints(
            minHeight: 200,
            minWidth: double.infinity,
          ),
          height: 200,
          padding: const EdgeInsets.all(AppPadding.medium),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          // Use a placeholder instead of the chart
          child:
              enableCharts
                  ? _buildRevenueChart(data.revenueData)
                  : _buildPlaceholderWidget(
                    'Revenue Chart',
                    'Total Revenue: ₹${data.totalRevenue.toStringAsFixed(2)}',
                  ),
        ),
        const SizedBox(height: AppPadding.large),
        const Text('New Users (Last 7 Days)', style: AppTextStyles.heading2),
        const SizedBox(height: AppPadding.medium),
        Container(
          constraints: const BoxConstraints(
            minHeight: 200,
            minWidth: double.infinity,
          ),
          height: 200,
          padding: const EdgeInsets.all(AppPadding.medium),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          // Use a placeholder instead of the chart
          child:
              enableCharts
                  ? _buildUserGrowthChart(data.userGrowthData)
                  : _buildPlaceholderWidget(
                    'User Growth Chart',
                    'Total Users: ${data.totalUsers}',
                  ),
        ),
      ],
    );
  }

  // Simple placeholder widget to replace charts
  Widget _buildPlaceholderWidget(String title, String data) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: AppTextStyles.heading3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            data,
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Charts temporarily disabled',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(List<RevenueData> revenueData) {
    if (revenueData.isEmpty) {
      return const Center(child: Text('No revenue data available'));
    }

    // Calculate max Y value safely
    double maxY = 1.0; // Default value if all amounts are 0
    try {
      final maxAmount = revenueData
          .map((e) => e.amount)
          .reduce((a, b) => a > b ? a : b);
      maxY = maxAmount > 0 ? maxAmount * 1.2 : 1.0;
    } catch (e) {
      // Handle any errors in calculation
      debugPrint('Error calculating maxY: $e');
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final date = revenueData[groupIndex].date;
              final amount = revenueData[groupIndex].amount;
              return BarTooltipItem(
                '${DateFormat('MMM d').format(date)}\n₹${amount.toStringAsFixed(2)}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < revenueData.length) {
                  final date = revenueData[value.toInt()].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('E').format(date),
                      style: AppTextStyles.bodySmall,
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '₹${value.toInt()}',
                    style: AppTextStyles.bodySmall,
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: _calculateHorizontalInterval(revenueData),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withAlpha(51),
              strokeWidth: 1,
            ); // 0.2 * 255 = 51
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: _createBarGroups(revenueData),
      ),
    );
  }

  // Helper method to create bar groups with error handling
  List<BarChartGroupData> _createBarGroups(List<RevenueData> revenueData) {
    try {
      return revenueData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        // Ensure amount is not negative and is a double
        final amount = data.amount < 0 ? 0.0 : data.amount.toDouble();

        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: amount,
              color: AppColors.primary,
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppBorderRadius.small),
                topRight: Radius.circular(AppBorderRadius.small),
              ),
            ),
          ],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error creating bar groups: $e');
      // Return a single empty bar if there's an error
      return [
        BarChartGroupData(
          x: 0,
          barRods: [
            BarChartRodData(
              toY: 0,
              color: AppColors.primary,
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppBorderRadius.small),
                topRight: Radius.circular(AppBorderRadius.small),
              ),
            ),
          ],
        ),
      ];
    }
  }

  // Helper method to calculate horizontal interval for charts
  double _calculateHorizontalInterval(List<RevenueData> revenueData) {
    // If the list is empty, return a default value
    if (revenueData.isEmpty) {
      return 1.0;
    }

    try {
      // Get the maximum amount
      final maxAmount = revenueData
          .map((e) => e.amount)
          .reduce((a, b) => a > b ? a : b);

      // If max amount is 0 or very small, return a default value
      if (maxAmount <= 0) {
        return 1.0; // Default interval when there's no revenue
      }

      // Otherwise, calculate a reasonable interval
      return maxAmount / 5;
    } catch (e) {
      debugPrint('Error calculating horizontal interval: $e');
      return 1.0; // Default value in case of error
    }
  }

  // Helper method to calculate horizontal interval for user growth chart
  double _calculateUserGrowthInterval(List<UserGrowthData> userGrowthData) {
    // If the list is empty, return a default value
    if (userGrowthData.isEmpty) {
      return 1.0;
    }

    try {
      // Get the maximum count
      final maxCount = userGrowthData
          .map((e) => e.count)
          .reduce((a, b) => a > b ? a : b);

      // If max count is 0 or very small, return a default value
      if (maxCount <= 0) {
        return 1.0; // Default interval when there are no users
      }

      // Otherwise, calculate a reasonable interval
      return maxCount / 5;
    } catch (e) {
      debugPrint('Error calculating user growth interval: $e');
      return 1.0; // Default value in case of error
    }
  }

  Widget _buildUserGrowthChart(List<UserGrowthData> userGrowthData) {
    if (userGrowthData.isEmpty) {
      return const Center(child: Text('No user growth data available'));
    }

    // Ensure we have valid data points
    if (userGrowthData.length < 2) {
      return const Center(child: Text('Insufficient data for chart'));
    }

    // Ensure all spots have valid values
    final spots =
        userGrowthData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          return FlSpot(index.toDouble(), data.count.toDouble());
        }).toList();

    // Check if we have any valid spots
    if (spots.isEmpty) {
      return const Center(child: Text('No valid data points'));
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date = userGrowthData[spot.x.toInt()].date;
                return LineTooltipItem(
                  '${DateFormat('MMM d').format(date)}\n${spot.y.toInt()} users',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 &&
                    value.toInt() < userGrowthData.length) {
                  final date = userGrowthData[value.toInt()].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('E').format(date),
                      style: AppTextStyles.bodySmall,
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: AppTextStyles.bodySmall,
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: _calculateUserGrowthInterval(userGrowthData),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withAlpha(51),
              strokeWidth: 1,
            ); // 0.2 * 255 = 51
          },
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.secondary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.secondary.withAlpha(51), // 0.2 * 255 = 51
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders(AdminDashboardModel data) {
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
        const SizedBox(height: AppPadding.small),
        if (data.recentOrders.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppPadding.large),
              child: Text('No recent orders'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.recentOrders.length,
            itemBuilder: (context, index) {
              final order = data.recentOrders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppPadding.medium),
                child: ListTile(
                  title: Text(
                    'Order #${order.orderId.substring(0, 8)}',
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
