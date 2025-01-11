import 'package:flutter/material.dart';
import 'package:smart_kirana/models/cart_item_model.dart';
import 'package:smart_kirana/models/order_model.dart';
import 'package:smart_kirana/models/user_model.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();
  final AuthProvider _authProvider;

  List<OrderModel> _orders = [];
  OrderModel? _selectedOrder;
  bool _isLoading = false;
  String? _error;

  OrderProvider({required AuthProvider authProvider}) : _authProvider = authProvider {
    _loadOrders();
  }

  // Getters
  List<OrderModel> get orders => _orders;
  OrderModel? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all orders for the current user
  Future<void> _loadOrders() async {
    if (_authProvider.currentUser == null) return;

    _setLoading(true);
    try {
      _orders = await _orderService.getUserOrders(_authProvider.currentUser!.uid);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load orders: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Refresh orders
  Future<void> refreshOrders() async {
    await _loadOrders();
  }

  // Get order by ID
  Future<void> getOrderById(String orderId) async {
    _setLoading(true);
    try {
      final order = await _orderService.getOrderById(orderId);
      if (order != null) {
        _selectedOrder = order;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to get order: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Create a new order
  Future<String?> createOrder({
    required List<CartItemModel> cartItems,
    required double subtotal,
    required double deliveryFee,
    required double discount,
    required double totalAmount,
    required UserAddress deliveryAddress,
    required String paymentMethod,
    String? deliveryNotes,
  }) async {
    if (_authProvider.currentUser == null || _authProvider.userData == null) {
      _setError('User not authenticated');
      return null;
    }

    _setLoading(true);
    try {
      final orderId = await _orderService.createOrder(
        userId: _authProvider.currentUser!.uid,
        cartItems: cartItems,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        discount: discount,
        totalAmount: totalAmount,
        deliveryAddress: deliveryAddress,
        paymentMethod: paymentMethod,
        userName: _authProvider.userData!.name,
        deliveryNotes: deliveryNotes,
      );

      // Refresh orders list
      await _loadOrders();
      
      return orderId;
    } catch (e) {
      _setError('Failed to create order: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Cancel an order
  Future<bool> cancelOrder(String orderId) async {
    _setLoading(true);
    try {
      await _orderService.cancelOrder(orderId);
      
      // Update local order status
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index >= 0) {
        final updatedOrder = OrderModel.fromMap(
          {..._orders[index].toMap(), 'status': OrderStatus.cancelled.name},
          _orders[index].id,
        );
        _orders[index] = updatedOrder;
        
        // If this is the selected order, update it too
        if (_selectedOrder?.id == orderId) {
          _selectedOrder = updatedOrder;
        }
        
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Failed to cancel order: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
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

  void clearSelectedOrder() {
    _selectedOrder = null;
    notifyListeners();
  }
}
