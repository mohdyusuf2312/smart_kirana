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
  DateTime? _lastLocationUpdate;

  // Cache duration for location updates (5 minutes)
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Getters
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Check if cached location is still valid
  bool get _isCacheValid {
    if (_lastLocationUpdate == null || _currentPosition == null) {
      return false;
    }
    return DateTime.now().difference(_lastLocationUpdate!) <
        _cacheValidDuration;
  }

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

  // Get current position with optimized settings for faster response
  Future<Position?> getCurrentPosition() async {
    try {
      _setLoading(true);
      _error = null;

      // Return cached position if still valid
      if (_isCacheValid) {
        _setLoading(false);
        return _currentPosition;
      }

      // Try to get last known position first for immediate response
      Position? lastKnownPosition;
      try {
        lastKnownPosition = await Geolocator.getLastKnownPosition();
        if (lastKnownPosition != null) {
          // Use last known position temporarily while getting fresh position
          _currentPosition = lastKnownPosition;
          // Get address from last known position in background
          getAddressFromPosition(lastKnownPosition);
        }
      } catch (e) {
        // Ignore errors from last known position
      }

      // Get fresh position with optimized settings
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.low, // Use low accuracy for faster response
        timeLimit: const Duration(
          seconds: 5,
        ), // Reduced timeout for faster response
      );

      // Update cache timestamp
      _lastLocationUpdate = DateTime.now();

      // Get address from fresh position
      await getAddressFromPosition(_currentPosition!);

      return _currentPosition;
    } catch (e) {
      // If we have a last known position, use it as fallback
      if (_currentPosition != null) {
        return _currentPosition;
      }
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
