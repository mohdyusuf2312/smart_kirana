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
        title: Text(isSelecting ? 'Select Delivery Address' : 'My Addresses'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!isSelecting)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await addressProvider.loadAddresses();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Addresses refreshed'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Header with count
          if (!addressProvider.isLoading &&
              addressProvider.addresses.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.primary.withAlpha(20),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${addressProvider.addresses.length} saved address${addressProvider.addresses.length > 1 ? 'es' : ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

          // Main content
          Expanded(
            child:
                addressProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : addressProvider.addresses.isEmpty
                    ? _buildEmptyAddresses()
                    : _buildAddressList(context, addressProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddressForm(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Add New Address'),
      ),
    );
  }

  Widget _buildEmptyAddresses() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_outlined,
                size: 80,
                color: AppColors.primary.withAlpha(180),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Addresses Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'You haven\'t added any delivery addresses yet. Add a new address to get started with your orders.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Builder(
              builder:
                  (context) => ElevatedButton.icon(
                    onPressed: () => _navigateToAddressForm(context),
                    icon: const Icon(Icons.add_location_alt),
                    label: const Text('ADD NEW ADDRESS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressList(
    BuildContext context,
    AddressProvider addressProvider,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: addressProvider.addresses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final address = addressProvider.addresses[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(30),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap:
                  isSelecting && onAddressSelected != null
                      ? () => onAddressSelected!(address)
                      : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with label and default badge
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
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  address.label != null
                                      ? address.label!
                                      : 'Address',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
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
                                    borderRadius: BorderRadius.circular(12),
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
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Address details
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address.addressLine,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${address.city}, ${address.state} - ${address.pincode}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (address.phoneNumber != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  address.phoneNumber!,
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
                    ),

                    // Action buttons
                    if (!isSelecting) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (!address.isDefault)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed:
                                    () =>
                                        _setDefaultAddress(context, address.id),
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                ),
                                label: const Text('Set Default'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          if (!address.isDefault) const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: IconButton(
                                    onPressed:
                                        () => _navigateToAddressForm(
                                          context,
                                          address,
                                        ),
                                    icon: const Icon(
                                      Icons.edit,
                                      color: AppColors.primary,
                                    ),
                                    tooltip: 'Edit',
                                  ),
                                ),
                                Expanded(
                                  child: IconButton(
                                    onPressed:
                                        () =>
                                            _deleteAddress(context, address.id),
                                    icon: const Icon(
                                      Icons.delete,
                                      color: AppColors.error,
                                    ),
                                    tooltip: 'Delete',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Select button for address selection mode
                    if (isSelecting && onAddressSelected != null) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => onAddressSelected!(address),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('DELIVER HERE'),
                        ),
                      ),
                    ],
                  ],
                ),
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
        // Store scaffold messenger before async gap
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        // Force refresh the address provider
        await Provider.of<AddressProvider>(
          context,
          listen: false,
        ).loadAddresses();

        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
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
