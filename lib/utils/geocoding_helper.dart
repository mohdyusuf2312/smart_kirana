import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class GeocodingHelper {
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';

  /// Get address from coordinates with multiple fallback strategies
  static Future<String> getAddressFromCoordinates(LatLng location) async {
    // Strategy 1: Try native geocoding package
    String address = await _tryNativeGeocoding(location);
    if (address.isNotEmpty && !address.startsWith('Lat:')) {
      return address;
    }

    // Strategy 2: Try OpenStreetMap Nominatim API
    address = await _tryNominatimGeocoding(location);
    if (address.isNotEmpty && !address.startsWith('Lat:')) {
      return address;
    }

    // Strategy 3: Return coordinates as fallback
    return 'Lat: ${location.latitude.toStringAsFixed(6)}, Lng: ${location.longitude.toStringAsFixed(6)}';
  }

  /// Try native geocoding package
  static Future<String> _tryNativeGeocoding(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      ).timeout(const Duration(seconds: 10));

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        List<String> addressParts = [];

        // Build address from available parts
        if (place.name != null && place.name!.isNotEmpty) {
          addressParts.add(place.name!);
        }

        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }

        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }

        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }

        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }

        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressParts.add(place.postalCode!);
        }

        String result = addressParts.join(', ');
        if (result.isNotEmpty) {
          return result;
        }
      }
    } catch (e) {
      // Silent failure
    }

    return '';
  }

  /// Try OpenStreetMap Nominatim API as fallback
  static Future<String> _tryNominatimGeocoding(LatLng location) async {
    try {
      final url =
          '$_nominatimBaseUrl/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&zoom=18&addressdetails=1';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'SmartKirana/1.0',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('display_name')) {
          String address = data['display_name'] as String;

          // Clean up the address
          address = address.replaceAll(', India', '');

          return address;
        }

        // Try to build address from components
        if (data.containsKey('address')) {
          Map<String, dynamic> addressComponents = data['address'];
          List<String> parts = [];

          // Add relevant address components
          for (String key in [
            'house_number',
            'road',
            'neighbourhood',
            'suburb',
            'city',
            'state',
            'postcode',
          ]) {
            if (addressComponents.containsKey(key)) {
              parts.add(addressComponents[key].toString());
            }
          }

          if (parts.isNotEmpty) {
            String result = parts.join(', ');

            return result;
          }
        }
      }
    } catch (e) {
      // Silent failure
    }

    return '';
  }

  /// Test if geocoding services are working
  static Future<bool> testGeocodingServices() async {
    // Test with a known location (India Gate, Delhi)
    const testLocation = LatLng(28.6129, 77.2295);

    // Test native geocoding
    String nativeResult = await _tryNativeGeocoding(testLocation);
    bool nativeWorking =
        nativeResult.isNotEmpty && !nativeResult.startsWith('Lat:');

    // Test Nominatim
    String nominatimResult = await _tryNominatimGeocoding(testLocation);
    bool nominatimWorking =
        nominatimResult.isNotEmpty && !nominatimResult.startsWith('Lat:');

    return nativeWorking || nominatimWorking;
  }
}
