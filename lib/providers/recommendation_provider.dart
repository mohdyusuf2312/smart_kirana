import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_kirana/models/product_model.dart';
import 'package:smart_kirana/models/recommendation_model.dart';
import 'package:smart_kirana/services/recommendation_service.dart';

class RecommendationProvider extends ChangeNotifier {
  final RecommendationService _recommendationService = RecommendationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RecommendationModel? _userRecommendations;
  List<RecommendationModel> _allUserRecommendations = [];
  RecommendationModel? _globalRecommendations;
  bool _isLoading = false;
  String? _error;

  // Getters
  RecommendationModel? get userRecommendations => _userRecommendations;
  List<RecommendationModel> get allUserRecommendations =>
      _allUserRecommendations;
  RecommendationModel? get globalRecommendations => _globalRecommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load recommendations for a specific user
  Future<void> loadUserRecommendations(
    String userId, {
    String? userName,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      // First, check if recommendations need to be refreshed
      if (userName != null) {
        await _recommendationService.checkAndRefreshRecommendations(
          userId,
          userName,
        );
      }

      // Then load the recommendations
      _userRecommendations = await _recommendationService
          .getUserRecommendations(userId);

      // If user has no recommendations, explicitly load global recommendations
      if (_userRecommendations == null ||
          _userRecommendations!.products.isEmpty) {
        debugPrint(
          'No user-specific recommendations found, loading global recommendations',
        );

        // Load global recommendations if not already loaded
        if (_globalRecommendations == null) {
          await loadGlobalRecommendations();
        }

        // If we have global recommendations, use them as fallback
        if (_globalRecommendations != null &&
            _globalRecommendations!.products.isNotEmpty) {
          debugPrint('Using global recommendations as fallback');
          _userRecommendations = _globalRecommendations;
        }
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to load recommendations: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load global recommendations
  Future<void> loadGlobalRecommendations() async {
    _setLoading(true);
    _error = null;

    try {
      _globalRecommendations =
          await _recommendationService.getGlobalRecommendations();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load global recommendations: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load all user recommendations (for admin)
  Future<void> loadAllUserRecommendations() async {
    _setLoading(true);
    _error = null;

    try {
      // Get all recommendations (including global ones for debugging)
      final querySnapshot =
          await _firestore.collection('recommendations').get();

      // Clear previous recommendations
      _allUserRecommendations = [];

      // Process each document
      for (var doc in querySnapshot.docs) {
        try {
          final recommendation = RecommendationModel.fromMap(
            doc.data(),
            doc.id,
          );

          // Add all recommendations to the list for now
          // The UI will filter out global recommendations when displaying
          _allUserRecommendations.add(recommendation);

          // Debug info
          debugPrint(
            'Loaded recommendation - ID: ${doc.id}, Name: ${recommendation.userName}, '
            'isGlobal: ${recommendation.isGlobal}, Products: ${recommendation.products.length}',
          );
        } catch (docError) {
          debugPrint(
            'Error processing recommendation document ${doc.id}: $docError',
          );
          // Continue processing other documents even if one fails
        }
      }

      // Sort recommendations by userName for better display
      _allUserRecommendations.sort((a, b) => a.userName.compareTo(b.userName));

      notifyListeners();
      debugPrint(
        'Loaded ${_allUserRecommendations.length} total recommendations',
      );

      // Count actual user recommendations (non-global)
      final userRecsCount =
          _allUserRecommendations.where((rec) => !rec.isGlobal).length;
      debugPrint('User-specific recommendations count: $userRecsCount');
    } catch (e) {
      _setError('Failed to load all recommendations: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Generate recommendations for a user based on order history
  Future<void> generateRecommendationsForUser(
    String userId,
    String userName,
  ) async {
    _setLoading(true);
    _error = null;

    try {
      await _recommendationService.generateRecommendationsForUser(
        userId,
        userName,
      );

      // Reload user recommendations
      await loadUserRecommendations(userId);

      // Also reload all user recommendations to keep the admin view in sync
      await loadAllUserRecommendations();

      debugPrint('Generated recommendations for user $userId');
    } catch (e) {
      _setError('Failed to generate recommendations: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Add a product to user's recommendations
  Future<void> addProductToRecommendations(
    String userId,
    String userName,
    ProductModel product,
  ) async {
    _setLoading(true);
    _error = null;

    try {
      await _recommendationService.addProductToRecommendations(
        userId,
        userName,
        product,
      );

      // Reload user recommendations
      await loadUserRecommendations(userId);

      // Also reload all user recommendations to keep the admin view in sync
      await loadAllUserRecommendations();

      debugPrint(
        'Added product ${product.name} to recommendations for user $userId',
      );
    } catch (e) {
      _setError('Failed to add product to recommendations: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Remove a product from user's recommendations
  Future<void> removeProductFromRecommendations(
    String userId,
    String productId, {
    bool updateUIOnly = false, // New parameter to control database reload
  }) async {
    _setLoading(true);
    _error = null;

    try {
      // Update the database
      await _recommendationService.removeProductFromRecommendations(
        userId,
        productId,
      );

      // Update local state directly instead of reloading everything
      // This prevents the screen from refreshing completely

      // Check if this is a global recommendation
      if (_globalRecommendations != null &&
          userId == _globalRecommendations!.userId) {
        // Update global recommendations locally
        _globalRecommendations = _globalRecommendations!.copyWith(
          products:
              _globalRecommendations!.products
                  .where((product) => product.productId != productId)
                  .toList(),
        );
      }

      // Update user recommendations if applicable
      if (_userRecommendations != null &&
          userId == _userRecommendations!.userId) {
        _userRecommendations = _userRecommendations!.copyWith(
          products:
              _userRecommendations!.products
                  .where((product) => product.productId != productId)
                  .toList(),
        );
      }

      // Update in the all users list without reloading
      final index = _allUserRecommendations.indexWhere(
        (rec) => rec.userId == userId,
      );
      if (index >= 0) {
        final updatedRec = _allUserRecommendations[index].copyWith(
          products:
              _allUserRecommendations[index].products
                  .where((product) => product.productId != productId)
                  .toList(),
        );
        _allUserRecommendations[index] = updatedRec;
      }

      // Only reload from database if updateUIOnly is false
      if (!updateUIOnly) {
        // Check if this is a global recommendation
        if (_globalRecommendations != null &&
            userId == _globalRecommendations!.userId) {
          // Reload global recommendations
          await loadGlobalRecommendations();
        } else {
          // Reload user recommendations
          await loadUserRecommendations(userId);
        }

        // Also reload all user recommendations to keep the admin view in sync
        await loadAllUserRecommendations();
      }

      // Notify listeners to update UI without full reload
      notifyListeners();

      debugPrint(
        'Removed product $productId from recommendations for user $userId',
      );
    } catch (e) {
      _setError(
        'Failed to remove product from recommendations: ${e.toString()}',
      );
    } finally {
      _setLoading(false);
    }
  }

  // Add a product to global recommendations
  Future<void> addProductToGlobalRecommendations(ProductModel product) async {
    _setLoading(true);
    _error = null;

    try {
      await _recommendationService.addProductToGlobalRecommendations(product);
      // Reload global recommendations to update the UI
      await loadGlobalRecommendations();
      // Also reload all user recommendations to keep the admin view in sync
      await loadAllUserRecommendations();
      debugPrint('Added product ${product.name} to global recommendations');
    } catch (e) {
      _setError(
        'Failed to add product to global recommendations: ${e.toString()}',
      );
    } finally {
      _setLoading(false);
    }
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
