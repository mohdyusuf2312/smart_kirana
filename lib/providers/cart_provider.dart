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
  final double _deliveryFee = 40.0; // Default delivery fee

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
  double get deliveryFee => _deliveryFee;

  // Calculate subtotal
  double get subtotal {
    return _cartItems.fold(
      0,
      (accumulator, item) => accumulator + item.totalPrice,
    );
  }

  // Calculate total
  double get total {
    return subtotal + (_cartItems.isNotEmpty ? _deliveryFee : 0);
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
  Future<void> addToCart(ProductModel product, int quantity) async {
    if (_authProvider.currentUser == null) return;

    _setLoading(true);
    try {
      // Check if product already in cart
      final existingIndex = _cartItems.indexWhere(
        (item) => item.product.id == product.id,
      );

      if (existingIndex >= 0) {
        // Update quantity if already in cart
        await updateCartItemQuantity(
          product.id,
          _cartItems[existingIndex].quantity + quantity,
        );
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
    } catch (e) {
      _setError('Failed to add to cart: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update cart item quantity
  Future<void> updateCartItemQuantity(String productId, int quantity) async {
    if (_authProvider.currentUser == null) return;

    _setLoading(true);
    try {
      await _firestore
          .collection('users')
          .doc(_authProvider.currentUser!.uid)
          .collection('cart')
          .doc(productId)
          .update({'quantity': quantity});

      final index = _cartItems.indexWhere(
        (item) => item.product.id == productId,
      );
      if (index >= 0) {
        _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update cart: ${e.toString()}');
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
              discountPrice: 0,
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
