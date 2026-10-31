import '../../domain/entities/node.dart';
import '../../domain/repositories/node_repository.dart';
import '../datasources/local/dmesh_database.dart';
import '../models/node_model.dart';

class NodeRepositoryImpl implements NodeRepository {
  final DMeshDatabase _database;

  NodeRepositoryImpl({DMeshDatabase? database})
      : _database = database ?? DMeshDatabase.instance;

  @override
  Future<List<MeshNode>> getNodes() async {
    final rows = await _database.getAllNodes();
    return rows.map((r) => NodeModel.fromMap(r)).toList();
  }

  @override
  Future<MeshNode?> getNodeById(String id) async {
    final row = await _database.getNodeById(id);
    if (row == null) return null;
    return NodeModel.fromMap(row);
  }

  @override
  Future<void> saveNode(MeshNode node) async {
    final model = NodeModel.fromEntity(node);
    await _database.insertOrUpdateNode(model.toMap());
  }

  @override
  Future<void> deleteNode(String id) async {
    await _database.deleteNode(id);
  }

  @override
  Future<void> updateNodeLocation(String id, double latitude, double longitude) async {
    final existing = await getNodeById(id);
    if (existing != null) {
      final updated = existing.copyWith(
        latitude: latitude,
        longitude: longitude,
        lastSeen: DateTime.now(),
        isOnline: true,
      );
      await saveNode(updated);
    }
  }

  @override
  Future<void> updateNodeTelemetry({
    required String id,
    required int battery,
    required int rssi,
    required double snr,
    required int hopCount,
    required bool isOnline,
  }) async {
    final existing = await getNodeById(id);
    if (existing != null) {
      final updated = existing.copyWith(
        batteryPercentage: battery,
        rssi: rssi,
        snr: snr,
        hopCount: hopCount,
        isOnline: isOnline,
        lastSeen: DateTime.now(),
      );
      await saveNode(updated);
    }
  }
}

