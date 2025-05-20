import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/user_model.dart';
import 'package:smart_kirana/providers/address_provider.dart';
import 'package:smart_kirana/screens/home/location_picker_screen.dart';
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
  final _labelController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  bool _isDefault = false;
  double _latitude = 0.0;
  double _longitude = 0.0;

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

  // Open location picker
  Future<void> _openLocationPicker() async {
    try {
      LatLng? initialLocation;

      // Use existing coordinates if available
      if (_latitude != 0.0 && _longitude != 0.0) {
        initialLocation = LatLng(_latitude, _longitude);
      }

      final result =
          await Navigator.pushNamed(
                context,
                LocationPickerScreen.routeName,
                arguments: {'initialLocation': initialLocation},
              )
              as Map<String, dynamic>?;

      if (result != null && mounted) {
        final LatLng location = result['location'];
        final String address = result['address'];

        setState(() {
          _latitude = location.latitude;
          _longitude = location.longitude;
        });

        // Parse the address and fill the form fields
        _parseAndFillAddress(address);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening location picker: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Parse address string and fill form fields
  void _parseAndFillAddress(String address) {
    try {
      final addressParts = address.split(', ');

      if (addressParts.isNotEmpty) {
        // First part is usually the street/building
        _addressLineController.text = addressParts.first;

        // Try to extract city, state, and pincode from remaining parts
        for (int i = 1; i < addressParts.length; i++) {
          final part = addressParts[i].trim();

          // Check if it's a pincode (6 digits)
          if (RegExp(r'^\d{6}$').hasMatch(part)) {
            _pincodeController.text = part;
          }
          // Check if it looks like a state (common Indian states)
          else if (part.toLowerCase().contains('delhi') ||
              part.toLowerCase().contains('mumbai') ||
              part.toLowerCase().contains('bangalore') ||
              part.toLowerCase().contains('chennai') ||
              part.toLowerCase().contains('kolkata') ||
              part.toLowerCase().contains('hyderabad') ||
              part.toLowerCase().contains('pune') ||
              part.toLowerCase().contains('ahmedabad') ||
              part.toLowerCase().contains('jaipur') ||
              part.toLowerCase().contains('lucknow') ||
              part.toLowerCase().contains('kanpur') ||
              part.toLowerCase().contains('nagpur') ||
              part.toLowerCase().contains('indore') ||
              part.toLowerCase().contains('thane') ||
              part.toLowerCase().contains('bhopal') ||
              part.toLowerCase().contains('visakhapatnam') ||
              part.toLowerCase().contains('pimpri') ||
              part.toLowerCase().contains('patna') ||
              part.toLowerCase().contains('vadodara') ||
              part.toLowerCase().contains('ghaziabad') ||
              part.toLowerCase().contains('ludhiana') ||
              part.toLowerCase().contains('agra') ||
              part.toLowerCase().contains('nashik') ||
              part.toLowerCase().contains('faridabad') ||
              part.toLowerCase().contains('meerut') ||
              part.toLowerCase().contains('rajkot') ||
              part.toLowerCase().contains('kalyan') ||
              part.toLowerCase().contains('vasai') ||
              part.toLowerCase().contains('varanasi') ||
              part.toLowerCase().contains('srinagar') ||
              part.toLowerCase().contains('aurangabad') ||
              part.toLowerCase().contains('dhanbad') ||
              part.toLowerCase().contains('amritsar') ||
              part.toLowerCase().contains('navi mumbai') ||
              part.toLowerCase().contains('allahabad') ||
              part.toLowerCase().contains('ranchi') ||
              part.toLowerCase().contains('howrah') ||
              part.toLowerCase().contains('coimbatore') ||
              part.toLowerCase().contains('jabalpur') ||
              part.toLowerCase().contains('gwalior') ||
              part.toLowerCase().contains('vijayawada') ||
              part.toLowerCase().contains('jodhpur') ||
              part.toLowerCase().contains('madurai') ||
              part.toLowerCase().contains('raipur') ||
              part.toLowerCase().contains('kota') ||
              part.toLowerCase().contains('guwahati') ||
              part.toLowerCase().contains('chandigarh') ||
              part.toLowerCase().contains('solapur') ||
              part.toLowerCase().contains('hubli') ||
              part.toLowerCase().contains('tiruchirappalli') ||
              part.toLowerCase().contains('bareilly') ||
              part.toLowerCase().contains('mysore') ||
              part.toLowerCase().contains('tiruppur') ||
              part.toLowerCase().contains('gurgaon') ||
              part.toLowerCase().contains('aligarh') ||
              part.toLowerCase().contains('jalandhar') ||
              part.toLowerCase().contains('bhubaneswar') ||
              part.toLowerCase().contains('salem') ||
              part.toLowerCase().contains('warangal') ||
              part.toLowerCase().contains('mira') ||
              part.toLowerCase().contains('bhiwandi') ||
              part.toLowerCase().contains('saharanpur') ||
              part.toLowerCase().contains('gorakhpur') ||
              part.toLowerCase().contains('bikaner') ||
              part.toLowerCase().contains('amravati') ||
              part.toLowerCase().contains('noida') ||
              part.toLowerCase().contains('jamshedpur') ||
              part.toLowerCase().contains('bhilai') ||
              part.toLowerCase().contains('cuttack') ||
              part.toLowerCase().contains('firozabad') ||
              part.toLowerCase().contains('kochi') ||
              part.toLowerCase().contains('nellore') ||
              part.toLowerCase().contains('bhavnagar') ||
              part.toLowerCase().contains('dehradun') ||
              part.toLowerCase().contains('durgapur') ||
              part.toLowerCase().contains('asansol') ||
              part.toLowerCase().contains('rourkela') ||
              part.toLowerCase().contains('nanded') ||
              part.toLowerCase().contains('kolhapur') ||
              part.toLowerCase().contains('ajmer') ||
              part.toLowerCase().contains('akola') ||
              part.toLowerCase().contains('gulbarga') ||
              part.toLowerCase().contains('jamnagar') ||
              part.toLowerCase().contains('ujjain') ||
              part.toLowerCase().contains('loni') ||
              part.toLowerCase().contains('siliguri') ||
              part.toLowerCase().contains('jhansi') ||
              part.toLowerCase().contains('ulhasnagar') ||
              part.toLowerCase().contains('jammu') ||
              part.toLowerCase().contains('sangli') ||
              part.toLowerCase().contains('mangalore') ||
              part.toLowerCase().contains('erode') ||
              part.toLowerCase().contains('belgaum') ||
              part.toLowerCase().contains('ambattur') ||
              part.toLowerCase().contains('tirunelveli') ||
              part.toLowerCase().contains('malegaon') ||
              part.toLowerCase().contains('gaya') ||
              part.toLowerCase().contains('jalgaon') ||
              part.toLowerCase().contains('udaipur') ||
              part.toLowerCase().contains('maheshtala')) {
            if (_cityController.text.isEmpty) {
              _cityController.text = part;
            } else if (_stateController.text.isEmpty) {
              _stateController.text = part;
            }
          }
          // Otherwise, treat as city if city is empty
          else if (_cityController.text.isEmpty) {
            _cityController.text = part;
          }
          // Or as state if state is empty
          else if (_stateController.text.isEmpty) {
            _stateController.text = part;
          }
        }
      }
    } catch (e) {
      // If parsing fails, just put the full address in the address line
      _addressLineController.text = address;
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
                      // Map Location Button
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(
                          bottom: AppPadding.medium,
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _openLocationPicker,
                          icon: const Icon(Icons.map),
                          label: const Text('Choose Location on Map'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),
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
