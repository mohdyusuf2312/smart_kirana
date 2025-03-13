import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/cart_item_model.dart';
import 'package:smart_kirana/providers/cart_provider.dart';
import 'package:smart_kirana/screens/home/checkout_screen.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/custom_button.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return cartProvider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : cartProvider.cartItems.isEmpty
        ? _buildEmptyCart()
        : _buildCartContent(context, cartProvider);
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: AppColors.textSecondary.withAlpha(128),
          ),
          const SizedBox(height: AppPadding.medium),
          Text('Your cart is empty', style: AppTextStyles.heading3),
          const SizedBox(height: AppPadding.small),
          Text(
            'Add items to your cart to see them here',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, CartProvider cartProvider) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppPadding.medium),
            itemCount: cartProvider.cartItems.length,
            itemBuilder: (context, index) {
              final cartItem = cartProvider.cartItems[index];
              return _buildCartItemCard(context, cartItem, cartProvider);
            },
          ),
        ),
        _buildCartSummary(context, cartProvider),
      ],
    );
  }

  Widget _buildCartItemCard(
    BuildContext context,
    CartItemModel cartItem,
    CartProvider cartProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppPadding.medium),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppBorderRadius.small),
              child: Image.network(
                cartItem.product.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: AppColors.background,
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
            const SizedBox(width: AppPadding.medium),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.product.name,
                    style: AppTextStyles.heading3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppPadding.small),
                  Text(
                    '₹${(cartItem.product.discountPrice != null && cartItem.product.discountPrice! > 0) ? cartItem.product.discountPrice! : cartItem.product.price}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (cartItem.product.discountPrice != null &&
                      cartItem.product.discountPrice! > 0)
                    Text(
                      '₹${cartItem.product.price}',
                      style: AppTextStyles.bodySmall.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: AppPadding.small),
                  Row(
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove,
                        onPressed: () {
                          if (cartItem.quantity > 1) {
                            cartProvider.updateCartItemQuantity(
                              cartItem.product.id,
                              cartItem.quantity - 1,
                            );
                          } else {
                            cartProvider.removeFromCart(cartItem.product.id);
                          }
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppPadding.medium,
                          vertical: AppPadding.small,
                        ),
                        child: Text(
                          '${cartItem.quantity}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildQuantityButton(
                        icon: Icons.add,
                        onPressed: () {
                          cartProvider.updateCartItemQuantity(
                            cartItem.product.id,
                            cartItem.quantity + 1,
                          );
                        },
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        onPressed: () {
                          cartProvider.removeFromCart(cartItem.product.id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
          padding: const EdgeInsets.all(4.0),
          child: Icon(icon, size: 16, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context, CartProvider cartProvider) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: AppTextStyles.bodyMedium),
              Text(
                '₹${cartProvider.subtotal.toStringAsFixed(2)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.small),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery Fee', style: AppTextStyles.bodyMedium),
              Text(
                '₹${cartProvider.deliveryFee.toStringAsFixed(2)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Free delivery message
          if (cartProvider.subtotal < 200)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(AppBorderRadius.small),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add ₹${(200 - cartProvider.subtotal).toStringAsFixed(2)} more to get FREE delivery!',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${cartProvider.total.toStringAsFixed(2)}',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.medium),
          CustomButton(
            text: 'Proceed to Checkout',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CheckoutScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
