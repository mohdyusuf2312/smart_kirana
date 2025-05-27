import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smart_kirana/models/product_model.dart';
import 'package:smart_kirana/providers/product_provider.dart';
import 'package:smart_kirana/providers/recommendation_provider.dart';
import 'package:smart_kirana/screens/admin/product_form_screen.dart';
import 'package:smart_kirana/utils/constants.dart';

class ExpiringSoonScreen extends StatefulWidget {
  static const String routeName = '/admin-expiring-soon';

  const ExpiringSoonScreen({super.key});

  @override
  State<ExpiringSoonScreen> createState() => _ExpiringSoonScreenState();
}

class _ExpiringSoonScreenState extends State<ExpiringSoonScreen> {
  bool _isLoading = false;
  String? _error;
  List<ProductModel> _expiringSoonProducts = [];

  @override
  void initState() {
    super.initState();
    _loadExpiringSoonProducts();
  }

  Future<void> _loadExpiringSoonProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );

      // Check if products are already loaded to avoid unnecessary reload
      if (productProvider.products.isEmpty) {
        await productProvider.loadProducts();
      }

      // Use compute to offload heavy processing from main thread
      final allProducts = productProvider.products;
      final expiringSoonProducts = await compute(
        _processExpiringSoonProducts,
        allProducts,
      );

      setState(() {
        _expiringSoonProducts = expiringSoonProducts;
      });

      // Add to recommendations in background without blocking UI
      _addExpiringSoonToRecommendations();
    } catch (e) {
      setState(() {
        _error = 'Failed to load expiring products: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Static method for compute function - processes expiring products
  static List<ProductModel> _processExpiringSoonProducts(
    List<ProductModel> allProducts,
  ) {
    final expiringSoonProducts =
        allProducts
            .where((product) => product.isExpiringSoon || product.isExpired)
            .toList();

    // Sort products by expiry date
    expiringSoonProducts.sort((a, b) {
      if (a.isExpired && !b.isExpired) return -1;
      if (!a.isExpired && b.isExpired) return 1;
      if (a.expiryDate == null && b.expiryDate == null) return 0;
      if (a.expiryDate == null) return 1;
      if (b.expiryDate == null) return -1;
      return a.expiryDate!.compareTo(b.expiryDate!);
    });

    return expiringSoonProducts;
  }

  void _addExpiringSoonToRecommendations() {
    // Get provider reference before async operation
    final recommendationProvider = Provider.of<RecommendationProvider>(
      context,
      listen: false,
    );

    // Run in background without blocking UI
    Future.microtask(() async {
      try {
        // Process in smaller batches to avoid blocking
        const batchSize = 5;
        for (int i = 0; i < _expiringSoonProducts.length; i += batchSize) {
          final batch = _expiringSoonProducts.skip(i).take(batchSize);

          for (final product in batch) {
            await recommendationProvider.addProductToGlobalRecommendations(
              product,
            );
          }

          // Add small delay between batches to keep UI responsive
          await Future.delayed(const Duration(milliseconds: 10));
        }
      } catch (e) {
        // Silently handle errors for recommendation updates
        debugPrint('Error adding expiring products to recommendations: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Expiring Soon',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadExpiringSoonProducts,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_error',
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppPadding.medium),
            ElevatedButton(
              onPressed: _loadExpiringSoonProducts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_expiringSoonProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.success,
            ),
            const SizedBox(height: AppPadding.medium),
            const Text(
              'No products expiring soon!',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: AppPadding.small),
            const Text(
              'All products have sufficient shelf life.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExpiringSoonProducts,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppPadding.medium),
            sliver: SliverToBoxAdapter(child: _buildSummaryCard()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppPadding.medium)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppPadding.medium),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Products', style: AppTextStyles.heading2),
                  Text(
                    '${_expiringSoonProducts.length} items',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppPadding.small)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppPadding.medium),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final product = _expiringSoonProducts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppPadding.small),
                  child: _buildProductCard(product),
                );
              }, childCount: _expiringSoonProducts.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppPadding.large)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final expiredCount = _expiringSoonProducts.where((p) => p.isExpired).length;
    final expiringSoonCount =
        _expiringSoonProducts
            .where((p) => p.isExpiringSoon && !p.isExpired)
            .length;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(26),
                    borderRadius: BorderRadius.circular(AppBorderRadius.small),
                  ),
                  child: const Icon(Icons.schedule, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Expiry Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppPadding.medium),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Expiring Soon',
                    expiringSoonCount.toString(),
                    Colors.orange,
                    Icons.warning_amber,
                  ),
                ),
                const SizedBox(width: AppPadding.medium),
                Expanded(
                  child: _buildSummaryItem(
                    'Expired',
                    expiredCount.toString(),
                    AppColors.error,
                    Icons.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final isExpired = product.isExpired;
    final daysUntilExpiry = product.daysUntilExpiry;
    final expiryColor = isExpired ? AppColors.error : Colors.orange;

    String expiryText;
    if (isExpired) {
      expiryText = 'Expired ${(-daysUntilExpiry!)} days ago';
    } else if (daysUntilExpiry == 0) {
      expiryText = 'Expires today';
    } else if (daysUntilExpiry == 1) {
      expiryText = 'Expires tomorrow';
    } else {
      expiryText = 'Expires in $daysUntilExpiry days';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppPadding.medium),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        side: BorderSide(color: expiryColor.withAlpha(51), width: 1),
      ),
      child: ListTile(
        leading: SizedBox(
          width: 50,
          height: 50,
          child:
              product.imageUrl.isNotEmpty
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppBorderRadius.small),
                    child: Image.network(
                      product.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    ),
                  )
                  : Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image),
                  ),
        ),
        title: Text(
          product.name,
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: ₹${product.price.toStringAsFixed(2)}'),
            Text('Stock: ${product.stock}'),
            if (product.expiryDate != null)
              Text(
                'Expiry: ${DateFormat('MMM d, yyyy').format(product.expiryDate!)}',
                style: AppTextStyles.bodySmall,
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: expiryColor.withAlpha(26),
                borderRadius: BorderRadius.circular(AppBorderRadius.small),
              ),
              child: Text(
                expiryText,
                style: AppTextStyles.bodySmall.copyWith(
                  color: expiryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ProductFormScreen(productId: product.id),
                  ),
                );
              },
            ),
            Icon(
              isExpired ? Icons.error : Icons.warning_amber,
              color: expiryColor,
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductFormScreen(productId: product.id),
            ),
          );
        },
      ),
    );
  }
}
