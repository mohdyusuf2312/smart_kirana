import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_kirana/models/cart_item_model.dart';
import 'package:smart_kirana/models/order_model.dart';
import 'package:smart_kirana/models/user_model.dart';
import 'package:smart_kirana/services/recommendation_service.dart';
import 'package:smart_kirana/services/route_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RecommendationService _recommendationService = RecommendationService();
  final RouteService _routeService = RouteService();

  // Create a new order
  Future<String> createOrder({
    required String userId,
    required List<CartItemModel> cartItems,
    required double subtotal,
    required double deliveryFee,
    required double discount,
    required double totalAmount,
    required UserAddress deliveryAddress,
    required String paymentMethod,
    required String userName,
    String? deliveryNotes,
    double? currentLatitude,
    double? currentLongitude,
  }) async {
    try {
      // Validate stock availability before proceeding
      for (var item in cartItems) {
        // Get the latest product data to ensure stock is current
        final productDoc =
            await _firestore.collection('products').doc(item.product.id).get();

        if (!productDoc.exists) {
          throw Exception(
            'Product ${item.product.name} is no longer available',
          );
        }

        final currentStock = productDoc.data()?['stock'] ?? 0;

        if (currentStock < item.quantity) {
          throw Exception(
            'Not enough stock for ${item.product.name}. Available: $currentStock, Requested: ${item.quantity}',
          );
        }
      }

      // Convert cart items to order items
      final orderItems =
          cartItems.map((item) => OrderItem.fromCartItem(item)).toList();

      // Calculate route if both current location and delivery address are available
      RouteInfo? routeInfo;
      DateTime estimatedDeliveryTime = DateTime.now().add(
        const Duration(hours: 2),
      );

      if (currentLatitude != null && currentLongitude != null) {
        try {
          routeInfo = await _routeService.calculateRoute(
            origin: LatLng(currentLatitude, currentLongitude),
            destination: LatLng(
              deliveryAddress.latitude,
              deliveryAddress.longitude,
            ),
          );

          if (routeInfo != null) {
            // Calculate more accurate delivery time based on route
            estimatedDeliveryTime = DateTime.now().add(
              Duration(
                seconds: routeInfo.durationValue + (15 * 60),
              ), // Add 15 min prep time
            );
          }
        } catch (e) {
          // Continue with default delivery time if route calculation fails
        }
      }

      // Create order document
      final orderRef = _firestore.collection('orders').doc();

      final order = OrderModel(
        id: orderRef.id,
        userId: userId,
        items: orderItems,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        discount: discount,
        totalAmount: totalAmount,
        orderDate: DateTime.now(),
        status: OrderStatus.pending,
        deliveryAddress: deliveryAddress.toMap(),
        paymentMethod: paymentMethod,
        deliveryNotes: deliveryNotes,
        userName: userName,
        estimatedDeliveryTime: estimatedDeliveryTime,
        deliveryLatitude: deliveryAddress.latitude,
        deliveryLongitude: deliveryAddress.longitude,
        currentLatitude: currentLatitude,
        currentLongitude: currentLongitude,
      );

      // Use a batch to ensure all operations succeed or fail together
      final batch = _firestore.batch();

      // Prepare order data with route information
      final orderData = order.toMap();
      if (routeInfo != null) {
        orderData['routeInfo'] = routeInfo.toMap();
      }

      // Add the order
      batch.set(orderRef, orderData);

      // Update product stock for each item
      for (var item in cartItems) {
        final productRef = _firestore
            .collection('products')
            .doc(item.product.id);

        // Decrement the stock by the ordered quantity
        batch.update(productRef, {
          'stock': FieldValue.increment(-item.quantity),
        });
      }

      // Commit the batch
      await batch.commit();

      // Note: We're not refreshing product data here because the real-time listeners
      // in ProductProvider will automatically update when Firestore changes

      // Generate recommendations based on this new order
      try {
        await _recommendationService.generateRecommendationsAfterOrder(
          userId,
          userName,
          order,
        );
      } catch (e) {
        // Don't fail the order creation if recommendation generation fails
      }

      return orderRef.id;
    } catch (e) {
      throw Exception('Failed to create order: ${e.toString()}');
    }
  }

  // Get all orders for a user
  Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('orders')
              .where('userId', isEqualTo: userId)
              .orderBy('orderDate', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user orders: ${e.toString()}');
    }
  }

  // Get a specific order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final docSnapshot =
          await _firestore.collection('orders').doc(orderId).get();

      if (!docSnapshot.exists) {
        return null;
      }

      return OrderModel.fromMap(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to get order: ${e.toString()}');
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status.name,
      });
    } catch (e) {
      throw Exception('Failed to update order status: ${e.toString()}');
    }
  }

  // Update order tracking information
  Future<void> updateOrderTracking({
    required String orderId,
    double? currentLatitude,
    double? currentLongitude,
    String? deliveryAgentName,
    String? deliveryAgentPhone,
    DateTime? estimatedDeliveryTime,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};

      if (currentLatitude != null) {
        updateData['currentLatitude'] = currentLatitude;
      }

      if (currentLongitude != null) {
        updateData['currentLongitude'] = currentLongitude;
      }

      if (deliveryAgentName != null) {
        updateData['deliveryAgentName'] = deliveryAgentName;
      }

      if (deliveryAgentPhone != null) {
        updateData['deliveryAgentPhone'] = deliveryAgentPhone;
      }

      if (estimatedDeliveryTime != null) {
        updateData['estimatedDeliveryTime'] = Timestamp.fromDate(
          estimatedDeliveryTime,
        );
      }

      if (updateData.isNotEmpty) {
        await _firestore.collection('orders').doc(orderId).update(updateData);
      }
    } catch (e) {
      throw Exception('Failed to update order tracking: ${e.toString()}');
    }
  }

  // Cancel an order
  Future<void> cancelOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.cancelled.name,
      });
    } catch (e) {
      throw Exception('Failed to cancel order: ${e.toString()}');
    }
  }

  // Update order payment information
  Future<void> updateOrderPaymentInfo({
    required String orderId,
    required String paymentId,
    required PaymentStatus paymentStatus,
    String? transactionId,
    String? paymentMethod,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'paymentStatus': paymentStatus.name,
        'paymentId': paymentId,
      };

      if (transactionId != null) {
        updateData['transactionId'] = transactionId;
      }

      if (paymentMethod != null) {
        updateData['paymentMethod'] = paymentMethod;
      }

      await _firestore.collection('orders').doc(orderId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update order payment info: ${e.toString()}');
    }
  }
}
