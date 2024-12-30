import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/user_model.dart';
import 'package:smart_kirana/providers/address_provider.dart';
import 'package:smart_kirana/providers/cart_provider.dart';
import 'package:smart_kirana/screens/home/address_screen.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/custom_button.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedPaymentMethod = 0;
  final List<String> _paymentMethods = ['Cash on Delivery', 'Online Payment'];
  UserAddress? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    final addressProvider = Provider.of<AddressProvider>(
      context,
      listen: false,
    );
    setState(() {
      _selectedAddress = addressProvider.defaultAddress;
    });
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Address
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Delivery Address', style: AppTextStyles.heading3),
                        TextButton(
                          onPressed: () => _selectAddress(context),
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppPadding.small),
                    // Address display
                    _selectedAddress != null
                        ? _buildAddressCard(_selectedAddress!)
                        : Container(
                          padding: const EdgeInsets.all(AppPadding.medium),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.small,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined),
                              const SizedBox(width: AppPadding.small),
                              Expanded(
                                child: Text(
                                  addressProvider.addresses.isEmpty
                                      ? 'No addresses found. Please add an address.'
                                      : 'Please select a delivery address',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ),
                              TextButton(
                                onPressed: () => _selectAddress(context),
                                child: Text(
                                  addressProvider.addresses.isEmpty
                                      ? 'Add'
                                      : 'Select',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppPadding.medium),

            // Payment Method
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Method', style: AppTextStyles.heading3),
                    const SizedBox(height: AppPadding.small),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _paymentMethods.length,
                      itemBuilder: (context, index) {
                        return RadioListTile(
                          title: Text(_paymentMethods[index]),
                          value: index,
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _selectedPaymentMethod = value as int;
                            });
                          },
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppPadding.medium),

            // Order Summary
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order Summary', style: AppTextStyles.heading3),
                    const SizedBox(height: AppPadding.medium),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Items (${cartProvider.cartItems.length})',
                          style: AppTextStyles.bodyMedium,
                        ),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
        child: CustomButton(
          text: 'Place Order',
          onPressed: () {
            if (_selectedAddress != null) {
              _placeOrder(context, cartProvider);
            }
          },
          enabled: _selectedAddress != null,
        ),
      ),
    );
  }

  Widget _buildAddressCard(UserAddress address) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary),
              const SizedBox(width: AppPadding.small),
              Expanded(
                child: Text(
                  address.addressLine,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.small),
          Text(
            '${address.city}, ${address.state} - ${address.pincode}',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _selectAddress(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                const AddressScreen(isSelecting: true, onAddressSelected: null),
        fullscreenDialog: true,
      ),
    );

    if (result != null && result is UserAddress && mounted) {
      setState(() {
        _selectedAddress = result;
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
      // Simulate order processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Close loading dialog
      if (mounted) navigator.pop();

      // Show success message
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      // Clear cart and navigate back to home
      await cartProvider.clearCart();
      if (mounted) {
        navigator.popUntil((route) => route.isFirst);
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
