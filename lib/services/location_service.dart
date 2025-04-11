import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Properties
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoading = false;
  String? _error;

  // Getters
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize location service
  Future<bool> initialize() async {
    try {
      _setLoading(true);
      _error = null;
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('Location services are disabled. Please enable location services.');
        return false;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setError('Location permissions are denied');
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _setError('Location permissions are permanently denied, we cannot request permissions.');
        return false;
      }

      // Get current position
      await getCurrentPosition();
      return true;
    } catch (e) {
      _setError('Error initializing location service: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      _setLoading(true);
      _error = null;
      
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Get address from position
      await getAddressFromPosition(_currentPosition!);
      
      return _currentPosition;
    } catch (e) {
      _setError('Error getting current position: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Get address from position
  Future<String?> getAddressFromPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _currentAddress = _formatAddress(place);
        return _currentAddress;
      }
      return null;
    } catch (e) {
      _setError('Error getting address: $e');
      return null;
    }
  }

  // Format address
  String _formatAddress(Placemark place) {
    List<String> addressParts = [
      if (place.name != null && place.name!.isNotEmpty) place.name!,
      if (place.street != null && place.street!.isNotEmpty) place.street!,
      if (place.subLocality != null && place.subLocality!.isNotEmpty) place.subLocality!,
      if (place.locality != null && place.locality!.isNotEmpty) place.locality!,
      if (place.postalCode != null && place.postalCode!.isNotEmpty) place.postalCode!,
    ];
    
    return addressParts.join(', ');
  }

  // Calculate delivery time based on distance (simplified)
  String getEstimatedDeliveryTime() {
    // In a real app, this would use the distance to calculate actual delivery time
    // For now, we'll return a fixed time
    return '15 minutes';
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
  }

  void _setError(String? errorMessage) {
    _error = errorMessage;
  }
}
