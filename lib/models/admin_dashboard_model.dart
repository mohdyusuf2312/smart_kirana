import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardModel {
  final int totalUsers;
  final int totalOrders;
  final double totalRevenue;
  final int pendingOrders;
  final int completedOrders;
  final int cancelledOrders;
  final List<OrderAnalytics> recentOrders;
  final List<RevenueData> revenueData;
  final List<UserGrowthData> userGrowthData;

  AdminDashboardModel({
    required this.totalUsers,
    required this.totalOrders,
    required this.totalRevenue,
    required this.pendingOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.recentOrders,
    required this.revenueData,
    required this.userGrowthData,
  });

  factory AdminDashboardModel.empty() {
    return AdminDashboardModel(
      totalUsers: 0,
      totalOrders: 0,
      totalRevenue: 0.0,
      pendingOrders: 0,
      completedOrders: 0,
      cancelledOrders: 0,
      recentOrders: [],
      revenueData: [],
      userGrowthData: [],
    );
  }
}

class OrderAnalytics {
  final String orderId;
  final String userId;
  final String userName;
  final double amount;
  final DateTime orderDate;
  final String status;

  OrderAnalytics({
    required this.orderId,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.orderDate,
    required this.status,
  });

  factory OrderAnalytics.fromMap(Map<String, dynamic> map, String id) {
    return OrderAnalytics(
      orderId: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      amount: (map['totalAmount'] ?? 0.0).toDouble(),
      orderDate: map['orderDate'] != null
          ? (map['orderDate'] as Timestamp).toDate()
          : DateTime.now(),
      status: map['status'] ?? '',
    );
  }
}

class RevenueData {
  final DateTime date;
  final double amount;

  RevenueData({
    required this.date,
    required this.amount,
  });
}

class UserGrowthData {
  final DateTime date;
  final int count;

  UserGrowthData({
    required this.date,
    required this.count,
  });
}
