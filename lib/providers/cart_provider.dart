import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_kirana/models/cart_item_model.dart';
import 'package:smart_kirana/models/product_model.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/providers/product_provider.dart';

class CartProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AuthProvider _authProvider;
  final ProductProvider _productProvider;

  List<CartItemModel> _cartItems = [];
  bool _isLoading = false;
  String? _error;
  final double _baseDeliveryFee = 40.0; // Default delivery fee
  final double _freeDeliveryThreshold =
      200.0; // Free delivery above this amount

  // Guest cart storage key
  static const String _guestCartKey = 'guest_cart_items';

  CartProvider({
    required AuthProvider authProvider,
    required ProductProvider productProvider,
  }) : _authProvider = authProvider,
       _productProvider = productProvider {
    _loadCart();
  }

  // Update auth provider reference (used when auth state changes)
  void updateAuthProvider(AuthProvider newAuthProvider) {
    _authProvider = newAuthProvider;
    // Don't reload cart here - let the merge logic handle it
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

  // Load cart from Firestore or local storage
  Future<void> _loadCart() async {
    _setLoading(true);
    try {
      if (_authProvider.currentUser != null) {
        // Load from Firestore for authenticated users
        await _loadCartFromFirestore();
      } else {
        // Load from local storage for guest users
        await _loadCartFromLocalStorage();
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to load cart: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load cart from Firestore for authenticated users
  Future<void> _loadCartFromFirestore() async {
    if (_authProvider.currentUser == null) return;

    // First check if there's a temporary guest cart to merge
    await _checkAndMergeTempGuestCart();

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
  }

  // Check for and merge temporary guest cart stored during authentication
  Future<void> _checkAndMergeTempGuestCart() async {
    if (_authProvider.currentUser == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final tempCartData = prefs.getString('temp_guest_cart_for_merge');

      if (tempCartData == null) return;

      // Parse temporary guest cart
      final List<dynamic> tempCartList = jsonDecode(tempCartData);
      final List<CartItemModel> tempCartItems = [];

      for (var item in tempCartList) {
        final productId = item['productId'];
        final quantity = item['quantity'];
        final product = _productProvider.getProductById(productId);

        if (product != null) {
          tempCartItems.add(
            CartItemModel(product: product, quantity: quantity),
          );
        }
      }

      if (tempCartItems.isNotEmpty) {
        // Load existing user cart from Firestore
        final cartSnapshot =
            await _firestore
                .collection('users')
                .doc(_authProvider.currentUser!.uid)
                .collection('cart')
                .get();

        final List<CartItemModel> userCartItems = [];
        for (var doc in cartSnapshot.docs) {
          final data = doc.data();
          final productId = data['productId'];
          final product = _productProvider.getProductById(productId);

          if (product != null) {
            userCartItems.add(CartItemModel.fromMap(data, product));
          }
        }

        // Merge temp cart with user cart
        for (var tempItem in tempCartItems) {
          final existingIndex = userCartItems.indexWhere(
            (item) => item.product.id == tempItem.product.id,
          );

          if (existingIndex >= 0) {
            // Update quantity if item already exists
            userCartItems[existingIndex] = userCartItems[existingIndex]
                .copyWith(
                  quantity:
                      userCartItems[existingIndex].quantity + tempItem.quantity,
                );
          } else {
            // Add new item
            userCartItems.add(tempItem);
          }
        }

        // Save merged cart to Firestore
        final batch = _firestore.batch();
        final userCartRef = _firestore
            .collection('users')
            .doc(_authProvider.currentUser!.uid)
            .collection('cart');

        // Clear existing cart
        final existingCartSnapshot = await userCartRef.get();
        for (var doc in existingCartSnapshot.docs) {
          batch.delete(doc.reference);
        }

        // Add merged cart items
        for (var item in userCartItems) {
          batch.set(userCartRef.doc(item.product.id), item.toMap());
        }

        await batch.commit();

        // Clear temporary cart data
        await prefs.remove('temp_guest_cart_for_merge');

        debugPrint(
          'Temporary guest cart merged successfully. Total items: ${userCartItems.length}',
        );
      }
    } catch (e) {
      debugPrint('Error merging temporary guest cart: $e');
      // Clear the temporary data even if merge fails
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('temp_guest_cart_for_merge');
    }
  }

  // Load cart from local storage for guest users
  Future<void> _loadCartFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = prefs.getString(_guestCartKey);

    _cartItems = [];

    if (cartData != null) {
      try {
        final List<dynamic> cartList = jsonDecode(cartData);
        for (var item in cartList) {
          final productId = item['productId'];
          final quantity = item['quantity'];
          final product = _productProvider.getProductById(productId);

          if (product != null) {
            _cartItems.add(CartItemModel(product: product, quantity: quantity));
          }
        }
      } catch (e) {
        // If there's an error parsing, clear the corrupted data
        await prefs.remove(_guestCartKey);
      }
    }
  }

  // Add product to cart
  Future<bool> addToCart(ProductModel product, int quantity) async {
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

        if (_authProvider.currentUser != null) {
          // Save to Firestore for authenticated users
          await _firestore
              .collection('users')
              .doc(_authProvider.currentUser!.uid)
              .collection('cart')
              .doc(product.id)
              .set(cartItem.toMap());
        } else {
          // Save to local storage for guest users
          await _saveGuestCartToLocalStorage();
        }

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

  // Save guest cart to local storage
  Future<void> _saveGuestCartToLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData =
        _cartItems
            .map(
              (item) => {
                'productId': item.product.id,
                'quantity': item.quantity,
              },
            )
            .toList();

    await prefs.setString(_guestCartKey, jsonEncode(cartData));
  }

  // Merge guest cart with user cart when user logs in
  Future<void> mergeGuestCartWithUserCart() async {
    if (_authProvider.currentUser == null) return;

    try {
      // Get guest cart from local storage
      final prefs = await SharedPreferences.getInstance();
      final guestCartData = prefs.getString(_guestCartKey);

      if (guestCartData == null) {
        // No guest cart, just load user cart
        await _loadCartFromFirestore();
        return;
      }

      // Parse guest cart
      final List<dynamic> guestCartList = jsonDecode(guestCartData);
      final List<CartItemModel> guestCartItems = [];

      for (var item in guestCartList) {
        final productId = item['productId'];
        final quantity = item['quantity'];
        final product = _productProvider.getProductById(productId);

        if (product != null) {
          guestCartItems.add(
            CartItemModel(product: product, quantity: quantity),
          );
        }
      }

      // Load existing user cart from Firestore
      await _loadCartFromFirestore();
      final List<CartItemModel> userCartItems = List.from(_cartItems);

      // Merge guest cart with user cart
      for (var guestItem in guestCartItems) {
        final existingIndex = userCartItems.indexWhere(
          (item) => item.product.id == guestItem.product.id,
        );

        if (existingIndex >= 0) {
          // Product exists in user cart, add quantities
          final newQuantity =
              userCartItems[existingIndex].quantity + guestItem.quantity;

          // Check stock availability
          if (newQuantity <= guestItem.product.stock) {
            userCartItems[existingIndex] = userCartItems[existingIndex]
                .copyWith(quantity: newQuantity);
          } else {
            // Use maximum available stock
            userCartItems[existingIndex] = userCartItems[existingIndex]
                .copyWith(quantity: guestItem.product.stock);
          }
        } else {
          // Product doesn't exist in user cart, add it
          if (guestItem.quantity <= guestItem.product.stock) {
            userCartItems.add(guestItem);
          } else {
            // Add with maximum available stock
            userCartItems.add(
              guestItem.copyWith(quantity: guestItem.product.stock),
            );
          }
        }
      }

      // Update cart items
      _cartItems = userCartItems;

      // Debug: Print cart items after merge
      debugPrint('Cart merge completed. Total items: ${_cartItems.length}');
      for (var item in _cartItems) {
        debugPrint('- ${item.product.name}: ${item.quantity}');
      }

      // Save merged cart to Firestore
      await _saveMergedCartToFirestore();

      // Clear guest cart from local storage
      await prefs.remove(_guestCartKey);

      notifyListeners();
    } catch (e) {
      // If merge fails, just load user cart
      await _loadCartFromFirestore();
    }
  }

  // Save merged cart to Firestore
  Future<void> _saveMergedCartToFirestore() async {
    if (_authProvider.currentUser == null) return;

    final batch = _firestore.batch();
    final userCartRef = _firestore
        .collection('users')
        .doc(_authProvider.currentUser!.uid)
        .collection('cart');

    // Clear existing cart
    final existingCartSnapshot = await userCartRef.get();
    for (var doc in existingCartSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Add merged cart items
    for (var item in _cartItems) {
      batch.set(userCartRef.doc(item.product.id), item.toMap());
    }

    await batch.commit();
  }

  // Update cart item quantity
  Future<bool> updateCartItemQuantity(String productId, int quantity) async {
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
      if (_authProvider.currentUser != null) {
        // Update in Firestore for authenticated users
        await _firestore
            .collection('users')
            .doc(_authProvider.currentUser!.uid)
            .collection('cart')
            .doc(productId)
            .update({'quantity': quantity});
      }

      if (index >= 0) {
        _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);

        // Save to local storage for guest users
        if (_authProvider.currentUser == null) {
          await _saveGuestCartToLocalStorage();
        }

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
    _setLoading(true);
    try {
      if (_authProvider.currentUser != null) {
        // Remove from Firestore for authenticated users
        await _firestore
            .collection('users')
            .doc(_authProvider.currentUser!.uid)
            .collection('cart')
            .doc(productId)
            .delete();
      }

      _cartItems.removeWhere((item) => item.product.id == productId);

      // Save to local storage for guest users
      if (_authProvider.currentUser == null) {
        await _saveGuestCartToLocalStorage();
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to remove from cart: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    _setLoading(true);
    try {
      if (_authProvider.currentUser != null) {
        // Clear from Firestore for authenticated users
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
      } else {
        // Clear from local storage for guest users
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_guestCartKey);
      }

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

  // Public method to reload cart (useful after authentication changes)
  Future<void> reloadCart() async {
    await _loadCart();
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
