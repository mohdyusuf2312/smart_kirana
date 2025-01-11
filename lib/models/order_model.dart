import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_kirana/models/cart_item_model.dart';

enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled,
}

class OrderItem {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final double totalPrice;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.totalPrice,
  });

  factory OrderItem.fromCartItem(CartItemModel cartItem) {
    return OrderItem(
      productId: cartItem.product.id,
      productName: cartItem.product.name,
      productImage: cartItem.product.imageUrl,
      price: cartItem.product.discountPrice > 0
          ? cartItem.product.discountPrice
          : cartItem.product.price,
      quantity: cartItem.quantity,
      totalPrice: cartItem.totalPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 0,
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
    );
  }
}

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double totalAmount;
  final DateTime orderDate;
  final OrderStatus status;
  final Map<String, dynamic> deliveryAddress;
  final String paymentMethod;
  final String? deliveryNotes;
  final DateTime? estimatedDeliveryTime;
  final String userName;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final double? currentLatitude;
  final double? currentLongitude;
  final String? deliveryAgentName;
  final String? deliveryAgentPhone;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.totalAmount,
    required this.orderDate,
    required this.status,
    required this.deliveryAddress,
    required this.paymentMethod,
    this.deliveryNotes,
    this.estimatedDeliveryTime,
    required this.userName,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.currentLatitude,
    this.currentLongitude,
    this.deliveryAgentName,
    this.deliveryAgentPhone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'totalAmount': totalAmount,
      'orderDate': Timestamp.fromDate(orderDate),
      'status': status.name,
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
      'deliveryNotes': deliveryNotes,
      'estimatedDeliveryTime': estimatedDeliveryTime != null
          ? Timestamp.fromDate(estimatedDeliveryTime!)
          : null,
      'userName': userName,
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,
      'deliveryAgentName': deliveryAgentName,
      'deliveryAgentPhone': deliveryAgentPhone,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String docId) {
    return OrderModel(
      id: docId,
      userId: map['userId'] ?? '',
      items: List<OrderItem>.from(
        (map['items'] as List? ?? []).map(
          (item) => OrderItem.fromMap(item as Map<String, dynamic>),
        ),
      ),
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      deliveryFee: (map['deliveryFee'] ?? 0.0).toDouble(),
      discount: (map['discount'] ?? 0.0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      orderDate: (map['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      deliveryAddress: Map<String, dynamic>.from(map['deliveryAddress'] ?? {}),
      paymentMethod: map['paymentMethod'] ?? 'Cash on Delivery',
      deliveryNotes: map['deliveryNotes'],
      estimatedDeliveryTime:
          (map['estimatedDeliveryTime'] as Timestamp?)?.toDate(),
      userName: map['userName'] ?? '',
      deliveryLatitude: map['deliveryLatitude'],
      deliveryLongitude: map['deliveryLongitude'],
      currentLatitude: map['currentLatitude'],
      currentLongitude: map['currentLongitude'],
      deliveryAgentName: map['deliveryAgentName'],
      deliveryAgentPhone: map['deliveryAgentPhone'],
    );
  }
}
