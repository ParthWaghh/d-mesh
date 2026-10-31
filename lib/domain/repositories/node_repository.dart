import '../entities/node.dart';

abstract class NodeRepository {
  Future<List<MeshNode>> getNodes();
  Future<MeshNode?> getNodeById(String id);
  Future<void> saveNode(MeshNode node);
  Future<void> deleteNode(String id);
  Future<void> updateNodeLocation(String id, double latitude, double longitude);
  Future<void> updateNodeTelemetry({
    required String id,
    required int battery,
    required int rssi,
    required double snr,
    required int hopCount,
    required bool isOnline,
  });
}

