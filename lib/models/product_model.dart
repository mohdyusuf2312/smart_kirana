class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final String imageUrl;
  final String categoryId;
  final String categoryName;
  final int stock;
  final String unit;
  final bool isPopular;
  final bool isFeatured;
  final DateTime? expiryDate;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.imageUrl,
    required this.categoryId,
    required this.categoryName,
    required this.stock,
    required this.unit,
    this.isPopular = false,
    this.isFeatured = false,
    this.expiryDate,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      discountPrice:
          map['discountPrice'] != null
              ? (map['discountPrice']).toDouble()
              : null,
      imageUrl: map['imageUrl'] ?? '',
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      stock: map['stock'] ?? 0,
      unit: map['unit'] ?? '',
      isPopular: map['isPopular'] ?? false,
      isFeatured: map['isFeatured'] ?? false,
      expiryDate:
          map['expiryDate'] != null
              ? (map['expiryDate'] as dynamic).toDate()
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'stock': stock,
      'unit': unit,
      'isPopular': isPopular,
      'isFeatured': isFeatured,
      'expiryDate': expiryDate,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? discountPrice,
    String? imageUrl,
    String? categoryId,
    String? categoryName,
    int? stock,
    String? unit,
    bool? isPopular,
    bool? isFeatured,
    DateTime? expiryDate,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      isPopular: isPopular ?? this.isPopular,
      isFeatured: isFeatured ?? this.isFeatured,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }

  // Helper method to check if product is expiring soon (within 30 days)
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    final difference = expiryDate!.difference(now).inDays;
    return difference >= 0 && difference <= 30;
  }

  // Helper method to get days until expiry
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    final now = DateTime.now();
    return expiryDate!.difference(now).inDays;
  }

  // Helper method to check if product is expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }
}
