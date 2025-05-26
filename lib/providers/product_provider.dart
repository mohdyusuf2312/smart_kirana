import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_kirana/models/category_model.dart';
import 'package:smart_kirana/models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;

  ProductProvider() {
    // Setup real-time listeners for product updates
    setupProductListeners();
  }

  // Getters
  List<ProductModel> get products => _products;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load products from Firestore
  Future<void> loadProducts() async {
    _setLoading(true);
    _error = null; // Clear previous errors
    try {
      final productsSnapshot = await _firestore.collection('products').get();

      if (productsSnapshot.docs.isEmpty) {
        _products = [];
        notifyListeners();
        return;
      }

      _products =
          productsSnapshot.docs
              .map((doc) {
                try {
                  return ProductModel.fromMap(doc.data(), doc.id);
                } catch (e) {
                  // debugPrint('Error parsing product ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<ProductModel>()
              .toList();

      notifyListeners();
    } catch (e) {
      // debugPrint('Failed to load products: $e');
      _setError('Failed to load products: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Refresh a specific product's data
  Future<void> refreshProduct(String productId) async {
    try {
      final productDoc =
          await _firestore.collection('products').doc(productId).get();

      if (!productDoc.exists) {
        // debugPrint('Product $productId no longer exists');
        // Remove from local list if it exists
        _products.removeWhere((product) => product.id == productId);
        notifyListeners();
        return;
      }

      // Find and update the product in the local list
      final index = _products.indexWhere((product) => product.id == productId);
      if (index >= 0) {
        try {
          final updatedProduct = ProductModel.fromMap(
            productDoc.data()!,
            productId,
          );
          _products[index] = updatedProduct;
          notifyListeners();
        } catch (e) {
          // debugPrint('Error parsing updated product $productId: $e');
        }
      }
    } catch (e) {
      // debugPrint('Failed to refresh product $productId: $e');
    }
  }

  // Listen for real-time updates to products
  void setupProductListeners() {
    _firestore
        .collection('products')
        .snapshots()
        .listen(
          (snapshot) {
            for (var change in snapshot.docChanges) {
              final docId = change.doc.id;

              switch (change.type) {
                case DocumentChangeType.modified:
                  try {
                    final updatedProduct = ProductModel.fromMap(
                      change.doc.data()!,
                      docId,
                    );
                    final index = _products.indexWhere(
                      (product) => product.id == docId,
                    );

                    if (index >= 0) {
                      _products[index] = updatedProduct;
                      notifyListeners();
                    }
                  } catch (e) {
                    // debugPrint('Error parsing modified product $docId: $e');
                  }
                  break;

                case DocumentChangeType.added:
                  // Only add if it doesn't already exist
                  if (!_products.any((product) => product.id == docId)) {
                    try {
                      final newProduct = ProductModel.fromMap(
                        change.doc.data()!,
                        docId,
                      );
                      _products.add(newProduct);
                      notifyListeners();
                    } catch (e) {
                      // debugPrint('Error parsing new product $docId: $e');
                    }
                  }
                  break;

                case DocumentChangeType.removed:
                  _products.removeWhere((product) => product.id == docId);
                  notifyListeners();
                  break;
              }
            }
          },
          onError: (error) {
            // debugPrint('Error in product listener: $error');
          },
        );
  }

  // Load categories from Firestore
  Future<void> loadCategories() async {
    _setLoading(true);
    _error = null; // Clear previous errors
    try {
      final categoriesSnapshot =
          await _firestore.collection('categories').get();

      if (categoriesSnapshot.docs.isEmpty) {
        _categories = [];
        notifyListeners();
        return;
      }

      _categories =
          categoriesSnapshot.docs
              .map((doc) {
                try {
                  return CategoryModel.fromMap(doc.data(), doc.id);
                } catch (e) {
                  // debugPrint('Error parsing category ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<CategoryModel>()
              .toList();

      notifyListeners();
    } catch (e) {
      // debugPrint('Failed to load categories: $e');
      _setError('Failed to load categories: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Get products by category
  List<ProductModel> getProductsByCategory(String categoryId) {
    return _products
        .where((product) => product.categoryId == categoryId)
        .toList();
  }

  // Get popular products
  List<ProductModel> getPopularProducts() {
    return _products.where((product) => product.isPopular).toList();
  }

  // Get featured products
  List<ProductModel> getFeaturedProducts() {
    return _products.where((product) => product.isFeatured).toList();
  }

  // Get products expiring soon (within 30 days)
  List<ProductModel> getExpiringSoonProducts() {
    return _products
        .where((product) => product.isExpiringSoon || product.isExpired)
        .toList();
  }

  // Get product by ID
  ProductModel? getProductById(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  // Get category by ID
  CategoryModel? getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  // Search products
  List<ProductModel> searchProducts(String query) {
    if (query.isEmpty) {
      return _products;
    }

    final lowercaseQuery = query.toLowerCase();
    return _products.where((product) {
      return product.name.toLowerCase().contains(lowercaseQuery) ||
          product.description.toLowerCase().contains(lowercaseQuery) ||
          product.categoryName.toLowerCase().contains(lowercaseQuery);
    }).toList();
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
