import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/product_model.dart';
import 'package:smart_kirana/providers/cart_provider.dart';
import 'package:smart_kirana/utils/constants.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
    final isInCart = cartProvider.isInCart(widget.product.id);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we're in a very small card scenario
        bool isCompactCard = constraints.maxWidth < 160;

        return MouseRegion(
          onEnter: (_) {
            setState(() {
              _isHovered = true;
            });
            _animationController.forward();
          },
          onExit: (_) {
            setState(() {
              _isHovered = false;
            });
            _animationController.reverse();
          },
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Card(
                  elevation: _elevationAnimation.value,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                  ),
                  child: Stack(
                    children: [
                      InkWell(
                        // Replace GestureDetector with InkWell for better touch feedback
                        onTap: widget.onTap,
                        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Product Image
                            Stack(
                              children: [
                                Hero(
                                  tag: 'product-${widget.product.id}',
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(AppBorderRadius.medium),
                                      topRight: Radius.circular(AppBorderRadius.medium),
                                    ),
                                    child: Image.network(
                                      widget.product.imageUrl,
                                      height: isCompactCard ? 80 : 100,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          height: isCompactCard ? 80 : 100,
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                if (widget.product.discountPrice != null &&
                                    widget.product.discountPrice! > 0)
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        borderRadius: BorderRadius.circular(
                                          AppBorderRadius.small,
                                        ),
                                      ),
                                      child: Text(
                                        '${(((widget.product.price - widget.product.discountPrice!) / widget.product.price) * 100).round()}% OFF',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                // Stock status overlay
                                if (widget.product.stock <= 0)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(AppBorderRadius.medium),
                                          topRight: Radius.circular(AppBorderRadius.medium),
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'OUT OF\nSTOCK',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                // Stock indicators
                                if (widget.product.stock > 0)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStockStatusColor(widget.product.stock),
                                        borderRadius: BorderRadius.circular(
                                          AppBorderRadius.small,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getStockStatusIcon(widget.product.stock),
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _getStockStatusText(widget.product.stock),
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            // Product Details
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.product.name,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isCompactCard ? 10 : 12,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            widget.product.unit,
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: _getStockStatusColor(widget.product.stock),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            '₹${(widget.product.discountPrice != null && widget.product.discountPrice! > 0) ? widget.product.discountPrice! : widget.product.price}',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                              fontSize: isCompactCard ? 10 : 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        if (widget.product.discountPrice != null &&
                                            widget.product.discountPrice! > 0)
                                          Flexible(
                                            child: Text(
                                              '₹${widget.product.price}',
                                              style: AppTextStyles.bodySmall.copyWith(
                                                decoration: TextDecoration.lineThrough,
                                                color: AppColors.textSecondary,
                                                fontSize: 8,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Add to Cart Button
                            if (widget.product.stock > 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                  vertical: 4.0,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (isInCart) {
                                        // Navigate to cart
                                        Navigator.pushNamed(context, '/cart');
                                      } else {
                                        // Add to cart
                                        final success = await cartProvider.addToCart(
                                          widget.product,
                                          1,
                                        );
                                        if (context.mounted) {
                                          if (success) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('${widget.product.name} added to cart'),
                                                duration: const Duration(seconds: 1),
                                                backgroundColor: AppColors.success,
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
                      // Hover overlay with product details
                      if (_isHovered)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.product.name,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.product.description,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white70,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Icon(
                                      _getStockStatusIcon(widget.product.stock),
                                      color: _getStockStatusColor(widget.product.stock),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getStockStatusText(widget.product.stock),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Category: ${widget.product.categoryName}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
