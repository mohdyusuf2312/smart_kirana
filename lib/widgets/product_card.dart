import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/product_model.dart';
import 'package:smart_kirana/providers/cart_provider.dart';
import 'package:smart_kirana/utils/constants.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  // Helper methods for stock status
  Color _getStockStatusColor(int stock) {
    if (stock <= 0) return AppColors.error;
    if (stock < 5) return AppColors.error;
    if (stock < 10) return Colors.orange;
    return AppColors.success;
  }

  IconData _getStockStatusIcon(int stock) {
    if (stock <= 0) return Icons.inventory_2;
    if (stock < 5) return Icons.warning_amber;
    if (stock < 10) return Icons.info_outline;
    return Icons.check_circle_outline;
  }

  String _getStockStatusText(int stock) {
    if (stock <= 0) return 'Out of Stock';
    if (stock < 5) return 'Low: $stock left';
    if (stock < 10) return 'Limited: $stock';
    return 'In Stock: $stock';
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final isInCart = cartProvider.isInCart(product.id);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we're in a very small card scenario
        bool isCompactCard = constraints.maxWidth < 160;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          ),
          child: InkWell(
            // Replace GestureDetector with InkWell for better touch feedback
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product Image
                Stack(
                  children: [
                    Hero(
                      tag: 'product-${product.id}',
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppBorderRadius.medium),
                          topRight: Radius.circular(AppBorderRadius.medium),
                        ),
                        child: Image.network(
                          product.imageUrl,
                          height: isCompactCard ? 80 : 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: isCompactCard ? 80 : 100,
                              width: double.infinity,
                              color: AppColors.background,
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        ),
                      ),
                    ),
                    if (product.discountPrice != null &&
                        product.discountPrice! > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.small,
                            ),
                          ),
                          child: Text(
                            '${(((product.price - product.discountPrice!) / product.price) * 100).round()}% OFF',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    // Stock status overlay
                    if (product.stock <= 0)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(128),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(AppBorderRadius.medium),
                              topRight: Radius.circular(AppBorderRadius.medium),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppPadding.medium,
                              vertical: AppPadding.small,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(
                                AppBorderRadius.small,
                              ),
                            ),
                            child: Text(
                              'OUT OF STOCK',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Stock indicators
                    if (product.stock > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStockStatusColor(product.stock),
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.small,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStockStatusIcon(product.stock),
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getStockStatusText(product.stock),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                // Product Details - Flexible to prevent overflow
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            product.name,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isCompactCard ? 10 : 12,
                            ),
                            maxLines: isCompactCard ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                product.unit,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Stock indicator dot
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getStockStatusColor(product.stock),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Flexible(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '₹${(product.discountPrice != null && product.discountPrice! > 0) ? product.discountPrice! : product.price}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              if (product.discountPrice != null &&
                                  product.discountPrice! > 0)
                                Flexible(
                                  child: Text(
                                    '₹${product.price}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Add to Cart Button
                if (product.stock > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6.0,
                      vertical: 4.0,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (isInCart) {
                            // Navigate to cart
                            Navigator.pushNamed(context, '/cart');
                          } else {
                            // Add to cart
                            final success = await cartProvider.addToCart(
                              product,
                              1,
                            );
                            if (context.mounted) {
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added to cart'),
                                    backgroundColor: AppColors.success,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } else if (cartProvider.error != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(cartProvider.error!),
                                    backgroundColor: AppColors.error,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isInCart ? AppColors.success : AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(double.infinity, 30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.small,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isInCart
                                  ? Icons.shopping_cart
                                  : Icons.add_shopping_cart,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              isInCart ? 'View Cart' : 'Add',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
