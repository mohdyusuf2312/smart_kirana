import 'package:smart_kirana/models/product_model.dart';

class CartItemModel {
  final ProductModel product;
  final int quantity;

  CartItemModel({required this.product, required this.quantity});

  factory CartItemModel.fromMap(
    Map<String, dynamic> map,
    ProductModel product,
  ) {
    return CartItemModel(product: product, quantity: map['quantity'] ?? 1);
  }

  Map<String, dynamic> toMap() {
    return {'productId': product.id, 'quantity': quantity};
  }

  CartItemModel copyWith({ProductModel? product, int? quantity}) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  double get totalPrice {
    final price =
        product.discountPrice > 0 ? product.discountPrice : product.price;
    return price * quantity;
  }
}
