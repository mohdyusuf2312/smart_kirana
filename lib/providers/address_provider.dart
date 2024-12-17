import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_kirana/models/user_model.dart';
import 'package:smart_kirana/providers/auth_provider.dart';

class AddressProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthProvider _authProvider;
  
  List<UserAddress> _addresses = [];
  bool _isLoading = false;
  String? _error;

  AddressProvider({
    required AuthProvider authProvider,
  }) : _authProvider = authProvider {
    _loadAddresses();
  }

  // Getters
  List<UserAddress> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserAddress? get defaultAddress => _addresses.isNotEmpty 
      ? _addresses.firstWhere((address) => address.isDefault, orElse: () => _addresses.first)
      : null;

  // Load addresses from Firestore
  Future<void> _loadAddresses() async {
    if (_authProvider.currentUser == null) return;
    
    _setLoading(true);
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(_authProvider.currentUser!.uid)
          .get();
      
      if (userDoc.exists && userDoc.data()!.containsKey('addresses')) {
        final addressesData = userDoc.data()!['addresses'] as List<dynamic>;
        
        _addresses = addressesData.map((data) {
          return UserAddress.fromMap(data as Map<String, dynamic>, data['id'] as String);
        }).toList();
      } else {
        _addresses = [];
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load addresses: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Add new address
  Future<void> addAddress(UserAddress address) async {
    if (_authProvider.currentUser == null) return;
    
    _setLoading(true);
    try {
      // If this is the first address or marked as default, ensure it's the only default
      if (_addresses.isEmpty || address.isDefault) {
        // Update all other addresses to not be default
        for (var i = 0; i < _addresses.length; i++) {
          if (_addresses[i].isDefault) {
            _addresses[i] = _addresses[i].copyWith(isDefault: false);
          }
        }
      }
      
      // Add the new address
      _addresses.add(address);
      
      // Update Firestore
      await _updateFirestoreAddresses();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to add address: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update existing address
  Future<void> updateAddress(UserAddress updatedAddress) async {
    if (_authProvider.currentUser == null) return;
    
    _setLoading(true);
    try {
      final index = _addresses.indexWhere((address) => address.id == updatedAddress.id);
      
      if (index >= 0) {
        // If this address is being set as default, update all others
        if (updatedAddress.isDefault && !_addresses[index].isDefault) {
          for (var i = 0; i < _addresses.length; i++) {
            if (i != index && _addresses[i].isDefault) {
              _addresses[i] = _addresses[i].copyWith(isDefault: false);
            }
          }
        }
        
        // Update the address
        _addresses[index] = updatedAddress;
        
        // Update Firestore
        await _updateFirestoreAddresses();
        
        notifyListeners();
      } else {
        throw Exception('Address not found');
      }
    } catch (e) {
      _setError('Failed to update address: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Delete address
  Future<void> deleteAddress(String addressId) async {
    if (_authProvider.currentUser == null) return;
    
    _setLoading(true);
    try {
      final index = _addresses.indexWhere((address) => address.id == addressId);
      
      if (index >= 0) {
        final wasDefault = _addresses[index].isDefault;
        
        // Remove the address
        _addresses.removeAt(index);
        
        // If the deleted address was the default and we have other addresses,
        // set the first one as default
        if (wasDefault && _addresses.isNotEmpty) {
          _addresses[0] = _addresses[0].copyWith(isDefault: true);
        }
        
        // Update Firestore
        await _updateFirestoreAddresses();
        
        notifyListeners();
      } else {
        throw Exception('Address not found');
      }
    } catch (e) {
      _setError('Failed to delete address: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Set address as default
  Future<void> setDefaultAddress(String addressId) async {
    if (_authProvider.currentUser == null) return;
    
    _setLoading(true);
    try {
      // Update all addresses
      for (var i = 0; i < _addresses.length; i++) {
        _addresses[i] = _addresses[i].copyWith(
          isDefault: _addresses[i].id == addressId,
        );
      }
      
      // Update Firestore
      await _updateFirestoreAddresses();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to set default address: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update addresses in Firestore
  Future<void> _updateFirestoreAddresses() async {
    if (_authProvider.currentUser == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_authProvider.currentUser!.uid)
          .update({
        'addresses': _addresses.map((address) => address.toMap()).toList(),
      });
    } catch (e) {
      _setError('Failed to update addresses in Firestore: ${e.toString()}');
      rethrow;
    }
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}
