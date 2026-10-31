import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/utils/geo_utils.dart';

void main() {
  group('GeoUtils - Geospatial Math & Formatting', () {
    test('distanceInMeters should accurately compute distance between two coordinates', () {
      // Coords: Gateway (19.9975, 73.7898) and Remote Node (20.0021, 73.7954)
      final distance = GeoUtils.distanceInMeters(19.9975, 73.7898, 20.0021, 73.7954);

      // Expected distance is approximately 770 meters
      expect(distance, greaterThan(700));
      expect(distance, lessThan(850));
    });

    test('formatDistance should format meters and kilometers properly', () {
      expect(GeoUtils.formatDistance(450), equals('450 m'));
      expect(GeoUtils.formatDistance(2450), equals('2.45 km'));
    });

    test('isValidCoordinate should validate valid and invalid latitude/longitude', () {
      expect(GeoUtils.isValidCoordinate(19.9975, 73.7898), isTrue);
      expect(GeoUtils.isValidCoordinate(0.0, 0.0), isTrue);
      expect(GeoUtils.isValidCoordinate(-89.9, 179.9), isTrue);

      // Invalid
      expect(GeoUtils.isValidCoordinate(95.0, 73.0), isFalse); // Lat > 90
      expect(GeoUtils.isValidCoordinate(19.0, 185.0), isFalse); // Lon > 180
      expect(GeoUtils.isValidCoordinate(null, 73.0), isFalse);
    });

    test('formatCoordinates should produce standard tactical coordinate strings', () {
      final formatted = GeoUtils.formatCoordinates(19.9975, 73.7898);
      expect(formatted, equals('19.99750°N, 73.78980°E'));

      final formattedSouthWest = GeoUtils.formatCoordinates(-33.8688, -151.2093);
      expect(formattedSouthWest, equals('33.86880°S, 151.20930°W'));
    });
  });
}

