import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_kirana/models/order_model.dart';
import 'package:smart_kirana/models/product_model.dart';
import 'package:smart_kirana/models/recommendation_model.dart';

class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get recommendations for a specific user
  Future<RecommendationModel?> getUserRecommendations(String userId) async {
    try {
      final docSnapshot =
          await _firestore.collection('recommendations').doc(userId).get();

      if (docSnapshot.exists) {
        return RecommendationModel.fromMap(
          docSnapshot.data() as Map<String, dynamic>,
          docSnapshot.id,
        );
      }

      // If user doesn't have recommendations, get global recommendations
      return await getGlobalRecommendations();
    } catch (e) {
      debugPrint('Error getting user recommendations: $e');
      return null;
    }
  }

  // Get global recommendations that apply to all users
  Future<RecommendationModel?> getGlobalRecommendations() async {
    try {
      final querySnapshot =
          await _firestore
              .collection('recommendations')
              .where('isGlobal', isEqualTo: true)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return RecommendationModel.fromMap(
          // ignore: unnecessary_cast
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }

      return null;
    } catch (e) {
      debugPrint('Error getting global recommendations: $e');
      return null;
    }
  }

  // Generate recommendations based on order history
  Future<void> generateRecommendationsForUser(
    String userId,
    String userName,
  ) async {
    try {
      // Get user's order history
      final ordersSnapshot =
          await _firestore
              .collection('orders')
              .where('userId', isEqualTo: userId)
              .orderBy('orderDate', descending: true)
              .get();

      if (ordersSnapshot.docs.isEmpty) {
        return;
      }

      // Process orders to find frequently purchased products with recency factor
      final Map<String, RecommendedProduct> productFrequency = {};
      final Map<String, DateTime> lastPurchaseDate =
          {}; // Track last purchase date for recency

      // Calculate recency weight - more recent orders get higher weight
      final now = DateTime.now();

      for (var doc in ordersSnapshot.docs) {
        final order = OrderModel.fromMap(doc.data(), doc.id);

        // Calculate days since this order
        final daysSinceOrder = now.difference(order.orderDate).inDays;
        // Recency factor: more recent orders have higher weight (max 1.0)
        // Orders older than 30 days get progressively less weight
        final recencyFactor =
            daysSinceOrder <= 30 ? 1.0 : 1.0 / (daysSinceOrder / 30);

        for (var item in order.items) {
          // Track the most recent purchase date for each product
          if (!lastPurchaseDate.containsKey(item.productId) ||
              order.orderDate.isAfter(lastPurchaseDate[item.productId]!)) {
            lastPurchaseDate[item.productId] = order.orderDate;
          }

          if (productFrequency.containsKey(item.productId)) {
            // Increment frequency for existing product with recency factor
            final existingProduct = productFrequency[item.productId]!;
            productFrequency[item.productId] = RecommendedProduct(
              productId: existingProduct.productId,
              productName: existingProduct.productName,
              imageUrl: existingProduct.imageUrl,
              price: existingProduct.price,
              discountPrice: existingProduct.discountPrice,
              // Add recency-weighted frequency
              frequency:
                  existingProduct.frequency + (1 * recencyFactor).round(),
            );
          } else {
            // Add new product
            productFrequency[item.productId] = RecommendedProduct(
              productId: item.productId,
              productName: item.productName,
              imageUrl: item.productImage,
              price: item.price,
              discountPrice:
                  item.price, // Use the price from order as discountPrice
              frequency: (1 * recencyFactor).round(), // Apply recency factor
            );
          }
        }
      }

      // Add complementary products based on category similarity
      await _addComplementaryProducts(productFrequency, userId);

      // Sort products by a combination of frequency and recency
      final recommendedProducts =
          productFrequency.values.toList()..sort((a, b) {
            // Primary sort by frequency
            final freqCompare = b.frequency.compareTo(a.frequency);
            if (freqCompare != 0) return freqCompare;

            // Secondary sort by recency (if frequencies are equal)
            final aDate = lastPurchaseDate[a.productId] ?? DateTime(2000);
            final bDate = lastPurchaseDate[b.productId] ?? DateTime(2000);
            return bDate.compareTo(aDate); // More recent first
          });

      // Limit to top 10 recommendations
      final topRecommendations = recommendedProducts.take(10).toList();

      // Save recommendations to Firestore
      await _firestore.collection('recommendations').doc(userId).set({
        'userName': userName,
        'products':
            topRecommendations.map((product) => product.toMap()).toList(),
        'lastUpdated': Timestamp.now(),
        'isGlobal': false,
      });
    } catch (e) {
      // Error generating recommendations - fail silently
    }
  }

  // Add a product to user's recommendations
  Future<void> addProductToRecommendations(
    String userId,
    String userName,
    ProductModel product,
  ) async {
    try {
      final docRef = _firestore.collection('recommendations').doc(userId);
      final docSnapshot = await docRef.get();

      final recommendedProduct = RecommendedProduct(
        productId: product.id,
        productName: product.name,
        imageUrl: product.imageUrl,
        price: product.price,
        discountPrice: product.discountPrice,
      );

      if (docSnapshot.exists) {
        // Update existing recommendations
        final recommendations = RecommendationModel.fromMap(
          docSnapshot.data() as Map<String, dynamic>,
          docSnapshot.id,
        );

        // Check if product already exists
        final existingIndex = recommendations.products.indexWhere(
          (p) => p.productId == product.id,
        );

        if (existingIndex >= 0) {
          // Product already exists, no need to add again
          return;
        }

        // Add new product to recommendations
        final updatedProducts = [
          ...recommendations.products,
          recommendedProduct,
        ];

        await docRef.update({
          'products': updatedProducts.map((p) => p.toMap()).toList(),
          'lastUpdated': Timestamp.now(),
        });
      } else {
        // Create new recommendations document
        await docRef.set({
          'userName': userName,
          'products': [recommendedProduct.toMap()],
          'lastUpdated': Timestamp.now(),
          'isGlobal': false,
        });
      }
    } catch (e) {
      // Error adding product to recommendations - fail silently
    }
  }

  // Remove a product from user's recommendations
  Future<void> removeProductFromRecommendations(
    String userId,
    String productId,
  ) async {
    try {
      final docRef = _firestore.collection('recommendations').doc(userId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        return;
      }

      final recommendations = RecommendationModel.fromMap(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );

      final updatedProducts =
          recommendations.products
              .where((product) => product.productId != productId)
              .toList();

      await docRef.update({
        'products': updatedProducts.map((p) => p.toMap()).toList(),
        'lastUpdated': Timestamp.now(),
      });
    } catch (e) {
      // Error removing product from recommendations - fail silently
    }
  }

  // Generate recommendations after an order is placed
  Future<void> generateRecommendationsAfterOrder(
    String userId,
    String userName,
    OrderModel order,
  ) async {
    try {
      // First, check if the user already has recommendations
      final docSnapshot =
          await _firestore.collection('recommendations').doc(userId).get();

      if (docSnapshot.exists) {
        // User already has recommendations, update them with new order data
        final recommendations = RecommendationModel.fromMap(
          docSnapshot.data() as Map<String, dynamic>,
          docSnapshot.id,
        );

        // Process new order items
        final Map<String, RecommendedProduct> updatedProducts = {};

        // First, add existing recommendations to the map
        for (var product in recommendations.products) {
          updatedProducts[product.productId] = product;
        }

        // Then process new order items
        for (var item in order.items) {
          if (updatedProducts.containsKey(item.productId)) {
            // Update existing product frequency
            final existingProduct = updatedProducts[item.productId]!;
            updatedProducts[item.productId] = RecommendedProduct(
              productId: existingProduct.productId,
              productName: existingProduct.productName,
              imageUrl: existingProduct.imageUrl,
              price: existingProduct.price,
              discountPrice: existingProduct.discountPrice,
              frequency: existingProduct.frequency + 1,
            );
          } else {
            // Add new product
            updatedProducts[item.productId] = RecommendedProduct(
              productId: item.productId,
              productName: item.productName,
              imageUrl: item.productImage,
              price: item.price,
              discountPrice: item.price,
              frequency: 1,
            );
          }
        }

        // Sort and limit products
        final sortedProducts =
            updatedProducts.values.toList()
              ..sort((a, b) => b.frequency.compareTo(a.frequency));

        final topProducts = sortedProducts.take(10).toList();

        // Update recommendations in Firestore
        await _firestore.collection('recommendations').doc(userId).update({
          'products': topProducts.map((p) => p.toMap()).toList(),
          'lastUpdated': Timestamp.now(),
        });
      } else {
        // User doesn't have recommendations yet, generate them from scratch
        await generateRecommendationsForUser(userId, userName);
      }
    } catch (e) {
      // Error generating recommendations after order - fail silently
    }
  }

  // Check if recommendations need to be refreshed (older than 7 days)
  Future<void> checkAndRefreshRecommendations(
    String userId,
    String userName,
  ) async {
    try {
      final docSnapshot =
          await _firestore.collection('recommendations').doc(userId).get();

      if (!docSnapshot.exists) {
        // No recommendations exist, generate them
        await generateRecommendationsForUser(userId, userName);
        return;
      }

      final recommendations = RecommendationModel.fromMap(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );

      // Check if recommendations are older than 7 days
      final now = DateTime.now();
      final daysSinceUpdate =
          now.difference(recommendations.lastUpdated).inDays;

      if (daysSinceUpdate > 7) {
        await generateRecommendationsForUser(userId, userName);
      }
    } catch (e) {
      // Error checking recommendation age - fail silently
    }
  }

  // Add a product to global recommendations
  Future<void> addProductToGlobalRecommendations(ProductModel product) async {
    try {
      // Get or create global recommendations document
      final querySnapshot =
          await _firestore
              .collection('recommendations')
              .where('isGlobal', isEqualTo: true)
              .limit(1)
              .get();

      final recommendedProduct = RecommendedProduct(
        productId: product.id,
        productName: product.name,
        imageUrl: product.imageUrl,
        price: product.price,
        discountPrice: product.discountPrice,
      );

      if (querySnapshot.docs.isNotEmpty) {
        // Update existing global recommendations
        final docRef = querySnapshot.docs.first.reference;
        final recommendations = RecommendationModel.fromMap(
          querySnapshot.docs.first.data(),
          querySnapshot.docs.first.id,
        );

        // Check if product already exists
        final existingIndex = recommendations.products.indexWhere(
          (p) => p.productId == product.id,
        );

        if (existingIndex >= 0) {
          // Product already exists, no need to add again
          return;
        }

        // Add new product to recommendations
        final updatedProducts = [
          ...recommendations.products,
          recommendedProduct,
        ];

        // Limit global recommendations to 20 products max
        // Sort by frequency first to keep the most popular ones
        updatedProducts.sort((a, b) => b.frequency.compareTo(a.frequency));
        final limitedProducts = updatedProducts.take(20).toList();

        await docRef.update({
          'products': limitedProducts.map((p) => p.toMap()).toList(),
          'lastUpdated': Timestamp.now(),
        });
      } else {
        // Create new global recommendations document
        await _firestore.collection('recommendations').add({
          'userName': 'Global Recommendations',
          'products': [recommendedProduct.toMap()],
          'lastUpdated': Timestamp.now(),
          'isGlobal': true,
        });
      }
    } catch (e) {
      // Error adding product to global recommendations - fail silently
    }
  }

  // Add complementary products based on category similarity and popularity
  Future<void> _addComplementaryProducts(
    Map<String, RecommendedProduct> productFrequency,
    String userId,
  ) async {
    try {
      // Get categories of frequently purchased products
      final purchasedCategories = <String>{};
      final purchasedProductIds = productFrequency.keys.toSet();

      // Get product details to find categories
      for (final productId in purchasedProductIds) {
        final productDoc =
            await _firestore.collection('products').doc(productId).get();
        if (productDoc.exists) {
          final categoryId = productDoc.data()?['categoryId'] as String?;
          if (categoryId != null) {
            purchasedCategories.add(categoryId);
          }
        }
      }

      // Find popular products in the same categories
      for (final categoryId in purchasedCategories) {
        final categoryProductsSnapshot =
            await _firestore
                .collection('products')
                .where('categoryId', isEqualTo: categoryId)
                .where('stock', isGreaterThan: 0)
                .limit(5)
                .get();

        for (final productDoc in categoryProductsSnapshot.docs) {
          final productId = productDoc.id;
          final productData = productDoc.data();

          // Skip if already in recommendations
          if (productFrequency.containsKey(productId)) continue;

          // Add as complementary product with lower frequency
          productFrequency[productId] = RecommendedProduct(
            productId: productId,
            productName: productData['name'] ?? '',
            imageUrl: productData['imageUrl'] ?? '',
            price: (productData['price'] ?? 0.0).toDouble(),
            discountPrice:
                productData['discountPrice'] != null
                    ? (productData['discountPrice']).toDouble()
                    : null,
            frequency: 1, // Lower frequency for complementary products
          );
        }
      }

      // Add trending products from global recommendations
      final globalRecommendations = await getGlobalRecommendations();
      if (globalRecommendations != null) {
        for (final product in globalRecommendations.products.take(3)) {
          if (!productFrequency.containsKey(product.productId)) {
            productFrequency[product.productId] = RecommendedProduct(
              productId: product.productId,
              productName: product.productName,
              imageUrl: product.imageUrl,
              price: product.price,
              discountPrice: product.discountPrice,
              frequency: 1, // Lower frequency for trending products
            );
          }
        }
      }
    } catch (e) {
      // Don't fail the main recommendation process if complementary products fail
    }
  }
}
