enum NoteCategory {
  general,
  medical,
  rescue,
  fire,
  accident,
  flood,
  earthquake,
  hazard,
  emergency,
}

enum NotePriority {
  low,
  normal,
  high,
  critical,
}

enum NoteSyncStatus {
  local,
  sharing,
  synced,
  received,
}

class GeoNote {
  final String id;
  final String title;
  final String description;
  final NoteCategory category;
  final NotePriority priority;
  final double latitude;
  final double longitude;
  final String authorNodeId;
  final DateTime createdAt;
  final NoteSyncStatus syncStatus;
  final String? targetNodeId;

  const GeoNote({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.priority = NotePriority.normal,
    required this.latitude,
    required this.longitude,
    required this.authorNodeId,
    required this.createdAt,
    this.syncStatus = NoteSyncStatus.local,
    this.targetNodeId,
  });

  GeoNote copyWith({
    String? id,
    String? title,
    String? description,
    NoteCategory? category,
    NotePriority? priority,
    double? latitude,
    double? longitude,
    String? authorNodeId,
    DateTime? createdAt,
    NoteSyncStatus? syncStatus,
    String? targetNodeId,
  }) {
    return GeoNote(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      authorNodeId: authorNodeId ?? this.authorNodeId,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      targetNodeId: targetNodeId ?? this.targetNodeId,
    );
  }

  static NoteCategory parseCategory(String str) {
    switch (str.toLowerCase()) {
      case 'medical':
        return NoteCategory.medical;
      case 'rescue':
        return NoteCategory.rescue;
      case 'fire':
        return NoteCategory.fire;
      case 'accident':
        return NoteCategory.accident;
      case 'flood':
        return NoteCategory.flood;
      case 'earthquake':
        return NoteCategory.earthquake;
      case 'hazard':
        return NoteCategory.hazard;
      case 'emergency':
        return NoteCategory.emergency;
      default:
        return NoteCategory.general;
    }
  }

  static NotePriority parsePriority(String str) {
    switch (str.toLowerCase()) {
      case 'low':
        return NotePriority.low;
      case 'high':
        return NotePriority.high;
      case 'critical':
        return NotePriority.critical;
      default:
        return NotePriority.normal;
    }
  }

  static NoteSyncStatus parseSyncStatus(String str) {
    switch (str.toLowerCase()) {
      case 'sharing':
        return NoteSyncStatus.sharing;
      case 'synced':
        return NoteSyncStatus.synced;
      case 'received':
        return NoteSyncStatus.received;
      default:
        return NoteSyncStatus.local;
    }
  }
}

