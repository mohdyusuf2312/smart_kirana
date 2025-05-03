import 'package:flutter/material.dart';
import 'package:smart_kirana/models/product_model.dart';
import 'package:smart_kirana/services/recommendation_service.dart';

class RecommendationProvider extends ChangeNotifier {
  final RecommendationService _recommendationService = RecommendationService();
  
  List<ProductModel> _recommendedProducts = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<ProductModel> get recommendedProducts => _recommendedProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Load recommendations for a user
  Future<void> loadRecommendations(
    String userId, 
    List<ProductModel> allProducts
  ) async {
    if (userId.isEmpty) {
      _setError('User ID is required to load recommendations');
      return;
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      // Get recommendation IDs from the service
      final recommendationIds = await _recommendationService.getRecommendations(userId);
      
      if (recommendationIds.isEmpty) {
        _recommendedProducts = [];
        _setLoading(false);
        return;
      }
      
      // Map recommendation IDs to actual product objects
      _recommendedProducts = recommendationIds
          .map((id) => allProducts.firstWhere(
                (product) => product.id == id,
                orElse: () => ProductModel(
                  id: '',
                  name: '',
                  description: '',
                  price: 0,
                  imageUrl: '',
                  categoryId: '',
                  categoryName: '',
                  stock: 0,
                  unit: '',
                ),
              ))
          .where((product) => product.id.isNotEmpty) // Filter out products that weren't found
          .toList();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load recommendations: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // Generate new recommendations for a user
  Future<void> generateRecommendations(
    String userId,
    List<ProductModel> allProducts
  ) async {
    if (userId.isEmpty) {
      _setError('User ID is required to generate recommendations');
      return;
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      // Generate new recommendations
      await _recommendationService.generateRecommendations(userId);
      
      // Load the newly generated recommendations
      await loadRecommendations(userId, allProducts);
    } catch (e) {
      _setError('Failed to generate recommendations: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
  }
}
