import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_kirana/services/recommendation_service.dart';
import 'package:smart_kirana/utils/constants.dart';

class RecommendationGenerationScreen extends StatefulWidget {
  static const String routeName = '/admin/recommendations';

  const RecommendationGenerationScreen({Key? key}) : super(key: key);

  @override
  State<RecommendationGenerationScreen> createState() =>
      _RecommendationGenerationScreenState();
}

class _RecommendationGenerationScreenState
    extends State<RecommendationGenerationScreen> {
  final RecommendationService _recommendationService = RecommendationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isGenerating = false;
  String? _errorMessage;
  String? _successMessage;
  List<Map<String, dynamic>> _userRecommendations = [];
  bool _isLoadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    _loadExistingRecommendations();
  }

  Future<void> _loadExistingRecommendations() async {
    setState(() {
      _isLoadingRecommendations = true;
      _errorMessage = null;
    });

    try {
      final recommendationsSnapshot = await _firestore
          .collection('recommendations')
          .get();

      final List<Map<String, dynamic>> recommendations = [];
      
      for (var doc in recommendationsSnapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String? ?? '';
        final generatedAt = (data['generatedAt'] as Timestamp?)?.toDate();
        final productCount = (data['recommendedProducts'] as List?)?.length ?? 0;
        
        // Get user name
        String userName = 'Unknown User';
        try {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            userName = userDoc.data()?['name'] as String? ?? 'Unknown User';
          }
        } catch (e) {
          debugPrint('Error fetching user data: $e');
        }
        
        recommendations.add({
          'userId': userId,
          'userName': userName,
          'generatedAt': generatedAt,
          'productCount': productCount,
        });
      }
      
      setState(() {
        _userRecommendations = recommendations;
        _isLoadingRecommendations = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load recommendations: ${e.toString()}';
        _isLoadingRecommendations = false;
      });
    }
  }

  Future<void> _generateRecommendationsForAllUsers() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Get all users
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'CUSTOMER')
          .get();

      if (usersSnapshot.docs.isEmpty) {
        setState(() {
          _errorMessage = 'No users found to generate recommendations for';
          _isGenerating = false;
        });
        return;
      }

      int successCount = 0;
      int failureCount = 0;
      
      // Generate recommendations for each user
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        try {
          await _recommendationService.generateRecommendations(userId);
          successCount++;
        } catch (e) {
          failureCount++;
          debugPrint('Failed to generate recommendations for user $userId: $e');
        }
      }

      setState(() {
        _successMessage = 'Generated recommendations for $successCount users. Failed for $failureCount users.';
        _isGenerating = false;
      });
      
      // Refresh the recommendations list
      await _loadExistingRecommendations();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate recommendations: ${e.toString()}';
        _isGenerating = false;
      });
    }
  }

  Future<void> _generateRecommendationsForUser(String userId) async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _recommendationService.generateRecommendations(userId);
      
      setState(() {
        _successMessage = 'Successfully generated recommendations for user';
        _isGenerating = false;
      });
      
      // Refresh the recommendations list
      await _loadExistingRecommendations();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate recommendations: ${e.toString()}';
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendation Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Generate Recommendations',
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: AppPadding.small),
                    const Text(
                      'Generate personalized product recommendations for all users based on their order history.',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: AppPadding.medium),
                    ElevatedButton(
                      onPressed: _isGenerating
                          ? null
                          : _generateRecommendationsForAllUsers,
                      child: _isGenerating
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Generating...'),
                              ],
                            )
                          : const Text('Generate Recommendations for All Users'),
                    ),
                  ],
                ),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppPadding.small),
                child: Text(
                  _errorMessage!,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                ),
              ),
            if (_successMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppPadding.small),
                child: Text(
                  _successMessage!,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.green),
                ),
              ),
            const SizedBox(height: AppPadding.medium),
            const Text(
              'Existing Recommendations',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: AppPadding.small),
            Expanded(
              child: _isLoadingRecommendations
                  ? const Center(child: CircularProgressIndicator())
                  : _userRecommendations.isEmpty
                      ? const Center(
                          child: Text('No recommendations generated yet'),
                        )
                      : ListView.builder(
                          itemCount: _userRecommendations.length,
                          itemBuilder: (context, index) {
                            final recommendation = _userRecommendations[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: AppPadding.small),
                              child: ListTile(
                                title: Text(recommendation['userName']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('User ID: ${recommendation['userId']}'),
                                    Text(
                                      'Generated: ${recommendation['generatedAt']?.toString() ?? 'Unknown'}',
                                    ),
                                    Text(
                                      'Products: ${recommendation['productCount']}',
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: () => _generateRecommendationsForUser(
                                    recommendation['userId'],
                                  ),
                                  tooltip: 'Regenerate recommendations',
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
