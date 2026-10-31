import 'dart:convert';
import '../../domain/entities/message.dart';

class MessageModel extends MeshMessage {
  const MessageModel({
    required super.id,
    required super.sourceNode,
    required super.destinationNode,
    required super.content,
    required super.timestamp,
    super.type,
    super.status,
    super.rssi,
    super.snr,
    super.hopCount,
    super.isEncrypted,
    super.relayNodes,
  });

  factory MessageModel.fromEntity(MeshMessage entity) {
    return MessageModel(
      id: entity.id,
      sourceNode: entity.sourceNode,
      destinationNode: entity.destinationNode,
      content: entity.content,
      timestamp: entity.timestamp,
      type: entity.type,
      status: entity.status,
      rssi: entity.rssi,
      snr: entity.snr,
      hopCount: entity.hopCount,
      isEncrypted: entity.isEncrypted,
      relayNodes: entity.relayNodes,
    );
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    List<String> relays = [];
    if (map['relay_nodes'] != null && map['relay_nodes'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['relay_nodes'].toString());
        if (decoded is List) {
          relays = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return MessageModel(
      id: map['id'] as String,
      sourceNode: map['source_node'] as String,
      destinationNode: map['destination_node'] as String,
      content: map['content'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch((map['timestamp'] as num).toInt()),
      type: MeshMessage.parseType(map['type'] as String? ?? 'chat'),
      status: MeshMessage.parseStatus(map['status'] as String? ?? 'draft'),
      rssi: (map['rssi'] as num?)?.toInt(),
      snr: (map['snr'] as num?)?.toDouble(),
      hopCount: (map['hop_count'] as num?)?.toInt() ?? 0,
      isEncrypted: (map['is_encrypted'] as int?) == 1,
      relayNodes: relays,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source_node': sourceNode,
      'destination_node': destinationNode,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type.name,
      'status': status.name,
      'rssi': rssi,
      'snr': snr,
      'hop_count': hopCount,
      'is_encrypted': isEncrypted ? 1 : 0,
      'relay_nodes': jsonEncode(relayNodes),
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    List<String> relays = [];
    if (json['relay_nodes'] is List) {
      relays = (json['relay_nodes'] as List).map((e) => e.toString()).toList();
    }

    return MessageModel(
      id: (json['message_id'] ?? json['id'] ?? '') as String,
      sourceNode: (json['source_node'] ?? 'UNKNOWN') as String,
      destinationNode: (json['destination_node'] ?? 'BROADCAST') as String,
      content: (json['message'] ?? json['content'] ?? '') as String,
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] is int
              ? (json['timestamp'] > 2000000000
                  ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
                  : DateTime.fromMillisecondsSinceEpoch(json['timestamp'] * 1000))
              : DateTime.now())
          : DateTime.now(),
      type: MeshMessage.parseType((json['type'] ?? 'chat') as String),
      status: MeshMessage.parseStatus((json['status'] ?? 'delivered') as String),
      rssi: (json['rssi'] as num?)?.toInt(),
      snr: (json['snr'] as num?)?.toDouble(),
      hopCount: (json['hop_count'] ?? json['hops'] as num?)?.toInt() ?? 0,
      isEncrypted: json['is_encrypted'] == true,
      relayNodes: relays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': id,
      'source_node': sourceNode,
      'destination_node': destinationNode,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch ~/ 1000,
      'type': type.name,
      'status': status.name,
      'rssi': rssi,
      'snr': snr,
      'hop_count': hopCount,
      'is_encrypted': isEncrypted,
      'relay_nodes': relayNodes,
    };
  }
}

