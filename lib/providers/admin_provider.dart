import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:smart_kirana/models/admin_dashboard_model.dart';
import 'package:smart_kirana/models/category_model.dart';
import 'package:smart_kirana/models/order_model.dart';
import 'package:smart_kirana/models/product_model.dart';
import 'package:smart_kirana/models/user_model.dart';
import 'package:smart_kirana/providers/auth_provider.dart';

class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthProvider _authProvider;

  AdminDashboardModel _dashboardData = AdminDashboardModel.empty();
  bool _isLoading = false;
  String? _error;

  // Getters
  AdminDashboardModel get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AdminProvider({required AuthProvider authProvider})
    : _authProvider = authProvider;

  // Check if current user is admin
  bool get isAdmin {
    final isAdmin = _authProvider.user?.role == 'ADMIN';
    debugPrint('User is admin: $isAdmin');
    return isAdmin;
  }

  // Fetch dashboard data
  Future<void> fetchDashboardData() async {
    if (!isAdmin) {
      _setError('Unauthorized access');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      // Initialize with default values in case of partial failures
      int totalUsers = 0;
      int totalOrders = 0;
      double totalRevenue = 0;
      int pendingOrders = 0;
      int completedOrders = 0;
      int cancelledOrders = 0;
      List<OrderAnalytics> recentOrders = [];
      List<RevenueData> revenueData = [];
      List<UserGrowthData> userGrowthData = [];

      // Fetch total users with error handling
      try {
        final usersSnapshot = await _firestore.collection('users').get();
        totalUsers = usersSnapshot.docs.length;
        debugPrint('Fetched $totalUsers users');
      } catch (e) {
        debugPrint('Error fetching users: $e');
        // Continue with default value
      }

      // Fetch orders data with error handling
      try {
        final ordersSnapshot = await _firestore.collection('orders').get();
        final orders = ordersSnapshot.docs;
        totalOrders = orders.length;
        debugPrint('Fetched $totalOrders orders');

        // Calculate revenue and order status counts
        for (var order in orders) {
          final orderData = order.data();
          final amount = orderData['totalAmount'];
          if (amount != null) {
            // Ensure amount is properly converted to double
            if (amount is int) {
              totalRevenue += amount.toDouble();
            } else if (amount is double) {
              totalRevenue += amount;
            } else {
              try {
                totalRevenue += double.parse(amount.toString());
              } catch (e) {
                debugPrint('Error parsing amount: $e');
              }
            }
          }

          final status = orderData['status'] as String?;
          if (status != null) {
            switch (status.toUpperCase()) {
              case 'PENDING':
                pendingOrders++;
                break;
              case 'PROCESSING':
              case 'SHIPPED':
                // These are also considered pending but tracked separately
                pendingOrders++;
                break;
              case 'DELIVERED':
                completedOrders++;
                break;
              case 'CANCELLED':
                cancelledOrders++;
                break;
            }
          }
        }
        debugPrint('Calculated revenue: $totalRevenue');
      } catch (e) {
        debugPrint('Error fetching orders: $e');
        // Continue with default values
      }

      // Get recent orders (last 10) with error handling
      try {
        final recentOrdersSnapshot =
            await _firestore
                .collection('orders')
                .orderBy('orderDate', descending: true)
                .limit(10)
                .get();

        recentOrders =
            recentOrdersSnapshot.docs
                .map((doc) {
                  try {
                    return OrderAnalytics.fromMap(doc.data(), doc.id);
                  } catch (e) {
                    debugPrint('Error parsing order ${doc.id}: $e');
                    return null;
                  }
                })
                .where((order) => order != null)
                .cast<OrderAnalytics>()
                .toList();
        debugPrint('Fetched ${recentOrders.length} recent orders');
      } catch (e) {
        debugPrint('Error fetching recent orders: $e');
        // Continue with empty list
      }

      // Generate revenue data for the last 7 days
      try {
        revenueData = await _generateRevenueData();
        debugPrint('Generated revenue data: ${revenueData.length} entries');
      } catch (e) {
        debugPrint('Error generating revenue data: $e');
        // Continue with empty list
      }

      // Generate user growth data for the last 7 days
      try {
        userGrowthData = await _generateUserGrowthData();
        debugPrint(
          'Generated user growth data: ${userGrowthData.length} entries',
        );
      } catch (e) {
        debugPrint('Error generating user growth data: $e');
        // Continue with empty list
      }

      // Update dashboard data
      _dashboardData = AdminDashboardModel(
        totalUsers: totalUsers,
        totalOrders: totalOrders,
        totalRevenue: totalRevenue,
        pendingOrders: pendingOrders,
        completedOrders: completedOrders,
        cancelledOrders: cancelledOrders,
        recentOrders: recentOrders,
        revenueData: revenueData,
        userGrowthData: userGrowthData,
      );

      notifyListeners();
      debugPrint('Dashboard data updated successfully');
    } catch (e) {
      debugPrint('Failed to fetch dashboard data: $e');
      _setError('Failed to fetch dashboard data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Generate revenue data for the last 7 days
  Future<List<RevenueData>> _generateRevenueData() async {
    List<RevenueData> revenueData = [];

    try {
      // Get today's date
      final now = DateTime.now();

      // Generate data for the last 7 days
      for (int i = 6; i >= 0; i--) {
        final date = DateTime(now.year, now.month, now.day - i);
        final nextDate = DateTime(now.year, now.month, now.day - i + 1);

        try {
          // Query orders for this day
          final ordersSnapshot =
              await _firestore
                  .collection('orders')
                  .where(
                    'orderDate',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(date),
                  )
                  .where('orderDate', isLessThan: Timestamp.fromDate(nextDate))
                  .get();

          // Calculate total revenue for this day
          double dailyRevenue = 0;
          for (var order in ordersSnapshot.docs) {
            dailyRevenue += (order.data()['totalAmount'] ?? 0).toDouble();
          }

          revenueData.add(RevenueData(date: date, amount: dailyRevenue));
        } catch (e) {
          // If there's an error for a specific day, add zero revenue
          debugPrint('Error fetching revenue data for day $i: $e');
          revenueData.add(RevenueData(date: date, amount: 0));
        }
      }
    } catch (e) {
      debugPrint('Error generating revenue data: $e');
      // Return empty data in case of error
      final now = DateTime.now();
      for (int i = 6; i >= 0; i--) {
        final date = DateTime(now.year, now.month, now.day - i);
        revenueData.add(RevenueData(date: date, amount: 0));
      }
    }

    return revenueData;
  }

  // Generate user growth data for the last 7 days
  Future<List<UserGrowthData>> _generateUserGrowthData() async {
    List<UserGrowthData> userGrowthData = [];

    try {
      // Get today's date
      final now = DateTime.now();

      // Generate data for the last 7 days
      for (int i = 6; i >= 0; i--) {
        final date = DateTime(now.year, now.month, now.day - i);
        final nextDate = DateTime(now.year, now.month, now.day - i + 1);

        try {
          // Query users created on this day
          final usersSnapshot =
              await _firestore
                  .collection('users')
                  .where(
                    'createdAt',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(date),
                  )
                  .where('createdAt', isLessThan: Timestamp.fromDate(nextDate))
                  .get();

          userGrowthData.add(
            UserGrowthData(date: date, count: usersSnapshot.docs.length),
          );
        } catch (e) {
          // If there's an error for a specific day, add zero count
          debugPrint('Error fetching user growth data for day $i: $e');
          userGrowthData.add(UserGrowthData(date: date, count: 0));
        }
      }
    } catch (e) {
      debugPrint('Error generating user growth data: $e');
      // Return empty data in case of error
      final now = DateTime.now();
      for (int i = 6; i >= 0; i--) {
        final date = DateTime(now.year, now.month, now.day - i);
        userGrowthData.add(UserGrowthData(date: date, count: 0));
      }
    }

    return userGrowthData;
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
