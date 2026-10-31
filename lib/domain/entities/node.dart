enum NodeType {
  gateway,
  relay,
  client,
  medical,
  command,
  hazard,
}

class MeshNode {
  final String id;
  final String name;
  final NodeType type;
  final double? latitude;
  final double? longitude;
  final int batteryPercentage;
  final double batteryVoltage;
  final int rssi;
  final double snr;
  final int hopCount;
  final bool isOnline;
  final DateTime lastSeen;
  final bool isVerified;
  final String? description;

  const MeshNode({
    required this.id,
    required this.name,
    required this.type,
    this.latitude,
    this.longitude,
    this.batteryPercentage = 100,
    this.batteryVoltage = 4.2,
    this.rssi = -80,
    this.snr = 8.0,
    this.hopCount = 0,
    this.isOnline = false,
    required this.lastSeen,
    this.isVerified = false,
    this.description,
  });

  bool get hasValidLocation =>
      latitude != null &&
      longitude != null &&
      latitude! >= -90 &&
      latitude! <= 90 &&
      longitude! >= -180 &&
      longitude! <= 180;

  MeshNode copyWith({
    String? id,
    String? name,
    NodeType? type,
    double? latitude,
    double? longitude,
    int? batteryPercentage,
    double? batteryVoltage,
    int? rssi,
    double? snr,
    int? hopCount,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isVerified,
    String? description,
  }) {
    return MeshNode(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      rssi: rssi ?? this.rssi,
      snr: snr ?? this.snr,
      hopCount: hopCount ?? this.hopCount,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isVerified: isVerified ?? this.isVerified,
      description: description ?? this.description,
    );
  }

  static NodeType parseNodeType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'gateway':
        return NodeType.gateway;
      case 'relay':
        return NodeType.relay;
      case 'medical':
        return NodeType.medical;
      case 'command':
        return NodeType.command;
      case 'hazard':
        return NodeType.hazard;
      default:
        return NodeType.client;
    }
  }

  String get typeString => type.name;
}

