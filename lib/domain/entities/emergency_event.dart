enum EmergencySeverity {
  advisory,
  warning,
  critical,
  lifeThreatening,
}

class EmergencyEvent {
  final String id;
  final String emergencyType;
  final String sourceNode;
  final double latitude;
  final double longitude;
  final EmergencySeverity severity;
  final String description;
  final DateTime timestamp;
  final bool isAcknowledged;
  final String? acknowledgedBy;
  final int? rssi;
  final double? snr;

  const EmergencyEvent({
    required this.id,
    required this.emergencyType,
    required this.sourceNode,
    required this.latitude,
    required this.longitude,
    required this.severity,
    required this.description,
    required this.timestamp,
    this.isAcknowledged = false,
    this.acknowledgedBy,
    this.rssi,
    this.snr,
  });

  EmergencyEvent copyWith({
    String? id,
    String? emergencyType,
    String? sourceNode,
    double? latitude,
    double? longitude,
    EmergencySeverity? severity,
    String? description,
    DateTime? timestamp,
    bool? isAcknowledged,
    String? acknowledgedBy,
    int? rssi,
    double? snr,
  }) {
    return EmergencyEvent(
      id: id ?? this.id,
      emergencyType: emergencyType ?? this.emergencyType,
      sourceNode: sourceNode ?? this.sourceNode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      rssi: rssi ?? this.rssi,
      snr: snr ?? this.snr,
    );
  }

  static EmergencySeverity parseSeverity(String str) {
    switch (str.toLowerCase()) {
      case 'advisory':
        return EmergencySeverity.advisory;
      case 'warning':
        return EmergencySeverity.warning;
      case 'life_threatening':
      case 'lifethreatening':
        return EmergencySeverity.lifeThreatening;
      default:
        return EmergencySeverity.critical;
    }
  }
}

