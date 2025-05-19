# Geocoding Troubleshooting Guide

## Common Issues and Solutions

### 1. **Geocoding Test Failed**

If you're seeing "geocoding test failed", here are the most common causes and solutions:

#### **Issue A: Internet Connectivity**
- **Symptom**: No internet connection or restricted network
- **Solution**: 
  - Check if device has internet access
  - Try on different network (WiFi vs Mobile data)
  - Check if corporate firewall is blocking geocoding services

#### **Issue B: Platform Permissions**
- **Symptom**: Location permissions not granted
- **Solution**:
  ```bash
  # For Android - check permissions in device settings
  # For iOS - check location permissions in device settings
  ```

#### **Issue C: Geocoding Service Limitations**
- **Symptom**: Native geocoding package fails
- **Solution**: The app now includes fallback to OpenStreetMap Nominatim API

#### **Issue D: Android Emulator Issues**
- **Symptom**: Geocoding fails only on Android emulator
- **Solution**:
  - Test on real device
  - Enable location services in emulator
  - Set custom location in emulator

### 2. **Testing Steps**

1. **Run Comprehensive Diagnostics**:
   - Open location picker screen
   - Tap the debug button (bug icon) in debug mode
   - Check console output for detailed error messages

2. **Manual Testing**:
   ```dart
   // Test in your app
   import 'package:smart_kirana/utils/geocoding_helper.dart';
   
   // Test geocoding
   bool result = await GeocodingHelper.testGeocodingServices();
   print('Geocoding test result: $result');
   ```

3. **Check Debug Console**:
   Look for these messages:
   - `=== GEOCODING DIAGNOSTIC TEST ===`
   - `Trying native geocoding for...`
   - `Trying Nominatim geocoding for...`

### 3. **Expected Behavior**

✅ **Working Correctly**:
- Native geocoding works: Shows proper address
- Fallback works: If native fails, Nominatim provides address
- Coordinates fallback: If all fails, shows coordinates

❌ **Not Working**:
- Shows "Address not available" 
- No debug output in console
- App crashes when tapping on map

### 4. **Fallback Strategy**

The app now uses a 3-tier fallback system:

1. **Primary**: Native `geocoding` package
2. **Secondary**: OpenStreetMap Nominatim API (no API key required)
3. **Tertiary**: Display coordinates as address

### 5. **Debug Information**

When testing, check console for:
```
🔍 === COMPREHENSIVE GEOCODING DIAGNOSTICS ===
Testing internet connectivity...
Internet connectivity: CONNECTED
=== GEOCODING DIAGNOSTIC TEST ===
Testing geocoding services with India Gate coordinates...
Trying native geocoding for 28.6129, 77.2295
Native geocoding - Placemark found:
  Name: India Gate
  Locality: New Delhi
  Administrative Area: Delhi
  Country: India
Geocoding test results:
  Native: WORKING - India Gate, New Delhi, Delhi
  Nominatim: WORKING - India Gate, Rajpath, New Delhi, Delhi, India
```

### 6. **Common Fixes**

#### **For Android**:
1. Check `android/app/src/main/AndroidManifest.xml` has:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
   ```

2. Ensure Google Play Services are installed on device

#### **For iOS**:
1. Check `ios/Runner/Info.plist` has:
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>This app needs access to location to provide delivery services.</string>
   ```

#### **For Both Platforms**:
1. Run `flutter clean && flutter pub get`
2. Restart the app completely
3. Test on real device instead of emulator

### 7. **If Still Not Working**

1. **Check Dependencies**:
   ```yaml
   dependencies:
     geocoding: ^3.0.0
     geolocator: ^12.0.0
     http: ^1.4.0
   ```

2. **Test Simple Geocoding**:
   ```dart
   import 'package:geocoding/geocoding.dart';
   
   try {
     List<Placemark> placemarks = await placemarkFromCoordinates(28.6129, 77.2295);
     print('Placemarks: ${placemarks.length}');
     if (placemarks.isNotEmpty) {
       print('First placemark: ${placemarks.first.locality}');
     }
   } catch (e) {
     print('Error: $e');
   }
   ```

3. **Contact Support**:
   - Provide debug console output
   - Specify device type (Android/iOS, emulator/real device)
   - Include error messages

### 8. **Success Indicators**

✅ You should see:
- Addresses appear when tapping on map
- Debug test shows "WORKING" for at least one service
- No error messages in console
- Retry button works when geocoding fails

The new implementation should be much more reliable with the fallback system!
