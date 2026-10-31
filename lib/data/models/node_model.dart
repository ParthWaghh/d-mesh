import '../../domain/entities/node.dart';

class NodeModel extends MeshNode {
  const NodeModel({
    required super.id,
    required super.name,
    required super.type,
    super.latitude,
    super.longitude,
    super.batteryPercentage,
    super.batteryVoltage,
    super.rssi,
    super.snr,
    super.hopCount,
    super.isOnline,
    required super.lastSeen,
    super.isVerified,
    super.description,
  });

  factory NodeModel.fromEntity(MeshNode entity) {
    return NodeModel(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      latitude: entity.latitude,
      longitude: entity.longitude,
      batteryPercentage: entity.batteryPercentage,
      batteryVoltage: entity.batteryVoltage,
      rssi: entity.rssi,
      snr: entity.snr,
      hopCount: entity.hopCount,
      isOnline: entity.isOnline,
      lastSeen: entity.lastSeen,
      isVerified: entity.isVerified,
      description: entity.description,
    );
  }

  factory NodeModel.fromMap(Map<String, dynamic> map) {
    return NodeModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: MeshNode.parseNodeType(map['type'] as String? ?? 'client'),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      batteryPercentage: (map['battery_percentage'] as num?)?.toInt() ?? 100,
      batteryVoltage: (map['battery_voltage'] as num?)?.toDouble() ?? 4.2,
      rssi: (map['rssi'] as num?)?.toInt() ?? -80,
      snr: (map['snr'] as num?)?.toDouble() ?? 8.0,
      hopCount: (map['hop_count'] as num?)?.toInt() ?? 0,
      isOnline: (map['is_online'] as int?) == 1,
      lastSeen: DateTime.fromMillisecondsSinceEpoch((map['last_seen'] as num).toInt()),
      isVerified: (map['is_verified'] as int?) == 1,
      description: map['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': typeString,
      'latitude': latitude,
      'longitude': longitude,
      'battery_percentage': batteryPercentage,
      'battery_voltage': batteryVoltage,
      'rssi': rssi,
      'snr': snr,
      'hop_count': hopCount,
      'is_online': isOnline ? 1 : 0,
      'last_seen': lastSeen.millisecondsSinceEpoch,
      'is_verified': isVerified ? 1 : 0,
      'description': description,
    };
  }

  factory NodeModel.fromJson(Map<String, dynamic> json) {
    return NodeModel(
      id: (json['node_id'] ?? json['id']) as String,
      name: (json['name'] ?? 'LoRa Node') as String,
      type: MeshNode.parseNodeType((json['type'] ?? 'client') as String),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      batteryPercentage: (json['battery'] ?? json['battery_percentage'] as num?)?.toInt() ?? 100,
      batteryVoltage: (json['battery_voltage'] as num?)?.toDouble() ?? 4.2,
      rssi: (json['rssi'] as num?)?.toInt() ?? -80,
      snr: (json['snr'] as num?)?.toDouble() ?? 8.0,
      hopCount: (json['hops'] ?? json['hop_count'] as num?)?.toInt() ?? 0,
      isOnline: json['is_online'] == true || json['is_online'] == 1,
      lastSeen: json['last_seen'] != null
          ? (json['last_seen'] is int
              ? (json['last_seen'] > 2000000000
                  ? DateTime.fromMillisecondsSinceEpoch(json['last_seen'])
                  : DateTime.fromMillisecondsSinceEpoch(json['last_seen'] * 1000))
              : DateTime.now())
          : DateTime.now(),
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'node_id': id,
      'name': name,
      'type': typeString,
      'latitude': latitude,
      'longitude': longitude,
      'battery': batteryPercentage,
      'battery_voltage': batteryVoltage,
      'rssi': rssi,
      'snr': snr,
      'hops': hopCount,
      'is_online': isOnline,
      'last_seen': lastSeen.millisecondsSinceEpoch ~/ 1000,
      'is_verified': isVerified,
      'description': description,
    };
  }
}

