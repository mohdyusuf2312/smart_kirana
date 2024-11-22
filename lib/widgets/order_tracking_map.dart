import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_kirana/models/order_model.dart';
import 'package:smart_kirana/services/maps_service.dart';
import 'package:smart_kirana/utils/constants.dart';

class OrderTrackingMap extends StatefulWidget {
  final OrderModel order;
  final double height;

  const OrderTrackingMap({super.key, required this.order, this.height = 250});

  @override
  State<OrderTrackingMap> createState() => _OrderTrackingMapState();
}

class _OrderTrackingMapState extends State<OrderTrackingMap> {
  GoogleMapController? _mapController;
  final MapsService _mapsService = MapsService();

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  String? _error;
  StreamSubscription<LatLng>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      // Initialize maps service
      final initialized = await _mapsService.initialize();
      if (!initialized) {
        final errorMsg = _mapsService.error ?? 'Failed to initialize maps';
        if (mounted) {
          setState(() {
            _error = errorMsg;
            _isLoading = false;
          });
        }
        return;
      }

      // Check if order has delivery coordinates
      if (widget.order.deliveryLatitude == null ||
          widget.order.deliveryLongitude == null) {
        if (mounted) {
          setState(() {
            _error = 'Delivery location not available';
            _isLoading = false;
          });
        }
        return;
      }

      await _setupBasicMapData();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error setting up map: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _setupBasicMapData() async {
    final deliveryLocation = LatLng(
      widget.order.deliveryLatitude!,
      widget.order.deliveryLongitude!,
    );

    LatLng? currentLocation;
    if (widget.order.currentLatitude != null &&
        widget.order.currentLongitude != null) {
      currentLocation = LatLng(
        widget.order.currentLatitude!,
        widget.order.currentLongitude!,
      );
    }

    // Create markers using maps service
    _markers = _mapsService.createOrderTrackingMarkers(
      deliveryLocation: deliveryLocation,
      currentLocation: currentLocation,
      deliveryAgentName: widget.order.deliveryAgentName,
    );

    // Extract and create route polylines if available
    _polylines = _extractRoutePolylines();

    // Set loading to false after successful setup
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Set<Polyline> _extractRoutePolylines() {
    try {
      // Check if order has route information stored
      // This would be stored when the order was created with route calculation
      // For now, we'll return empty set as the route data structure needs to be defined
      // In a real implementation, you would extract the route points from the order data

      // Extract route points from order.routeInfo if available
      // For now, return empty set
      return {};
    } catch (e) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          child: _buildMapContent(),
        ),
      ),
    );
  }

  Widget _buildMapContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppPadding.small),
            Text('Loading map...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppPadding.small),
            Text(
              'Map Error',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppPadding.small / 2),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.medium,
              ),
              child: Text(
                _error!,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppPadding.medium),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _initializeMap();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (widget.order.deliveryLatitude == null ||
        widget.order.deliveryLongitude == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppPadding.small),
            Text(
              'Location Not Available',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppPadding.small / 2),
            Text(
              'Delivery location will be updated soon',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final deliveryLocation = LatLng(
      widget.order.deliveryLatitude!,
      widget.order.deliveryLongitude!,
    );

    LatLng? currentLocation;
    if (widget.order.currentLatitude != null &&
        widget.order.currentLongitude != null) {
      currentLocation = LatLng(
        widget.order.currentLatitude!,
        widget.order.currentLongitude!,
      );
    }

    final initialCameraPosition = _mapsService.getCameraPositionForBounds(
      deliveryLocation: deliveryLocation,
      currentLocation: currentLocation,
    );

    return GoogleMap(
      initialCameraPosition: initialCameraPosition,
      markers: _markers,
      polylines: _polylines,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
      compassEnabled: true,
      trafficEnabled: false,
      buildingsEnabled: true,
      indoorViewEnabled: false,
      mapType: MapType.normal,
      // Add error handling for map creation
      onCameraMove: (CameraPosition position) {
        // Handle camera movement if needed
      },
    );
  }
}
