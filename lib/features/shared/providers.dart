import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/datasources/local/dmesh_database.dart';
import '../../data/repositories/message_repository_impl.dart';
import '../../data/repositories/node_repository_impl.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/emergency_event.dart';
import '../../domain/entities/geo_note.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/mesh_route.dart';
import '../../domain/entities/node.dart';
import '../../domain/repositories/message_repository.dart';
import '../../domain/repositories/node_repository.dart';
import '../../domain/repositories/note_repository.dart';

// --- DATABASE & REPOSITORY PROVIDERS ---

final databaseProvider = Provider<DMeshDatabase>((ref) {
  return DMeshDatabase.instance;
});

final nodeRepositoryProvider = Provider<NodeRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return NodeRepositoryImpl(database: db);
});

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return MessageRepositoryImpl(database: db);
});

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return NoteRepositoryImpl(database: db);
});

// --- CONNECTION STATE ---

enum GatewayConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class GatewayState {
  final GatewayConnectionStatus status;
  final String ip;
  final int port;
  final String? deviceName;
  final String? nodeId;
  final String? firmwareVersion;
  final int? battery;
  final int? uptimeSeconds;
  final String? errorMessage;
  final DateTime? lastHeartbeat;

  const GatewayState({
    this.status = GatewayConnectionStatus.disconnected,
    this.ip = AppConstants.defaultGatewayIp,
    this.port = AppConstants.defaultGatewayHttpPort,
    this.deviceName,
    this.nodeId,
    this.firmwareVersion,
    this.battery,
    this.uptimeSeconds,
    this.errorMessage,
    this.lastHeartbeat,
  });

  bool get isConnected => status == GatewayConnectionStatus.connected;

  GatewayState copyWith({
    GatewayConnectionStatus? status,
    String? ip,
    int? port,
    String? deviceName,
    String? nodeId,
    String? firmwareVersion,
    int? battery,
    int? uptimeSeconds,
    String? errorMessage,
    DateTime? lastHeartbeat,
  }) {
    return GatewayState(
      status: status ?? this.status,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      deviceName: deviceName ?? this.deviceName,
      nodeId: nodeId ?? this.nodeId,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      battery: battery ?? this.battery,
      uptimeSeconds: uptimeSeconds ?? this.uptimeSeconds,
      errorMessage: errorMessage ?? this.errorMessage,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
    );
  }
}

class GatewayNotifier extends StateNotifier<GatewayState> {
  GatewayNotifier() : super(const GatewayState());

  void setConnecting(String ip, int port) {
    state = state.copyWith(
      status: GatewayConnectionStatus.connecting,
      ip: ip,
      port: port,
      errorMessage: null,
    );
  }

  void setConnected({
    required String deviceName,
    required String nodeId,
    required String firmwareVersion,
    int? battery,
    int? uptimeSeconds,
  }) {
    state = state.copyWith(
      status: GatewayConnectionStatus.connected,
      deviceName: deviceName,
      nodeId: nodeId,
      firmwareVersion: firmwareVersion,
      battery: battery,
      uptimeSeconds: uptimeSeconds,
      lastHeartbeat: DateTime.now(),
      errorMessage: null,
    );
  }

  void setDisconnected() {
    state = state.copyWith(
      status: GatewayConnectionStatus.disconnected,
      errorMessage: null,
    );
  }

  void setReconnecting() {
    state = state.copyWith(
      status: GatewayConnectionStatus.reconnecting,
    );
  }

  void setError(String message) {
    state = state.copyWith(
      status: GatewayConnectionStatus.error,
      errorMessage: message,
    );
  }

  void updateHeartbeat({int? battery, int? uptimeSeconds}) {
    state = state.copyWith(
      lastHeartbeat: DateTime.now(),
      battery: battery ?? state.battery,
      uptimeSeconds: uptimeSeconds ?? state.uptimeSeconds,
    );
  }
}

final gatewayStateProvider =
    StateNotifierProvider<GatewayNotifier, GatewayState>((ref) {
  return GatewayNotifier();
});

// --- NODE REGISTRY STATE ---

class NodeListNotifier extends StateNotifier<List<MeshNode>> {
  final NodeRepository _repository;

  NodeListNotifier(this._repository) : super([]) {
    loadNodes();
  }

  Future<void> loadNodes() async {
    final nodes = await _repository.getNodes();
    state = nodes;
  }

  Future<void> addOrUpdateNode(MeshNode node) async {
    await _repository.saveNode(node);
    await loadNodes();
  }

  Future<void> removeNode(String id) async {
    await _repository.deleteNode(id);
    await loadNodes();
  }

  Future<void> updateLocation(String id, double lat, double lon) async {
    await _repository.updateNodeLocation(id, lat, lon);
    await loadNodes();
  }

  Future<void> updateTelemetry({
    required String id,
    required int battery,
    required int rssi,
    required double snr,
    required int hopCount,
    required bool isOnline,
  }) async {
    await _repository.updateNodeTelemetry(
      id: id,
      battery: battery,
      rssi: rssi,
      snr: snr,
      hopCount: hopCount,
      isOnline: isOnline,
    );
    await loadNodes();
  }
}

final nodeListProvider =
    StateNotifierProvider<NodeListNotifier, List<MeshNode>>((ref) {
  final repo = ref.watch(nodeRepositoryProvider);
  return NodeListNotifier(repo);
});

// --- GEO NOTES STATE ---

class NoteListNotifier extends StateNotifier<List<GeoNote>> {
  final NoteRepository _repository;

  NoteListNotifier(this._repository) : super([]) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    final notes = await _repository.getNotes();
    state = notes;
  }

  Future<void> addOrUpdateNote(GeoNote note) async {
    await _repository.saveNote(note);
    await loadNotes();
  }

  Future<void> removeNote(String id) async {
    await _repository.deleteNote(id);
    await loadNotes();
  }

  Future<void> updateSyncStatus(String id, NoteSyncStatus status) async {
    await _repository.updateNoteSyncStatus(id, status);
    await loadNotes();
  }
}

final noteListProvider =
    StateNotifierProvider<NoteListNotifier, List<GeoNote>>((ref) {
  final repo = ref.watch(noteRepositoryProvider);
  return NoteListNotifier(repo);
});

// --- MESSAGES STATE ---

class MessageListNotifier extends StateNotifier<List<MeshMessage>> {
  final MessageRepository _repository;

  MessageListNotifier(this._repository) : super([]) {
    loadMessages();
  }

  Future<void> loadMessages() async {
    final msgs = await _repository.getAllMessages();
    state = msgs;
  }

  Future<void> addMessage(MeshMessage message) async {
    await _repository.saveMessage(message);
    await loadMessages();
  }

  Future<void> markDelivered(String messageId) async {
    await _repository.markMessageDelivered(messageId);
    await loadMessages();
  }

  Future<void> markFailed(String messageId) async {
    await _repository.markMessageFailed(messageId);
    await loadMessages();
  }
}

final messageListProvider =
    StateNotifierProvider<MessageListNotifier, List<MeshMessage>>((ref) {
  final repo = ref.watch(messageRepositoryProvider);
  return MessageListNotifier(repo);
});

// --- EMERGENCY EVENTS STATE ---

class EmergencyListNotifier extends StateNotifier<List<EmergencyEvent>> {
  final DMeshDatabase _database;

  EmergencyListNotifier(this._database) : super([]) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    final rows = await _database.getAllEmergencyEvents();
    state = rows.map((r) => EmergencyEvent(
      id: r['id'] as String,
      emergencyType: r['emergency_type'] as String,
      sourceNode: r['source_node'] as String,
      latitude: (r['latitude'] as num).toDouble(),
      longitude: (r['longitude'] as num).toDouble(),
      severity: EmergencyEvent.parseSeverity(r['severity'] as String? ?? 'critical'),
      description: r['description'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch((r['timestamp'] as num).toInt()),
      isAcknowledged: (r['is_acknowledged'] as int?) == 1,
      acknowledgedBy: r['acknowledged_by'] as String?,
      rssi: (r['rssi'] as num?)?.toInt(),
      snr: (r['snr'] as num?)?.toDouble(),
    )).toList();
  }

  Future<void> addEvent(EmergencyEvent event) async {
    await _database.insertEmergencyEvent({
      'id': event.id,
      'emergency_type': event.emergencyType,
      'source_node': event.sourceNode,
      'latitude': event.latitude,
      'longitude': event.longitude,
      'severity': event.severity.name,
      'description': event.description,
      'timestamp': event.timestamp.millisecondsSinceEpoch,
      'is_acknowledged': event.isAcknowledged ? 1 : 0,
      'acknowledged_by': event.acknowledgedBy,
      'rssi': event.rssi,
      'snr': event.snr,
    });
    await loadEvents();
  }

  Future<void> acknowledge(String id, String ackBy) async {
    await _database.acknowledgeEmergency(id, ackBy);
    await loadEvents();
  }
}

final emergencyListProvider =
    StateNotifierProvider<EmergencyListNotifier, List<EmergencyEvent>>((ref) {
  final db = ref.watch(databaseProvider);
  return EmergencyListNotifier(db);
});

// --- NETWORK ROUTES STATE ---

class RouteListNotifier extends StateNotifier<List<MeshRoute>> {
  final DMeshDatabase _database;

  RouteListNotifier(this._database) : super([]) {
    loadRoutes();
  }

  Future<void> loadRoutes() async {
    final rows = await _database.getAllRoutes();
    // Parse routes
    state = [];
  }

  void setRoutes(List<MeshRoute> routes) {
    state = routes;
  }
}

final routeListProvider =
    StateNotifierProvider<RouteListNotifier, List<MeshRoute>>((ref) {
  final db = ref.watch(databaseProvider);
  return RouteListNotifier(db);
});

