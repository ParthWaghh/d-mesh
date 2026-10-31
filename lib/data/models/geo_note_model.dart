import '../../domain/entities/geo_note.dart';

class GeoNoteModel extends GeoNote {
  const GeoNoteModel({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    super.priority,
    required super.latitude,
    required super.longitude,
    required super.authorNodeId,
    required super.createdAt,
    super.syncStatus,
    super.targetNodeId,
  });

  factory GeoNoteModel.fromEntity(GeoNote entity) {
    return GeoNoteModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      category: entity.category,
      priority: entity.priority,
      latitude: entity.latitude,
      longitude: entity.longitude,
      authorNodeId: entity.authorNodeId,
      createdAt: entity.createdAt,
      syncStatus: entity.syncStatus,
      targetNodeId: entity.targetNodeId,
    );
  }

  factory GeoNoteModel.fromMap(Map<String, dynamic> map) {
    return GeoNoteModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: GeoNote.parseCategory(map['category'] as String? ?? 'general'),
      priority: GeoNote.parsePriority(map['priority'] as String? ?? 'normal'),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      authorNodeId: map['author_node_id'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch((map['created_at'] as num).toInt()),
      syncStatus: GeoNote.parseSyncStatus(map['sync_status'] as String? ?? 'local'),
      targetNodeId: map['target_node_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'priority': priority.name,
      'latitude': latitude,
      'longitude': longitude,
      'author_node_id': authorNodeId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'sync_status': syncStatus.name,
      'target_node_id': targetNodeId,
    };
  }

  factory GeoNoteModel.fromJson(Map<String, dynamic> json) {
    return GeoNoteModel(
      id: (json['note_id'] ?? json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      category: GeoNote.parseCategory((json['category'] ?? 'general') as String),
      priority: GeoNote.parsePriority((json['priority'] ?? 'normal') as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      authorNodeId: (json['author_node_id'] ?? json['author'] ?? 'UNKNOWN') as String,
      createdAt: json['created_at'] != null
          ? (json['created_at'] is int
              ? (json['created_at'] > 2000000000
                  ? DateTime.fromMillisecondsSinceEpoch(json['created_at'])
                  : DateTime.fromMillisecondsSinceEpoch(json['created_at'] * 1000))
              : DateTime.now())
          : DateTime.now(),
      syncStatus: GeoNote.parseSyncStatus((json['sync_status'] ?? 'received') as String),
      targetNodeId: json['target_node_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'note_id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'priority': priority.name,
      'latitude': latitude,
      'longitude': longitude,
      'author_node_id': authorNodeId,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
      'sync_status': syncStatus.name,
      'target_node_id': targetNodeId,
    };
  }
}

