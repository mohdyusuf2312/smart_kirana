import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_kirana/utils/geocoding_helper.dart';

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
        _setError(
          'Location services are disabled. Please enable location services.',
        );
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
        _setError(
          'Location permissions are permanently denied, we cannot request permissions.',
        );
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
        desiredAccuracy:
            LocationAccuracy
                .medium, // Changed from high to medium for faster response
        timeLimit: const Duration(seconds: 10), // Added timeout
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

  // Get address from position using the robust geocoding helper
  Future<String?> getAddressFromPosition(Position position) async {
    try {
      // Use our robust geocoding helper with fallback strategies
      LatLng location = LatLng(position.latitude, position.longitude);
      String address = await GeocodingHelper.getAddressFromCoordinates(
        location,
      );

      // Don't set coordinates as the address - keep it as null if geocoding fails
      if (address.startsWith('Lat:')) {
        _currentAddress = null;
        return null;
      }

      _currentAddress = address;
      return _currentAddress;
    } catch (e) {
      _setError('Error getting address: $e');
      _currentAddress = null;
      return null;
    }
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
