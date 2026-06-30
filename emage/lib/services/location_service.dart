import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationData {
  final String area;
  final double latitude;
  final double longitude;

  LocationData({
    required this.area,
    required this.latitude,
    required this.longitude,
  });
}

class LocationService {
  static Position? _cachedPosition;
  static String? _cachedArea;

  static Future<LocationData> getCurrentLocation() async {
    if (_cachedArea != null && _cachedPosition != null) {
      return LocationData(
        area: _cachedArea!,
        latitude: _cachedPosition!.latitude,
        longitude: _cachedPosition!.longitude,
      );
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    String area = "";
    if (placemarks.isNotEmpty) {
      final placemark = placemarks.first;
      List<String> parts = [];

      if (placemark.locality != null && placemark.locality!.isNotEmpty) {
        parts.add(placemark.locality!);
      }
      if (placemark.subAdministrativeArea != null &&
          placemark.subAdministrativeArea!.isNotEmpty) {
        parts.add(placemark.subAdministrativeArea!);
      }
      if (placemark.administrativeArea != null &&
          placemark.administrativeArea!.isNotEmpty) {
        parts.add(placemark.administrativeArea!);
      }

      area = parts.join(", ");
    }

    _cachedPosition = position;
    _cachedArea = area.isNotEmpty ? area : "Unknown area";

    return LocationData(
      area: _cachedArea!,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  static Future<void> refreshLocation() async {
    _cachedArea = null;
    _cachedPosition = null;
    await getCurrentLocation();
  }

  static Position? get position => _cachedPosition;
}
