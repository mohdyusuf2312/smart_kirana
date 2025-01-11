import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/user_model.dart';
import 'package:smart_kirana/providers/address_provider.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/custom_button.dart';
import 'package:smart_kirana/widgets/custom_input_field.dart';

class AddressFormScreen extends StatefulWidget {
  final UserAddress? address;
  final bool isEdit;

  const AddressFormScreen({super.key, this.address, this.isEdit = false});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressLineController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.address != null) {
      _addressLineController.text = widget.address!.addressLine;
      _cityController.text = widget.address!.city;
      _stateController.text = widget.address!.state;
      _pincodeController.text = widget.address!.pincode;
      _isDefault = widget.address!.isDefault;
    }
  }

  @override
  void dispose() {
    _addressLineController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      final addressProvider = Provider.of<AddressProvider>(
        context,
        listen: false,
      );

      final address = UserAddress(
        id:
            widget.isEdit
                ? widget.address!.id
                : DateTime.now().millisecondsSinceEpoch.toString(),
        addressLine: _addressLineController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        latitude: widget.isEdit ? widget.address!.latitude : 0.0,
        longitude: widget.isEdit ? widget.address!.longitude : 0.0,
        isDefault: _isDefault,
      );

      try {
        if (widget.isEdit) {
          await addressProvider.updateAddress(address);
        } else {
          await addressProvider.addAddress(address);
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save address: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressProvider = Provider.of<AddressProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Address' : 'Add New Address'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body:
          addressProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(AppPadding.medium),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomInputField(
                        label: 'Address Line',
                        hint: 'Enter your full address',
                        controller: _addressLineController,
                        keyboardType: TextInputType.streetAddress,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppPadding.medium),
                      CustomInputField(
                        label: 'City',
                        hint: 'Enter your city',
                        controller: _cityController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your city';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppPadding.medium),
                      CustomInputField(
                        label: 'State',
                        hint: 'Enter your state',
                        controller: _stateController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your state';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppPadding.medium),
                      CustomInputField(
                        label: 'Pincode',
                        hint: 'Enter your pincode',
                        controller: _pincodeController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your pincode';
                          }
                          if (value.length != 6) {
                            return 'Pincode must be 6 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppPadding.medium),
                      SwitchListTile(
                        title: const Text('Set as default address'),
                        value: _isDefault,
                        onChanged: (value) {
                          setState(() {
                            _isDefault = value;
                          });
                        },
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: AppPadding.large),
                      CustomButton(
                        text: widget.isEdit ? 'Update Address' : 'Save Address',
                        onPressed: _saveAddress,
                        isLoading: addressProvider.isLoading,
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
