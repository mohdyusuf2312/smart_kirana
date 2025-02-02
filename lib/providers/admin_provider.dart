import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  AdminProvider({required AuthProvider authProvider}) : _authProvider = authProvider;

  // Check if current user is admin
  bool get isAdmin {
    return _authProvider.user?.role == 'ADMIN';
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
      // Fetch total users
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;

      // Fetch orders data
      final ordersSnapshot = await _firestore.collection('orders').get();
      final orders = ordersSnapshot.docs;
      final totalOrders = orders.length;
      
      // Calculate revenue and order status counts
      double totalRevenue = 0;
      int pendingOrders = 0;
      int completedOrders = 0;
      int cancelledOrders = 0;

      for (var order in orders) {
        final orderData = order.data();
        totalRevenue += (orderData['totalAmount'] ?? 0).toDouble();
        
        switch (orderData['status']) {
          case 'PENDING':
          case 'PROCESSING':
          case 'SHIPPED':
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

      // Get recent orders (last 10)
      final recentOrdersSnapshot = await _firestore
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .limit(10)
          .get();
      
      final recentOrders = recentOrdersSnapshot.docs
          .map((doc) => OrderAnalytics.fromMap(doc.data(), doc.id))
          .toList();

      // Generate revenue data for the last 7 days
      final revenueData = await _generateRevenueData();
      
      // Generate user growth data for the last 7 days
      final userGrowthData = await _generateUserGrowthData();

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
    } catch (e) {
      _setError('Failed to fetch dashboard data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Generate revenue data for the last 7 days
  Future<List<RevenueData>> _generateRevenueData() async {
    List<RevenueData> revenueData = [];
    
    // Get today's date
    final now = DateTime.now();
    
    // Generate data for the last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final nextDate = DateTime(now.year, now.month, now.day - i + 1);
      
      // Query orders for this day
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(date))
          .where('orderDate', isLessThan: Timestamp.fromDate(nextDate))
          .get();
      
      // Calculate total revenue for this day
      double dailyRevenue = 0;
      for (var order in ordersSnapshot.docs) {
        dailyRevenue += (order.data()['totalAmount'] ?? 0).toDouble();
      }
      
      revenueData.add(RevenueData(date: date, amount: dailyRevenue));
    }
    
    return revenueData;
  }

  // Generate user growth data for the last 7 days
  Future<List<UserGrowthData>> _generateUserGrowthData() async {
    List<UserGrowthData> userGrowthData = [];
    
    // Get today's date
    final now = DateTime.now();
    
    // Generate data for the last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final nextDate = DateTime(now.year, now.month, now.day - i + 1);
      
      // Query users created on this day
      final usersSnapshot = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(date))
          .where('createdAt', isLessThan: Timestamp.fromDate(nextDate))
          .get();
      
      userGrowthData.add(UserGrowthData(
        date: date,
        count: usersSnapshot.docs.length,
      ));
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
