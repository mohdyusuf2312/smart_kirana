import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/user_model.dart';
import 'package:smart_kirana/providers/address_provider.dart';
import 'package:smart_kirana/screens/home/address_form_screen.dart';
import 'package:smart_kirana/utils/constants.dart';

class AddressScreen extends StatelessWidget {
  final bool isSelecting;
  final Function(UserAddress)? onAddressSelected;

  const AddressScreen({
    super.key,
    this.isSelecting = false,
    this.onAddressSelected,
  });

  @override
  Widget build(BuildContext context) {
    final addressProvider = Provider.of<AddressProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isSelecting ? 'Select Address' : 'My Addresses'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body:
          addressProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : addressProvider.addresses.isEmpty
              ? _buildEmptyAddresses()
              : _buildAddressList(context, addressProvider),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddressForm(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyAddresses() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 100,
            color: AppColors.textSecondary.withAlpha(128),
          ),
          const SizedBox(height: AppPadding.medium),
          Text('No Addresses Found', style: AppTextStyles.heading3),
          const SizedBox(height: AppPadding.small),
          Text(
            'Add a new address to get started',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList(
    BuildContext context,
    AddressProvider addressProvider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppPadding.medium),
      itemCount: addressProvider.addresses.length,
      itemBuilder: (context, index) {
        final address = addressProvider.addresses[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: AppPadding.medium),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          ),
          child: InkWell(
            onTap:
                isSelecting && onAddressSelected != null
                    ? () => onAddressSelected!(address)
                    : null,
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            child: Padding(
              padding: const EdgeInsets.all(AppPadding.medium),
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
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (address.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(26),
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.small,
                            ),
                          ),
                          child: Text(
                            'Default',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
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
                  const SizedBox(height: AppPadding.medium),
                  if (!isSelecting)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!address.isDefault)
                          TextButton.icon(
                            onPressed:
                                () => _setDefaultAddress(context, address.id),
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 16,
                            ),
                            label: const Text('Set as Default'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        const SizedBox(width: AppPadding.small),
                        TextButton.icon(
                          onPressed:
                              () => _navigateToAddressForm(context, address),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppPadding.small),
                        TextButton.icon(
                          onPressed: () => _deleteAddress(context, address.id),
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Delete'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _navigateToAddressForm(
    BuildContext context, [
    UserAddress? address,
  ]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                AddressFormScreen(address: address, isEdit: address != null),
      ),
    );

    if (result == true) {
      // Refresh addresses
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              address != null ? 'Address updated' : 'Address added',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _setDefaultAddress(
    BuildContext context,
    String addressId,
  ) async {
    try {
      final addressProvider = Provider.of<AddressProvider>(
        context,
        listen: false,
      );
      await addressProvider.setDefaultAddress(addressId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default address updated'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update default address: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteAddress(BuildContext context, String addressId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Address'),
            content: const Text(
              'Are you sure you want to delete this address?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final addressProvider = Provider.of<AddressProvider>(
          context,
          listen: false,
        );
        await addressProvider.deleteAddress(addressId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address deleted'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete address: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
