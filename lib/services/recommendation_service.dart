import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_kirana/models/order_model.dart';
import 'package:smart_kirana/models/product_model.dart';

class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Generate recommendations based on user's order history
  Future<void> generateRecommendations(String userId) async {
    try {
      // Step 1: Get user's order history
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('orderDate', descending: true)
          .get();

      if (ordersSnapshot.docs.isEmpty) {
        debugPrint('No order history found for user $userId');
        return;
      }

      // Step 2: Extract all ordered products
      final Map<String, int> productFrequency = {};
      final Map<String, DateTime> lastOrderedDate = {};
      final Map<String, List<String>> categoryProducts = {};
      final Set<String> categories = {};

      for (var orderDoc in ordersSnapshot.docs) {
        final orderData = orderDoc.data();
        final orderItems = orderData['items'] as List<dynamic>;
        final orderDate = (orderData['orderDate'] as Timestamp).toDate();

        for (var item in orderItems) {
          final productId = item['productId'] as String;
          final categoryId = item['categoryId'] as String? ?? '';
          
          // Update frequency count
          productFrequency[productId] = (productFrequency[productId] ?? 0) + 1;
          
          // Update last ordered date if newer
          if (!lastOrderedDate.containsKey(productId) || 
              orderDate.isAfter(lastOrderedDate[productId]!)) {
            lastOrderedDate[productId] = orderDate;
          }
          
          // Group products by category
          if (categoryId.isNotEmpty) {
            categories.add(categoryId);
            if (!categoryProducts.containsKey(categoryId)) {
              categoryProducts[categoryId] = [];
            }
            if (!categoryProducts[categoryId]!.contains(productId)) {
              categoryProducts[categoryId]!.add(productId);
            }
          }
        }
      }

      // Step 3: Get all products to find related items
      final productsSnapshot = await _firestore.collection('products').get();
      final Map<String, ProductModel> allProducts = {};
      
      for (var doc in productsSnapshot.docs) {
        try {
          final product = ProductModel.fromMap(doc.data(), doc.id);
          allProducts[doc.id] = product;
        } catch (e) {
          debugPrint('Error parsing product ${doc.id}: $e');
        }
      }

      // Step 4: Calculate scores for each product
      final Map<String, double> productScores = {};
      
      // Score based on purchase frequency
      for (var entry in productFrequency.entries) {
        productScores[entry.key] = entry.value.toDouble() * 2.0; // Base score from frequency
      }
      
      // Score based on recency (higher score for recently ordered items)
      final now = DateTime.now();
      for (var entry in lastOrderedDate.entries) {
        final daysSinceOrder = now.difference(entry.value).inDays;
        // Recency factor: more recent = higher score
        final recencyScore = daysSinceOrder < 30 ? (30 - daysSinceOrder) / 10 : 0;
        productScores[entry.key] = (productScores[entry.key] ?? 0) + recencyScore;
      }
      
      // Add related products based on category
      for (var categoryId in categories) {
        final productsInCategory = categoryProducts[categoryId] ?? [];
        
        // Find products in the same category that user hasn't purchased
        final allProductsInCategory = allProducts.values
            .where((p) => p.categoryId == categoryId)
            .map((p) => p.id)
            .toList();
            
        for (var productId in allProductsInCategory) {
          if (!productsInCategory.contains(productId)) {
            // Add a smaller score for products in categories user has purchased from
            productScores[productId] = (productScores[productId] ?? 0) + 0.5;
          }
        }
      }
      
      // Step 5: Sort products by score and take top recommendations
      final sortedRecommendations = productScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Get top 20 recommendations or fewer if not enough
      final int recommendationCount = sortedRecommendations.length > 20 
          ? 20 
          : sortedRecommendations.length;
          
      final List<String> topRecommendations = sortedRecommendations
          .take(recommendationCount)
          .map((e) => e.key)
          .toList();
      
      // Step 6: Store recommendations in Firestore
      await _firestore.collection('recommendations').doc(userId).set({
        'userId': userId,
        'recommendedProducts': topRecommendations,
        'generatedAt': Timestamp.now(),
      });
      
      debugPrint('Generated ${topRecommendations.length} recommendations for user $userId');
    } catch (e) {
      debugPrint('Error generating recommendations: $e');
      rethrow;
    }
  }

  // Get recommendations for a user
  Future<List<String>> getRecommendations(String userId) async {
    try {
      final recommendationDoc = await _firestore
          .collection('recommendations')
          .doc(userId)
          .get();
      
      if (!recommendationDoc.exists) {
        // Generate recommendations if they don't exist
        await generateRecommendations(userId);
        
        // Try to get the newly generated recommendations
        final newRecommendationDoc = await _firestore
            .collection('recommendations')
            .doc(userId)
            .get();
            
        if (!newRecommendationDoc.exists) {
          return [];
        }
        
        return List<String>.from(
          newRecommendationDoc.data()?['recommendedProducts'] ?? []
        );
      }
      
      return List<String>.from(
        recommendationDoc.data()?['recommendedProducts'] ?? []
      );
    } catch (e) {
      debugPrint('Error getting recommendations: $e');
      return [];
    }
  }
}
