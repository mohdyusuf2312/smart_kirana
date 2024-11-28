import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RouteService {
  // Singleton pattern
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal();

  // Properties
  String? _apiKey;
  bool _isInitialized = false;
  String? _error;

  // Getters
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  // Initialize the route service
  Future<bool> initialize() async {
    try {
      // Ensure dotenv is loaded
      if (!dotenv.isInitialized) {
        await dotenv.load(fileName: ".env");
      }

      _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

      if (_apiKey == null || _apiKey!.isEmpty) {
        _error = 'Google Maps API key not found in .env file';
        return false;
      }

      // Validate API key format
      if (!_apiKey!.startsWith('AIza')) {
        _error = 'Invalid Google Maps API key format';
        return false;
      }

      _isInitialized = true;
      _error = null;

      return true;
    } catch (e) {
      _error = 'Failed to initialize Route Service: $e';
      return false;
    }
  }

  // Calculate route between two points using Google Directions API
  Future<RouteInfo?> calculateRoute({
    required LatLng origin,
    required LatLng destination,
    String travelMode = 'driving',
  }) async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          throw Exception(_error ?? 'Failed to initialize RouteService');
        }
      }

      final String url =
          'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=$travelMode'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          // Decode polyline points
          final polylinePoints = _decodePolyline(
            route['overview_polyline']['points'],
          );

          return RouteInfo(
            distance: leg['distance']['text'],
            duration: leg['duration']['text'],
            distanceValue: leg['distance']['value'],
            durationValue: leg['duration']['value'],
            polylinePoints: polylinePoints,
            startAddress: leg['start_address'],
            endAddress: leg['end_address'],
          );
        } else {
          throw Exception('No route found: ${data['status']}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _error = 'Failed to calculate route: $e';
      return null;
    }
  }

  // Decode polyline string to list of LatLng points
  List<LatLng> _decodePolyline(String polyline) {
    List<LatLng> points = [];
    int index = 0;
    int len = polyline.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  // Get estimated delivery time based on route duration
  String getEstimatedDeliveryTime(int durationInSeconds) {
    // Add preparation time (15 minutes) to the travel time
    final totalSeconds = durationInSeconds + (15 * 60);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

// Model class for route information
class RouteInfo {
  final String distance;
  final String duration;
  final int distanceValue; // in meters
  final int durationValue; // in seconds
  final List<LatLng> polylinePoints;
  final String startAddress;
  final String endAddress;

  RouteInfo({
    required this.distance,
    required this.duration,
    required this.distanceValue,
    required this.durationValue,
    required this.polylinePoints,
    required this.startAddress,
    required this.endAddress,
  });

  Map<String, dynamic> toMap() {
    return {
      'distance': distance,
      'duration': duration,
      'distanceValue': distanceValue,
      'durationValue': durationValue,
      'polylinePoints':
          polylinePoints
              .map(
                (point) => {
                  'latitude': point.latitude,
                  'longitude': point.longitude,
                },
              )
              .toList(),
      'startAddress': startAddress,
      'endAddress': endAddress,
    };
  }

  factory RouteInfo.fromMap(Map<String, dynamic> map) {
    return RouteInfo(
      distance: map['distance'] ?? '',
      duration: map['duration'] ?? '',
      distanceValue: map['distanceValue'] ?? 0,
      durationValue: map['durationValue'] ?? 0,
      polylinePoints:
          (map['polylinePoints'] as List<dynamic>?)
              ?.map(
                (point) =>
                    LatLng(point['latitude'] ?? 0.0, point['longitude'] ?? 0.0),
              )
              .toList() ??
          [],
      startAddress: map['startAddress'] ?? '',
      endAddress: map['endAddress'] ?? '',
    );
  }
}
