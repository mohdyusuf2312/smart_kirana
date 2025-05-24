import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/user_model.dart';
import 'package:smart_kirana/providers/address_provider.dart';
import 'package:smart_kirana/providers/cart_provider.dart';
import 'package:smart_kirana/providers/order_provider.dart';
import 'package:smart_kirana/screens/home/address_screen.dart';
import 'package:smart_kirana/screens/payment/payment_screen.dart';
import 'package:smart_kirana/utils/constants.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  UserAddress? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    if (!mounted) return;

    try {
      final addressProvider = Provider.of<AddressProvider>(
        context,
        listen: false,
      );

      // Make sure addresses are loaded
      await addressProvider.loadAddresses();

      if (mounted) {
        setState(() {
          _selectedAddress = addressProvider.defaultAddress;
        });
      }
    } catch (e) {
      debugPrint('Error loading default address: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final addressProvider = Provider.of<AddressProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.primary,
            child: Row(
              children: [
                _buildProgressStep(1, 'Address', true),
                _buildProgressLine(true),
                _buildProgressStep(2, 'Payment', true),
                _buildProgressLine(true),
                _buildProgressStep(3, 'Review', true),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery Address Section
                  _buildSectionHeader(
                    'Delivery Address',
                    Icons.location_on,
                    _selectedAddress != null ? 'Change' : 'Select',
                    () => _selectAddress(context),
                  ),

                  // Address display
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child:
                        _selectedAddress != null
                            ? _buildAddressCard(_selectedAddress!)
                            : _buildEmptyAddressCard(addressProvider, context),
                  ),

                  const Divider(height: 32),

                  // Order Items Section
                  _buildSectionHeader(
                    'Order Items',
                    Icons.shopping_bag,
                    'Edit',
                    () {
                      Navigator.pop(context);
                    },
                  ),

                  // Order items list
                  _buildOrderItemsList(cartProvider),

                  const Divider(height: 32),

                  // Price Details Section
                  _buildSectionHeader(
                    'Price Details',
                    Icons.receipt_long,
                    null,
                    null,
                  ),

                  // Price breakdown
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildPriceDetails(cartProvider),
                  ),

                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '₹${cartProvider.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed:
                      _selectedAddress != null
                          ? () => _placeOrder(context, cartProvider)
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'PLACE ORDER',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, bool isActive) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.white : Colors.white.withAlpha(100),
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: TextStyle(
                  color: isActive ? AppColors.primary : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white.withAlpha(180),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Container(
      width: 20,
      height: 2,
      color: isActive ? Colors.white : Colors.white.withAlpha(100),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    String? actionText,
    VoidCallback? onAction,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (actionText != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
              ),
              child: Text(
                actionText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyAddressCard(
    AddressProvider addressProvider,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              addressProvider.addresses.isEmpty
                  ? 'No addresses found. Please add an address.'
                  : 'Please select a delivery address',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          ElevatedButton(
            onPressed: () => _selectAddress(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 36),
            ),
            child: Text(
              addressProvider.addresses.isEmpty ? 'ADD' : 'SELECT',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsList(CartProvider cartProvider) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: cartProvider.cartItems.length,
      separatorBuilder: (context, index) => const Divider(height: 16),
      itemBuilder: (context, index) {
        final item = cartProvider.cartItems[index];
        final product = item.product;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading image: $error');
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 24,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),

            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.unit} × ${item.quantity}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₹${(product.discountPrice ?? product.price).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (product.discountPrice != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '₹${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Item total
            Text(
              '₹${item.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPriceDetails(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          _buildPriceRow(
            'Item Total',
            '₹${cartProvider.subtotal.toStringAsFixed(2)}',
            isBold: false,
          ),
          const SizedBox(height: 8),
          _buildPriceRow(
            'Delivery Fee',
            cartProvider.deliveryFee > 0
                ? '₹${cartProvider.deliveryFee.toStringAsFixed(2)}'
                : 'FREE',
            isBold: false,
            valueColor:
                cartProvider.deliveryFee == 0 ? AppColors.success : null,
          ),
          const Divider(height: 24),
          _buildPriceRow(
            'Total Amount',
            '₹${cartProvider.total.toStringAsFixed(2)}',
            isBold: true,
            valueColor: AppColors.primary,
          ),
          if (cartProvider.deliveryFee == 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_shipping,
                    color: AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Yay! You got FREE delivery',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black : Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? (isBold ? Colors.black : Colors.grey.shade700),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard(UserAddress address) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            address.label != null
                                ? address.label!
                                : 'Delivery Address',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (address.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(26),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.addressLine,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${address.city}, ${address.state} - ${address.pincode}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (address.phoneNumber != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                const Icon(
                  Icons.phone,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Contact: ${address.phoneNumber!}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectAddress(BuildContext context) async {
    UserAddress? selectedAddress;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddressScreen(
              isSelecting: true,
              onAddressSelected: (address) {
                selectedAddress = address;
                Navigator.pop(context);
              },
            ),
        fullscreenDialog: true,
      ),
    );

    if (selectedAddress != null && mounted) {
      setState(() {
        _selectedAddress = selectedAddress;
      });
    }
  }

  Future<void> _placeOrder(
    BuildContext context,
    CartProvider cartProvider,
  ) async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Store context-related objects before the async gap
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppPadding.medium),
                Text('Processing your order...'),
              ],
            ),
          ),
    );

    try {
      // Get the order provider
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      // Create the order
      final orderId = await orderProvider.createOrder(
        cartItems: cartProvider.cartItems,
        subtotal: cartProvider.subtotal,
        deliveryFee: cartProvider.deliveryFee,
        discount: 0.0, // No discount for now
        totalAmount: cartProvider.total,
        deliveryAddress: _selectedAddress!,
        paymentMethod: "To be selected on payment screen",
        deliveryNotes: null, // No delivery notes for now
      );

      // Close loading dialog
      if (mounted) navigator.pop();

      if (orderId != null) {
        // Show success message
        // if (mounted) {
        //   scaffoldMessenger.showSnackBar(
        //     const SnackBar(
        //       content: Text('Order placed successfully!'),
        //       backgroundColor: AppColors.success,
        //     ),
        //   );
        // }

        // Always navigate to payment screen
        if (mounted) {
          navigator.pushNamed(
            PaymentScreen.routeName,
            arguments: {'orderId': orderId, 'amount': cartProvider.total},
          );
        }
      } else {
        // Show error message
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Failed to place order: ${orderProvider.error}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) navigator.pop();

      // Show error message
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to place order: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
