import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:smart_kirana/models/admin_dashboard_model.dart';
import 'package:smart_kirana/utils/constants.dart';

class DashboardCharts extends StatefulWidget {
  final AdminDashboardModel data;

  const DashboardCharts({Key? key, required this.data}) : super(key: key);

  @override
  State<DashboardCharts> createState() => _DashboardChartsState();
}

class _DashboardChartsState extends State<DashboardCharts>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Analytics', style: AppTextStyles.heading2),
        const SizedBox(height: AppPadding.small),

        // Tab bar for switching between charts
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Revenue'), Tab(text: 'User Growth')],
        ),

        const SizedBox(height: AppPadding.medium),

        // Chart container
        SizedBox(
          height: 300,
          child: TabBarView(
            controller: _tabController,
            children: [_buildRevenueChart(), _buildUserGrowthChart()],
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    final revenueData = widget.data.revenueData;

    if (revenueData.isEmpty) {
      return _buildPlaceholderWidget(
        'No Revenue Data',
        'No data available for the selected period',
      );
    }

    // Check if all revenue values are zero
    bool allZero = true;
    for (var data in revenueData) {
      if (data.amount > 0) {
        allZero = false;
        break;
      }
    }

    if (allZero) {
      return _buildPlaceholderWidget(
        'No Revenue',
        'No revenue recorded in the selected period',
      );
    }

    // Calculate max Y value safely
    double maxY = 1.0; // Default value if all amounts are 0
    try {
      final maxAmount = revenueData
          .map((e) => e.amount)
          .reduce((a, b) => a > b ? a : b);
      maxY = maxAmount > 0 ? maxAmount * 1.2 : 1.0;
    } catch (e) {
      debugPrint('Error calculating maxY: $e');
      return _buildPlaceholderWidget('Error', 'Could not render revenue chart');
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Revenue (Last 7 Days)', style: AppTextStyles.heading3),
            const SizedBox(height: AppPadding.medium),
            Expanded(
              child: BarChart(
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
                          if (value.toInt() >= 0 &&
                              value.toInt() < revenueData.length) {
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
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: _calculateHorizontalInterval(
                      revenueData,
                    ),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withAlpha(51),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _createBarGroups(revenueData),
                ),
              ),
            ),
          ],
        ),
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
    if (revenueData.isEmpty) {
      return 1.0;
    }

    try {
      final maxAmount = revenueData
          .map((e) => e.amount)
          .reduce((a, b) => a > b ? a : b);

      if (maxAmount <= 0) {
        return 1.0;
      }

      return maxAmount / 5;
    } catch (e) {
      debugPrint('Error calculating horizontal interval: $e');
      return 1.0;
    }
  }

  Widget _buildUserGrowthChart() {
    final userGrowthData = widget.data.userGrowthData;

    if (userGrowthData.isEmpty) {
      return _buildPlaceholderWidget(
        'No User Data',
        'No user growth data available',
      );
    }

    if (userGrowthData.length < 2) {
      return _buildPlaceholderWidget(
        'Insufficient Data',
        'Need at least 2 data points for chart',
      );
    }

    // Check if all user count values are zero
    bool allZero = true;
    for (var data in userGrowthData) {
      if (data.count > 0) {
        allZero = false;
        break;
      }
    }

    if (allZero) {
      return _buildPlaceholderWidget(
        'No User Growth',
        'No new users in the selected period',
      );
    }

    List<FlSpot> spots = [];
    try {
      spots =
          userGrowthData.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            return FlSpot(index.toDouble(), data.count.toDouble());
          }).toList();
    } catch (e) {
      debugPrint('Error creating spots for user growth chart: $e');
      return _buildPlaceholderWidget(
        'Error',
        'Could not render user growth chart',
      );
    }

    if (spots.isEmpty) {
      return _buildPlaceholderWidget(
        'No Data Points',
        'Could not generate chart data',
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Users (Last 7 Days)',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppPadding.medium),
            Expanded(
              child: LineChart(
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
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: _calculateUserGrowthInterval(
                      userGrowthData,
                    ),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withAlpha(51),
                        strokeWidth: 1,
                      );
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
                        color: AppColors.secondary.withAlpha(51),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to calculate horizontal interval for user growth chart
  double _calculateUserGrowthInterval(List<UserGrowthData> userGrowthData) {
    if (userGrowthData.isEmpty) {
      return 1.0;
    }

    try {
      final maxCount = userGrowthData
          .map((e) => e.count)
          .reduce((a, b) => a > b ? a : b);

      if (maxCount <= 0) {
        return 1.0;
      }

      return maxCount / 5;
    } catch (e) {
      debugPrint('Error calculating user growth interval: $e');
      return 1.0;
    }
  }

  // Placeholder widget for charts when data is not available
  Widget _buildPlaceholderWidget(String title, String message) {
    return Card(
      elevation: 2,
      child: Center(
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
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
