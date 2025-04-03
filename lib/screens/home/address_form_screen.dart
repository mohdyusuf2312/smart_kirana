import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/user_model.dart';
import 'package:smart_kirana/providers/address_provider.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/custom_button.dart';
import 'package:smart_kirana/widgets/custom_input_field.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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
  final _labelController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  bool _isDefault = false;
  bool _isLoadingLocation = false;
  double _latitude = 0.0;
  double _longitude = 0.0;
  String _locationError = '';

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.address != null) {
      _addressLineController.text = widget.address!.addressLine;
      _cityController.text = widget.address!.city;
      _stateController.text = widget.address!.state;
      _pincodeController.text = widget.address!.pincode;
      _isDefault = widget.address!.isDefault;
      _latitude = widget.address!.latitude;
      _longitude = widget.address!.longitude;
      _labelController.text = widget.address!.label ?? '';
      _phoneNumberController.text = widget.address!.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _addressLineController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _labelController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoadingLocation = true;
      _locationError = '';
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _locationError =
              'Location services are disabled. Please enable location services.';
          _isLoadingLocation = false;
        });
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _locationError = 'Location permission denied';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationError =
              'Location permissions are permanently denied. Please enable in settings.';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      ).catchError((error) {
        throw Exception('Failed to get location: $error');
      });

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      try {
        // Get address from coordinates
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (!mounted) return;
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          setState(() {
            final street = place.street ?? '';
            final subLocality = place.subLocality ?? '';
            _addressLineController.text =
                street.isNotEmpty
                    ? (subLocality.isNotEmpty
                        ? '$street, $subLocality'
                        : street)
                    : (subLocality.isNotEmpty ? subLocality : '');
            _cityController.text = place.locality ?? '';
            _stateController.text = place.administrativeArea ?? '';
            _pincodeController.text = place.postalCode ?? '';
          });
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _locationError = 'Got location but failed to get address details: $e';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Error getting location: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      // Store context-related objects before the async gap
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      // Show loading indicator
      setState(() {
        // This will trigger the loading indicator in the build method
      });

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
        latitude: _latitude,
        longitude: _longitude,
        isDefault: _isDefault,
        label:
            _labelController.text.trim().isNotEmpty
                ? _labelController.text.trim()
                : null,
        phoneNumber:
            _phoneNumberController.text.trim().isNotEmpty
                ? _phoneNumberController.text.trim()
                : null,
      );

      try {
        if (widget.isEdit) {
          await addressProvider.updateAddress(address);
        } else {
          await addressProvider.addAddress(address);
        }

        if (mounted) {
          // Use the stored navigator to avoid context issues
          navigator.pop(true);
        }
      } catch (e) {
        if (mounted) {
          // Use the stored scaffoldMessenger to avoid context issues
          scaffoldMessenger.showSnackBar(
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
                      // Location Button
                      ElevatedButton.icon(
                        onPressed:
                            _isLoadingLocation ? null : _getCurrentLocation,
                        icon: Icon(
                          _isLoadingLocation
                              ? Icons.hourglass_empty
                              : Icons.my_location,
                        ),
                        label: Text(
                          _isLoadingLocation
                              ? 'Getting Location...'
                              : 'Use Current Location',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                      ),

                      if (_locationError.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _locationError,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      const SizedBox(height: AppPadding.medium),

                      // Address Label (Home, Work, etc.)
                      CustomInputField(
                        label: 'Address Label (Optional)',
                        hint: 'E.g., Home, Work, etc.',
                        controller: _labelController,
                      ),

                      const SizedBox(height: AppPadding.medium),

                      // Address Line
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

                      // City
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

                      // State
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

                      // Pincode
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

                      // Phone Number for delivery
                      CustomInputField(
                        label: 'Phone Number for Delivery (Optional)',
                        hint: 'Enter phone number for delivery',
                        controller: _phoneNumberController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: AppPadding.medium),

                      // Default Address Switch
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

                      // Save Button
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
