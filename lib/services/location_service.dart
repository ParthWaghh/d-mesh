import 'dart:async';
import '../core/constants/app_constants.dart';
import '../core/utils/geo_utils.dart';

class LocationPoint {
  final double latitude;
  final double longitude;
  final double? altitude;
  final DateTime timestamp;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    this.altitude,
    required this.timestamp,
  });
}

class LocationService {
  LocationPoint _currentPosition = const LocationPoint(
    latitude: AppConstants.defaultLatitude,
    longitude: AppConstants.defaultLongitude,
    altitude: 580.0,
    timestamp: null ?? null as dynamic,
  );

  LocationPoint get currentPosition => LocationPoint(
    latitude: _currentPosition.latitude,
    longitude: _currentPosition.longitude,
    altitude: _currentPosition.altitude,
    timestamp: DateTime.now(),
  );

  /// Computes distance from current position to a target in meters
  double distanceTo(double targetLat, double targetLon) {
    return GeoUtils.distanceInMeters(
      _currentPosition.latitude,
      _currentPosition.longitude,
      targetLat,
      targetLon,
    );
  }

  /// Computes compass bearing to target coordinate
  double bearingTo(double targetLat, double targetLon) {
    return GeoUtils.bearingInDegrees(
      _currentPosition.latitude,
      _currentPosition.longitude,
      targetLat,
      targetLon,
    );
  }

  void updateLocation(double lat, double lon, [double? alt]) {
    _currentPosition = LocationPoint(
      latitude: lat,
      longitude: lon,
      altitude: alt ?? _currentPosition.altitude,
      timestamp: DateTime.now(),
    );
  }
}

