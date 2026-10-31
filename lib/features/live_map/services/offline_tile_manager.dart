import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class TileCoord {
  final int x;
  final int y;
  final int z;

  const TileCoord(this.x, this.y, this.z);

  @override
  String toString() => '$z/$x/$y';
}

class OfflineTileManager {
  static const String userAgent = 'DMESH-Disaster-Rescue-Network/1.0';

  /// Converts latitude, longitude, and zoom level into OSM tile coordinates (Slippy Map tile names)
  static TileCoord latLonToTile(double lat, double lon, int zoom) {
    final int x = ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
    final double latRad = lat * math.pi / 180.0;
    final int y = ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * (1 << zoom)).floor();
    return TileCoord(x, y, zoom);
  }

  /// Returns path to local offline tile storage directory
  static Future<Directory> getOfflineTilesDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final tilesDir = Directory('${appDir.path}/offline_map_tiles');
    if (!await tilesDir.exists()) {
      await tilesDir.create(recursive: true);
    }
    return tilesDir;
  }

  /// Retrieves local cached tile if it exists
  static Future<File?> getCachedTile(int z, int x, int y) async {
    final tilesDir = await getOfflineTilesDir();
    final tileFile = File('${tilesDir.path}/$z/$x/$y.png');
    if (await tileFile.exists()) {
      return tileFile;
    }
    return null;
  }

  /// Downloads and caches a specific OpenStreetMap tile
  static Future<bool> downloadAndCacheTile(int z, int x, int y) async {
    try {
      final tilesDir = await getOfflineTilesDir();
      final tileFile = File('${tilesDir.path}/$z/$x/$y.png');

      if (await tileFile.exists()) return true;

      final url = Uri.parse('https://tile.openstreetmap.org/$z/$x/$y.png');
      final response = await http.get(url, headers: {'User-Agent': userAgent}).timeout(
        const Duration(seconds: 4),
      );

      if (response.statusCode == 200) {
        await tileFile.parent.create(recursive: true);
        await tileFile.writeAsBytes(response.bodyBytes);
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Pre-caches an entire bounding box for a disaster staging area across multiple zoom levels
  static Future<int> cacheDisasterRegion({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    int minZoom = 12,
    int maxZoom = 15,
    void Function(int downloaded, int total)? onProgress,
  }) async {
    int totalTiles = 0;
    final List<TileCoord> coordsToDownload = [];

    for (int z = minZoom; z <= maxZoom; z++) {
      final topLeft = latLonToTile(maxLat, minLon, z);
      final bottomRight = latLonToTile(minLat, maxLon, z);

      for (int x = topLeft.x; x <= bottomRight.x; x++) {
        for (int y = topLeft.y; y <= bottomRight.y; y++) {
          coordsToDownload.add(TileCoord(x, y, z));
        }
      }
    }

    totalTiles = coordsToDownload.length;
    int downloadedCount = 0;

    for (final coord in coordsToDownload) {
      final success = await downloadAndCacheTile(coord.z, coord.x, coord.y);
      if (success) downloadedCount++;
      onProgress?.call(downloadedCount, totalTiles);
      // Polite rate limit for OSM servers
      await Future.delayed(const Duration(milliseconds: 60));
    }

    return downloadedCount;
  }
}

