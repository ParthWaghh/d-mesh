import '../../domain/entities/emergency_event.dart';

class EmergencyEventModel extends EmergencyEvent {
  const EmergencyEventModel({
    required super.id,
    required super.emergencyType,
    required super.sourceNode,
    required super.latitude,
    required super.longitude,
    required super.severity,
    required super.description,
    required super.timestamp,
    super.isAcknowledged,
    super.acknowledgedBy,
    super.rssi,
    super.snr,
  });

  factory EmergencyEventModel.fromEntity(EmergencyEvent entity) {
    return EmergencyEventModel(
      id: entity.id,
      emergencyType: entity.emergencyType,
      sourceNode: entity.sourceNode,
      latitude: entity.latitude,
      longitude: entity.longitude,
      severity: entity.severity,
      description: entity.description,
      timestamp: entity.timestamp,
      isAcknowledged: entity.isAcknowledged,
      acknowledgedBy: entity.acknowledgedBy,
      rssi: entity.rssi,
      snr: entity.snr,
    );
  }

  factory EmergencyEventModel.fromMap(Map<String, dynamic> map) {
    return EmergencyEventModel(
      id: map['id'] as String,
      emergencyType: map['emergency_type'] as String,
      sourceNode: map['source_node'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      severity: EmergencyEvent.parseSeverity(map['severity'] as String? ?? 'critical'),
      description: map['description'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch((map['timestamp'] as num).toInt()),
      isAcknowledged: (map['is_acknowledged'] as int?) == 1,
      acknowledgedBy: map['acknowledged_by'] as String?,
      rssi: (map['rssi'] as num?)?.toInt(),
      snr: (map['snr'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'emergency_type': emergencyType,
      'source_node': sourceNode,
      'latitude': latitude,
      'longitude': longitude,
      'severity': severity.name,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'is_acknowledged': isAcknowledged ? 1 : 0,
      'acknowledged_by': acknowledgedBy,
      'rssi': rssi,
      'snr': snr,
    };
  }

  factory EmergencyEventModel.fromJson(Map<String, dynamic> json) {
    return EmergencyEventModel(
      id: (json['alert_id'] ?? json['id'] ?? '') as String,
      emergencyType: (json['emergency_type'] ?? 'general_sos') as String,
      sourceNode: (json['source_node'] ?? 'UNKNOWN') as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      severity: EmergencyEvent.parseSeverity((json['severity'] ?? 'critical') as String),
      description: (json['description'] ?? '') as String,
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] is int
              ? (json['timestamp'] > 2000000000
                  ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
                  : DateTime.fromMillisecondsSinceEpoch(json['timestamp'] * 1000))
              : DateTime.now())
          : DateTime.now(),
      isAcknowledged: json['is_acknowledged'] == true,
      acknowledgedBy: json['acknowledged_by'] as String?,
      rssi: (json['rssi'] as num?)?.toInt(),
      snr: (json['snr'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alert_id': id,
      'emergency_type': emergencyType,
      'source_node': sourceNode,
      'latitude': latitude,
      'longitude': longitude,
      'severity': severity.name,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch ~/ 1000,
      'is_acknowledged': isAcknowledged,
      'acknowledged_by': acknowledgedBy,
      'rssi': rssi,
      'snr': snr,
    };
  }
}

