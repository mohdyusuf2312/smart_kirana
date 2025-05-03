import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/product_model.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/providers/product_provider.dart';
import 'package:smart_kirana/providers/recommendation_provider.dart';
import 'package:smart_kirana/screens/home/product_detail_screen.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/product_card.dart';

class RecommendedProductsSection extends StatefulWidget {
  const RecommendedProductsSection({Key? key}) : super(key: key);

  @override
  State<RecommendedProductsSection> createState() => _RecommendedProductsSectionState();
}

class _RecommendedProductsSectionState extends State<RecommendedProductsSection> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_isInitialized) {
      _loadRecommendations();
      _isInitialized = true;
    }
  }

  Future<void> _loadRecommendations() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final recommendationProvider = Provider.of<RecommendationProvider>(context, listen: false);
    
    if (authProvider.isAuthenticated && authProvider.user != null) {
      await recommendationProvider.loadRecommendations(
        authProvider.user!.id,
        productProvider.products,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final recommendationProvider = Provider.of<RecommendationProvider>(context);
    
    // If user is not authenticated, show popular products instead
    if (!authProvider.isAuthenticated || authProvider.user == null) {
      return _buildPopularProductsSection(context);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.medium),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recommended For You',
                style: AppTextStyles.heading2,
              ),
              if (recommendationProvider.recommendedProducts.isNotEmpty)
                TextButton(
                  onPressed: () {
                    // Navigate to see all recommendations
                    // This could be implemented as a separate screen
                  },
                  child: const Text('See All'),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppPadding.small),
        if (recommendationProvider.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (recommendationProvider.error != null)
          Center(child: Text(recommendationProvider.error!))
        else if (recommendationProvider.recommendedProducts.isEmpty)
          _buildEmptyRecommendations()
        else
          _buildRecommendationsList(recommendationProvider.recommendedProducts),
      ],
    );
  }

  Widget _buildEmptyRecommendations() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.recommend,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppPadding.small),
          Text(
            'No recommendations yet',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Place some orders to get personalized recommendations',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsList(List<ProductModel> products) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.medium),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Padding(
            padding: const EdgeInsets.only(right: AppPadding.small),
            child: SizedBox(
              width: 160,
              child: ProductCard(
                product: product,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(product: product),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // Fallback to popular products if user is not authenticated
  Widget _buildPopularProductsSection(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final popularProducts = productProvider.products
        .where((product) => product.isPopular)
        .take(10)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppPadding.medium),
          child: Text(
            'Popular Products',
            style: AppTextStyles.heading2,
          ),
        ),
        const SizedBox(height: AppPadding.small),
        SizedBox(
          height: 220,
          child: popularProducts.isEmpty
              ? const Center(child: Text('No popular products available'))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppPadding.medium),
                  itemCount: popularProducts.length,
                  itemBuilder: (context, index) {
                    final product = popularProducts[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: AppPadding.small),
                      child: SizedBox(
                        width: 160,
                        child: ProductCard(
                          product: product,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailScreen(product: product),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
