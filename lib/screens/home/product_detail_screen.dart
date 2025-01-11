import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/product_model.dart';
import 'package:smart_kirana/providers/cart_provider.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/custom_button.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final isInCart = cartProvider.isInCart(widget.product.id);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product-${widget.product.id}',
                child: Image.network(
                  widget.product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.background,
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 100,
                        color: AppColors.textSecondary,
                      ),
                    );
                  },
                ),
              ),
            ),
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.arrow_back, color: AppColors.textPrimary),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    isInCart
                        ? Icons.shopping_cart
                        : Icons.shopping_cart_outlined,
                    color: isInCart ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                onPressed: () {
                  if (isInCart) {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/cart');
                  }
                },
              ),
              const SizedBox(width: AppPadding.small),
            ],
          ),

          // Product Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppPadding.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name and Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: AppTextStyles.heading1,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${widget.product.discountPrice > 0 ? widget.product.discountPrice : widget.product.price}',
                            style: AppTextStyles.heading2.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.product.discountPrice > 0)
                            Text(
                              '₹${widget.product.price}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppPadding.small),

                  // Category and Stock
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppPadding.small,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(26),
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.small,
                          ),
                        ),
                        child: Text(
                          widget.product.categoryName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppPadding.small),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppPadding.small,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              widget.product.stock > 0
                                  ? AppColors.success.withAlpha(26)
                                  : AppColors.error.withAlpha(26),
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.small,
                          ),
                        ),
                        child: Text(
                          widget.product.stock > 0
                              ? 'In Stock'
                              : 'Out of Stock',
                          style: AppTextStyles.bodySmall.copyWith(
                            color:
                                widget.product.stock > 0
                                    ? AppColors.success
                                    : AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppPadding.medium),

                  // Description
                  Text('Description', style: AppTextStyles.heading3),
                  const SizedBox(height: AppPadding.small),
                  Text(
                    widget.product.description,
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppPadding.large),

                  // Quantity Selector
                  if (widget.product.stock > 0) ...[
                    Text('Quantity', style: AppTextStyles.heading3),
                    const SizedBox(height: AppPadding.small),
                    Row(
                      children: [
                        _buildQuantityButton(
                          icon: Icons.remove,
                          onPressed: _decrementQuantity,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppPadding.medium,
                            vertical: AppPadding.small,
                          ),
                          child: Text(
                            '$_quantity',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildQuantityButton(
                          icon: Icons.add,
                          onPressed: _incrementQuantity,
                        ),
                        const Spacer(),
                        Text(
                          'Available: ${widget.product.stock}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppPadding.large),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          widget.product.stock > 0
              ? Container(
                padding: const EdgeInsets.all(AppPadding.medium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13), // 0.05 * 255 = 13
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: isInCart ? 'Update Cart' : 'Add to Cart',
                        onPressed: () {
                          if (isInCart) {
                            cartProvider.updateCartItemQuantity(
                              widget.product.id,
                              _quantity,
                            );
                          } else {
                            cartProvider.addToCart(widget.product, _quantity);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isInCart
                                    ? 'Cart updated successfully'
                                    : 'Added to cart successfully',
                              ),
                              backgroundColor: AppColors.success,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: Icons.shopping_cart,
                      ),
                    ),
                  ],
                ),
              )
              : Container(
                padding: const EdgeInsets.all(AppPadding.medium),
                color: Colors.white,
                child: CustomButton(
                  text: 'Out of Stock',
                  onPressed: () {}, // Empty function since button is disabled
                  enabled: false,
                ),
              ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textSecondary.withAlpha(76)),
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
