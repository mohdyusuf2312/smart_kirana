import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/product_model.dart';
import 'package:smart_kirana/providers/cart_provider.dart';
import 'package:smart_kirana/utils/constants.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final isInCart = cartProvider.isInCart(product.id);

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
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 100,
                          width: double.infinity,
                          color: AppColors.background,
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    ),
                  ),
                ),
                if (product.discountPrice != null && product.discountPrice! > 0)
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
                      child: Text(
                        'Out of Stock',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.unit,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '₹${(product.discountPrice != null && product.discountPrice! > 0) ? product.discountPrice! : product.price}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (product.discountPrice != null &&
                          product.discountPrice! > 0)
                        Text(
                          '₹${product.price}',
                          style: AppTextStyles.bodySmall.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ],
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
                    onPressed: () {
                      if (isInCart) {
                        // Navigate to cart
                        Navigator.pushNamed(context, '/cart');
                      } else {
                        // Add to cart
                        cartProvider.addToCart(product, 1);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Added to cart'),
                            backgroundColor: AppColors.success,
                            duration: Duration(seconds: 2),
                          ),
                        );
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
  }
}
