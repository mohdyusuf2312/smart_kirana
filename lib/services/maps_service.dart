import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapsService {
  // Singleton pattern
  static final MapsService _instance = MapsService._internal();
  factory MapsService() => _instance;
  MapsService._internal();

  // Properties
  String? _apiKey;
  bool _isInitialized = false;
  String? _error;

  // Getters
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  // Initialize the maps service
  Future<bool> initialize() async {
    try {
      if (kDebugMode) {
        print('MapsService: Starting initialization...');
      }

      // Ensure dotenv is loaded
      if (!dotenv.isInitialized) {
        if (kDebugMode) {
          print('MapsService: Loading .env file...');
        }
        await dotenv.load(fileName: ".env");
      }

      _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

      if (kDebugMode) {
        print('MapsService: API Key loaded: ${_apiKey != null ? 'Yes' : 'No'}');
        if (_apiKey != null) {
          print('MapsService: API Key length: ${_apiKey!.length}');
          print(
            'MapsService: API Key starts with: ${_apiKey!.substring(0, min(10, _apiKey!.length))}...',
          );
        }
      }

      if (_apiKey == null || _apiKey!.isEmpty) {
        _error = 'Google Maps API key not found in .env file';
        if (kDebugMode) {
          print('MapsService: Error - $_error');
        }
        return false;
      }

      // Validate API key format
      if (!_apiKey!.startsWith('AIza')) {
        _error = 'Invalid Google Maps API key format';
        if (kDebugMode) {
          print('MapsService: Error - $_error');
        }
        return false;
      }

      _isInitialized = true;
      _error = null;

      if (kDebugMode) {
        print('MapsService: Initialization successful!');
      }

      return true;
    } catch (e) {
      _error = 'Failed to initialize Maps Service: $e';
      if (kDebugMode) {
        print('MapsService: Exception during initialization - $_error');
      }
      return false;
    }
  }

  // Create markers for order tracking
  Set<Marker> createOrderTrackingMarkers({
    required LatLng deliveryLocation,
    LatLng? currentLocation,
    String? deliveryAgentName,
    bool includeStoreMarker = true,
  }) {
    Set<Marker> markers = {};

    // Delivery location marker
    markers.add(
      Marker(
        markerId: const MarkerId('delivery_location'),
        position: deliveryLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(
          title: 'Delivery Location',
          snippet: 'Your order will be delivered here',
        ),
      ),
    );

    // Current location marker (delivery agent)
    if (currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: currentLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: deliveryAgentName ?? 'Delivery Agent',
            snippet: 'Current location',
          ),
        ),
      );
    }

    return markers;
  }

  // Get camera position to show all markers (delivery agent, customer)
  CameraPosition getCameraPositionForBounds({
    required LatLng deliveryLocation,
    LatLng? currentLocation,
    bool includeStore = true,
  }) {
    List<LatLng> locations = [deliveryLocation];

    // Add current location if available
    if (currentLocation != null) {
      locations.add(currentLocation);
    }

    if (locations.length == 1) {
      return CameraPosition(target: locations.first, zoom: 15.0);
    }

    // Calculate bounds for all locations
    double minLat = locations.map((l) => l.latitude).reduce(min);
    double maxLat = locations.map((l) => l.latitude).reduce(max);
    double minLng = locations.map((l) => l.longitude).reduce(min);
    double maxLng = locations.map((l) => l.longitude).reduce(max);

    // Calculate center
    LatLng center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

    // Calculate zoom level based on the span
    double latSpan = maxLat - minLat;
    double lngSpan = maxLng - minLng;
    double maxSpan = max(latSpan, lngSpan);

    double zoom = 15.0;
    if (maxSpan > 0.1) {
      zoom = 9.0; // Very wide area
    } else if (maxSpan > 0.05) {
      zoom = 10.0; // Wide area
    } else if (maxSpan > 0.02) {
      zoom = 11.0; // Medium area
    } else if (maxSpan > 0.01) {
      zoom = 12.0; // Small area
    } else if (maxSpan > 0.005) {
      zoom = 13.0; // Very small area
    }

    return CameraPosition(target: center, zoom: zoom);
  }

  // Simulate delivery agent movement (for demo purposes)
  Stream<LatLng> simulateDeliveryAgentMovement({
    required LatLng startLocation,
    required LatLng endLocation,
    Duration interval = const Duration(seconds: 10),
  }) async* {
    const int steps = 20;
    double latStep = (endLocation.latitude - startLocation.latitude) / steps;
    double lngStep = (endLocation.longitude - startLocation.longitude) / steps;

    for (int i = 0; i <= steps; i++) {
      yield LatLng(
        startLocation.latitude + (latStep * i),
        startLocation.longitude + (lngStep * i),
      );

      if (i < steps) {
        await Future.delayed(interval);
      }
    }
  }
}
