import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_kirana/models/cart_item_model.dart';
import 'package:smart_kirana/models/product_model.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/providers/product_provider.dart';

class CartProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthProvider _authProvider;
  final ProductProvider _productProvider;

  List<CartItemModel> _cartItems = [];
  bool _isLoading = false;
  String? _error;
  final double _baseDeliveryFee = 40.0; // Default delivery fee
  final double _freeDeliveryThreshold =
      200.0; // Free delivery above this amount

  CartProvider({
    required AuthProvider authProvider,
    required ProductProvider productProvider,
  }) : _authProvider = authProvider,
       _productProvider = productProvider {
    _loadCart();
  }

  // Getters
  List<CartItemModel> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Calculate delivery fee based on subtotal
  double get deliveryFee {
    return subtotal >= _freeDeliveryThreshold ? 0.0 : _baseDeliveryFee;
  }

  // Calculate subtotal
  double get subtotal {
    return _cartItems.fold(
      0,
      (accumulator, item) => accumulator + item.totalPrice,
    );
  }

  // Calculate total
  double get total {
    return subtotal + (_cartItems.isNotEmpty ? deliveryFee : 0);
  }

  // Load cart from Firestore
  Future<void> _loadCart() async {
    if (_authProvider.currentUser == null) return;

    _setLoading(true);
    try {
      final cartSnapshot =
          await _firestore
              .collection('users')
              .doc(_authProvider.currentUser!.uid)
              .collection('cart')
              .get();

      _cartItems = [];

      for (var doc in cartSnapshot.docs) {
        final data = doc.data();
        final productId = data['productId'];
        final product = _productProvider.getProductById(productId);

        if (product != null) {
          _cartItems.add(CartItemModel.fromMap(data, product));
        }
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to load cart: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Add product to cart
  Future<bool> addToCart(ProductModel product, int quantity) async {
    if (_authProvider.currentUser == null) return false;

    // Check if product is in stock
    if (product.stock <= 0) {
      _setError('Product is out of stock');
      return false;
    }

    // Check if requested quantity is available
    if (quantity > product.stock) {
      _setError('Only ${product.stock} items available in stock');
      return false;
    }

    _setLoading(true);
    try {
      // Check if product already in cart
      final existingIndex = _cartItems.indexWhere(
        (item) => item.product.id == product.id,
      );

      if (existingIndex >= 0) {
        // Calculate new quantity
        final newQuantity = _cartItems[existingIndex].quantity + quantity;

        // Check if new quantity exceeds available stock
        if (newQuantity > product.stock) {
          _setError(
            'Cannot add more items. Only ${product.stock} available in stock',
          );
          _setLoading(false);
          return false;
        }

        // Update quantity if already in cart
        await updateCartItemQuantity(product.id, newQuantity);
      } else {
        // Add new item to cart
        final cartItem = CartItemModel(product: product, quantity: quantity);

        await _firestore
            .collection('users')
            .doc(_authProvider.currentUser!.uid)
            .collection('cart')
            .doc(product.id)
            .set(cartItem.toMap());

        _cartItems.add(cartItem);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to add to cart: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update cart item quantity
  Future<bool> updateCartItemQuantity(String productId, int quantity) async {
    if (_authProvider.currentUser == null) return false;

    // Find the product in cart
    final index = _cartItems.indexWhere((item) => item.product.id == productId);

    if (index >= 0) {
      final product = _cartItems[index].product;

      // Check if requested quantity is available
      if (quantity > product.stock) {
        _setError(
          'Cannot update quantity. Only ${product.stock} available in stock',
        );
        return false;
      }
    } else {
      _setError('Product not found in cart');
      return false;
    }

    _setLoading(true);
    try {
      await _firestore
          .collection('users')
          .doc(_authProvider.currentUser!.uid)
          .collection('cart')
          .doc(productId)
          .update({'quantity': quantity});

      if (index >= 0) {
        _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to update cart: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String productId) async {
    if (_authProvider.currentUser == null) return;

    _setLoading(true);
    try {
      await _firestore
          .collection('users')
          .doc(_authProvider.currentUser!.uid)
          .collection('cart')
          .doc(productId)
          .delete();

      _cartItems.removeWhere((item) => item.product.id == productId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to remove from cart: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    if (_authProvider.currentUser == null) return;

    _setLoading(true);
    try {
      final batch = _firestore.batch();
      final cartSnapshot =
          await _firestore
              .collection('users')
              .doc(_authProvider.currentUser!.uid)
              .collection('cart')
              .get();

      for (var doc in cartSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      _cartItems = [];
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear cart: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Check if product is in cart
  bool isInCart(String productId) {
    return _cartItems.any((item) => item.product.id == productId);
  }

  // Get cart item quantity
  int getCartItemQuantity(String productId) {
    final item = _cartItems.firstWhere(
      (item) => item.product.id == productId,
      orElse:
          () => CartItemModel(
            product: ProductModel(
              id: '',
              name: '',
              description: '',
              price: 0,
              discountPrice: null,
              imageUrl: '',
              categoryId: '',
              categoryName: '',
              stock: 0,
              unit: '',
            ),
            quantity: 0,
          ),
    );
    return item.quantity;
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
}
