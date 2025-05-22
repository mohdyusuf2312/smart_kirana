import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:smart_kirana/services/maps_service.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/utils/geocoding_helper.dart';
import 'package:smart_kirana/widgets/custom_button.dart';

class LocationPickerScreen extends StatefulWidget {
  static const String routeName = '/location-picker';
  final LatLng? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  final MapsService _mapsService = MapsService();

  LatLng? _selectedLocation;
  String _selectedAddress = 'Tap on map to select location';
  bool _isLoading = true;
  bool _isGettingAddress = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _initializeMap();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      // Initialize maps service
      final initialized = await _mapsService.initialize();
      if (!initialized) {
        setState(() {
          _error = _mapsService.error ?? 'Failed to initialize maps';
          _isLoading = false;
        });
        return;
      }

      // If no initial location, try to get current location
      if (_selectedLocation == null) {
        await _getCurrentLocation();
      } else {
        await _getAddressFromLocation(_selectedLocation!);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error initializing map: $e';
        _isLoading = false;
      });
    }
  }

  // Test geocoding service with comprehensive diagnostics
  Future<bool> _testGeocodingService() async {
    if (kDebugMode) {
      debugPrint('=== GEOCODING DIAGNOSTIC TEST ===');
    }

    try {
      // Test 1: Basic geocoding test with India Gate, Delhi
      if (kDebugMode) {
        debugPrint('Test 1: Testing with India Gate, Delhi (28.6129, 77.2295)');
      }

      List<Placemark> testPlacemarks = await placemarkFromCoordinates(
        28.6129,
        77.2295,
      ).timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        debugPrint('Test 1 Result: ${testPlacemarks.length} placemarks found');
        if (testPlacemarks.isNotEmpty) {
          Placemark place = testPlacemarks.first;
          debugPrint('  - Name: ${place.name}');
          debugPrint('  - Street: ${place.street}');
          debugPrint('  - Locality: ${place.locality}');
          debugPrint('  - Administrative Area: ${place.administrativeArea}');
          debugPrint('  - Country: ${place.country}');
          debugPrint('  - Postal Code: ${place.postalCode}');
        }
      }

      if (testPlacemarks.isNotEmpty) {
        // Test 2: Try another well-known location (Mumbai)
        if (kDebugMode) {
          debugPrint('Test 2: Testing with Mumbai (19.0760, 72.8777)');
        }

        List<Placemark> mumbaiPlacemarks = await placemarkFromCoordinates(
          19.0760,
          72.8777,
        ).timeout(const Duration(seconds: 10));

        if (kDebugMode) {
          debugPrint(
            'Test 2 Result: ${mumbaiPlacemarks.length} placemarks found',
          );
          if (mumbaiPlacemarks.isNotEmpty) {
            debugPrint('  - Locality: ${mumbaiPlacemarks.first.locality}');
          }
        }

        return mumbaiPlacemarks.isNotEmpty;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Geocoding test failed with error: $e');
        debugPrint('Error type: ${e.runtimeType}');
        if (e is Exception) {
          debugPrint('Exception details: ${e.toString()}');
        }
      }
      return false;
    }
  }

  // Test internet connectivity
  Future<bool> _testInternetConnectivity() async {
    try {
      if (kDebugMode) {
        debugPrint('Testing internet connectivity...');
      }

      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));

      bool isConnected = response.statusCode == 200;
      if (kDebugMode) {
        debugPrint(
          'Internet connectivity: ${isConnected ? 'CONNECTED' : 'DISCONNECTED'}',
        );
      }

      return isConnected;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Internet connectivity test failed: $e');
      }
      return false;
    }
  }

  // Run comprehensive diagnostics
  Future<void> _runComprehensiveDiagnostics() async {
    if (kDebugMode) {
      debugPrint('\n🔍 === COMPREHENSIVE GEOCODING DIAGNOSTICS ===');
    }

    // Test 1: Internet connectivity
    bool internetConnected = await _testInternetConnectivity();

    // Test 2: Geocoding service
    bool geocodingWorking = await GeocodingHelper.testGeocodingServices();

    // Test 3: Platform-specific checks
    await _testPlatformSpecificIssues();

    // Show results to user
    if (mounted) {
      String message = '''
Diagnostics Results:
• Internet: ${internetConnected ? '✅ Connected' : '❌ Disconnected'}
• Geocoding: ${geocodingWorking ? '✅ Working' : '❌ Failed'}

${!geocodingWorking ? 'Check debug console for detailed error logs.' : ''}
      ''';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: geocodingWorking ? Colors.green : Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Test platform-specific issues
  Future<void> _testPlatformSpecificIssues() async {
    if (kDebugMode) {
      debugPrint('\n🔧 Testing platform-specific issues...');

      // Check if we're on Android/iOS
      debugPrint('Platform: ${Theme.of(context).platform}');

      // Test location permissions
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        debugPrint('Location permission: $permission');

        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        debugPrint('Location service enabled: $serviceEnabled');
      } catch (e) {
        debugPrint('Location permission check failed: $e');
      }
    }
  }

  // Alternative geocoding method with multiple attempts and fallback
  Future<String> _getAddressWithRetry(
    LatLng location, {
    int maxAttempts = 3,
  }) async {
    // First try the standard geocoding approach
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        if (kDebugMode) {
          debugPrint(
            'Geocoding attempt $attempt for ${location.latitude}, ${location.longitude}',
          );
        }

        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        ).timeout(Duration(seconds: 5 + (attempt * 2))); // Increasing timeout

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;

          // Try different formatting strategies
          List<String> addressParts = [];

          // Strategy 1: Use thoroughfare and subThoroughfare
          if (place.subThoroughfare != null &&
              place.subThoroughfare!.isNotEmpty) {
            if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
              addressParts.add(
                '${place.subThoroughfare}, ${place.thoroughfare}',
              );
            } else {
              addressParts.add(place.subThoroughfare!);
            }
          } else if (place.thoroughfare != null &&
              place.thoroughfare!.isNotEmpty) {
            addressParts.add(place.thoroughfare!);
          }

          // Strategy 2: Use name if no thoroughfare
          if (addressParts.isEmpty &&
              place.name != null &&
              place.name!.isNotEmpty) {
            addressParts.add(place.name!);
          }

          // Add locality information
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            addressParts.add(place.subLocality!);
          }

          if (place.locality != null && place.locality!.isNotEmpty) {
            addressParts.add(place.locality!);
          } else if (place.subAdministrativeArea != null &&
              place.subAdministrativeArea!.isNotEmpty) {
            addressParts.add(place.subAdministrativeArea!);
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
            if (kDebugMode) {
              debugPrint('Geocoding successful on attempt $attempt: $result');
            }
            return result;
          }
        }

        if (kDebugMode) {
          debugPrint('Attempt $attempt: No meaningful address found');
        }

        // Wait before retry
        if (attempt < maxAttempts) {
          await Future.delayed(Duration(seconds: attempt));
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Attempt $attempt failed: $e');
        }

        // Wait before retry
        if (attempt < maxAttempts) {
          await Future.delayed(Duration(seconds: attempt));
        }
      }
    }

    // If standard geocoding failed, try alternative approach
    String fallbackAddress = await _getFallbackAddress(location);
    if (fallbackAddress.isNotEmpty && !fallbackAddress.startsWith('Lat:')) {
      return fallbackAddress;
    }

    // All attempts failed, return coordinates
    return 'Lat: ${location.latitude.toStringAsFixed(6)}, Lng: ${location.longitude.toStringAsFixed(6)}';
  }

  // Fallback geocoding using HTTP API (when geocoding package fails)
  Future<String> _getFallbackAddress(LatLng location) async {
    try {
      if (kDebugMode) {
        debugPrint('Trying fallback geocoding via HTTP API...');
      }

      // Use OpenStreetMap Nominatim API as fallback (free, no API key required)
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&zoom=18&addressdetails=1';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'SmartKirana/1.0', // Required by Nominatim
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = response.body;
        if (kDebugMode) {
          debugPrint('Fallback geocoding response: $data');
        }

        // Simple parsing of the response
        if (data.contains('"display_name"')) {
          final startIndex = data.indexOf('"display_name":"') + 16;
          final endIndex = data.indexOf('"', startIndex);
          if (startIndex > 15 && endIndex > startIndex) {
            String address = data.substring(startIndex, endIndex);
            // Clean up the address
            address = address.replaceAll('\\/', '/');
            if (kDebugMode) {
              debugPrint('Fallback geocoding successful: $address');
            }
            return address;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Fallback geocoding failed: $e');
      }
    }

    return '';
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Use default location (Delhi, India)
        _selectedLocation = const LatLng(28.6139, 77.2090);
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Use default location
          _selectedLocation = const LatLng(28.6139, 77.2090);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Use default location
        _selectedLocation = const LatLng(28.6139, 77.2090);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      _selectedLocation = LatLng(position.latitude, position.longitude);
      await _getAddressFromLocation(_selectedLocation!);
    } catch (e) {
      // Use default location on error
      _selectedLocation = const LatLng(28.6139, 77.2090);
    }
  }

  Future<void> _getAddressFromLocation(LatLng location) async {
    setState(() {
      _isGettingAddress = true;
    });

    try {
      // Use the new geocoding helper with multiple fallback strategies
      String address = await GeocodingHelper.getAddressFromCoordinates(
        location,
      );

      if (mounted) {
        setState(() {
          _selectedAddress = address;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Geocoding error: $e');
      }
      if (mounted) {
        setState(() {
          _selectedAddress =
              'Lat: ${location.latitude.toStringAsFixed(6)}, Lng: ${location.longitude.toStringAsFixed(6)}';
        });

        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get address: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingAddress = false;
        });
      }
    }
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _getAddressFromLocation(location);
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.pop(context, {
        'location': _selectedLocation,
        'address': _selectedAddress,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedLocation != null)
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: () async {
                await _getCurrentLocation();
                if (_selectedLocation != null && _mapController != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLng(_selectedLocation!),
                  );
                }
              },
            ),
          // Debug button to test geocoding
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () async {
                await _runComprehensiveDiagnostics();
              },
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Map
                  Expanded(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target:
                            _selectedLocation ?? const LatLng(28.6139, 77.2090),
                        zoom: 15.0,
                      ),
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                      onTap: _onMapTap,
                      markers:
                          _selectedLocation != null
                              ? {
                                Marker(
                                  markerId: const MarkerId('selected_location'),
                                  position: _selectedLocation!,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueRed,
                                  ),
                                ),
                              }
                              : {},
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: true,
                      mapToolbarEnabled: false,
                      compassEnabled: true,
                      trafficEnabled: false,
                      buildingsEnabled: true,
                      indoorViewEnabled: false,
                      mapType: MapType.normal,
                    ),
                  ),

                  // Address display and confirm button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Selected Location',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (_isGettingAddress) ...[
                              const SizedBox(width: 8),
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedAddress,
                          style: const TextStyle(fontSize: 14),
                        ),

                        // Show retry option if geocoding fails
                        if (_selectedAddress.startsWith('Lat:') &&
                            _selectedLocation != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.warning,
                                      color: Colors.orange,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Address not found',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Geocoding service couldn\'t find an address for this location. You can still use the coordinates.',
                                  style: TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            _isGettingAddress
                                                ? null
                                                : () => _getAddressFromLocation(
                                                  _selectedLocation!,
                                                ),
                                        icon: const Icon(
                                          Icons.refresh,
                                          size: 16,
                                        ),
                                        label: const Text('Retry'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'Confirm Location',
                          onPressed:
                              _selectedLocation != null
                                  ? _confirmLocation
                                  : null,
                          enabled:
                              _selectedLocation != null && !_isGettingAddress,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
