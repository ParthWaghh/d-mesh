import 'dart:math' as math;

class GeoUtils {
  static const double earthRadiusKm = 6371.0;

  /// Haversine formula to calculate great-circle distance between two GPS coordinates in meters
  static double distanceInMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c * 1000.0;
  }

  /// Calculates initial compass bearing from Point A to Point B in degrees (0..360)
  static double bearingInDegrees(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final double phi1 = _degToRad(lat1);
    final double phi2 = _degToRad(lat2);
    final double deltaLambda = _degToRad(lon2 - lon1);

    final double y = math.sin(deltaLambda) * math.cos(phi2);
    final double x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);

    final double theta = math.atan2(y, x);
    return (_radToDeg(theta) + 360) % 360;
  }

  /// Formats distance into human readable string (e.g. "450 m" or "2.4 km")
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000.0).toStringAsFixed(2)} km';
    }
  }

  /// Validates latitude and longitude ranges
  static bool isValidCoordinate(double? lat, double? lon) {
    if (lat == null || lon == null) return false;
    return lat >= -90.0 && lat <= 90.0 && lon >= -180.0 && lon <= 180.0;
  }

  /// Format coordinates into standard military/tactical string
  static String formatCoordinates(double lat, double lon) {
    final String latStr = lat >= 0
        ? '${lat.toStringAsFixed(5)}°N'
        : '${(-lat).toStringAsFixed(5)}°S';
    final String lonStr = lon >= 0
        ? '${lon.toStringAsFixed(5)}°E'
        : '${(-lon).toStringAsFixed(5)}°W';
    return '$latStr, $lonStr';
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);
  static double _radToDeg(double rad) => rad * (180.0 / math.pi);
}

