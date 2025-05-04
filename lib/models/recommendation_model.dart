import 'package:cloud_firestore/cloud_firestore.dart';

class RecommendedProduct {
  final String productId;
  final String productName;
  final String imageUrl;
  final double price;
  final double? discountPrice;
  final int frequency; // How many times this product was ordered

  RecommendedProduct({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
    this.discountPrice,
    this.frequency = 1,
  });

  factory RecommendedProduct.fromMap(Map<String, dynamic> map) {
    return RecommendedProduct(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      discountPrice:
          map['discountPrice'] != null
              ? (map['discountPrice']).toDouble()
              : null,
      frequency: map['frequency'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'price': price,
      'discountPrice': discountPrice,
      'frequency': frequency,
    };
  }
}

class RecommendationModel {
  final String userId;
  final String userName;
  final List<RecommendedProduct> products;
  final DateTime lastUpdated;
  final bool isGlobal; // Whether this is a global recommendation for all users

  RecommendationModel({
    required this.userId,
    required this.userName,
    required this.products,
    required this.lastUpdated,
    this.isGlobal = false,
  });

  factory RecommendationModel.fromMap(Map<String, dynamic> map, String id) {
    return RecommendationModel(
      userId: id,
      userName: map['userName'] ?? '',
      products: List<RecommendedProduct>.from(
        (map['products'] as List? ?? []).map(
          (product) =>
              RecommendedProduct.fromMap(product as Map<String, dynamic>),
        ),
      ),
      lastUpdated:
          (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isGlobal: map['isGlobal'] ?? false,
    );
  }

  // Create a copy of this recommendation with updated fields
  RecommendationModel copyWith({
    String? userId,
    String? userName,
    List<RecommendedProduct>? products,
    DateTime? lastUpdated,
    bool? isGlobal,
  }) {
    return RecommendationModel(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      products: products ?? this.products,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isGlobal: isGlobal ?? this.isGlobal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'products': products.map((product) => product.toMap()).toList(),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'isGlobal': isGlobal,
    };
  }
}
