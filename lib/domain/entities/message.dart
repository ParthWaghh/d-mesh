enum MessageType {
  chat,
  sos,
  noteShare,
  telemetry,
  ack,
}

enum MessageStatus {
  draft,
  queued,
  sent,
  delivered,
  failed,
}

class MeshMessage {
  final String id;
  final String sourceNode;
  final String destinationNode;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final MessageStatus status;
  final int? rssi;
  final double? snr;
  final int hopCount;
  final bool isEncrypted;
  final List<String> relayNodes;

  const MeshMessage({
    required this.id,
    required this.sourceNode,
    required this.destinationNode,
    required this.content,
    required this.timestamp,
    this.type = MessageType.chat,
    this.status = MessageStatus.draft,
    this.rssi,
    this.snr,
    this.hopCount = 0,
    this.isEncrypted = false,
    this.relayNodes = const [],
  });

  bool get isBroadcast => destinationNode.toUpperCase() == 'BROADCAST';
  bool get isAcked => status == MessageStatus.delivered;

  MeshMessage copyWith({
    String? id,
    String? sourceNode,
    String? destinationNode,
    String? content,
    DateTime? timestamp,
    MessageType? type,
    MessageStatus? status,
    int? rssi,
    double? snr,
    int? hopCount,
    bool? isEncrypted,
    List<String>? relayNodes,
  }) {
    return MeshMessage(
      id: id ?? this.id,
      sourceNode: sourceNode ?? this.sourceNode,
      destinationNode: destinationNode ?? this.destinationNode,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      status: status ?? this.status,
      rssi: rssi ?? this.rssi,
      snr: snr ?? this.snr,
      hopCount: hopCount ?? this.hopCount,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      relayNodes: relayNodes ?? this.relayNodes,
    );
  }

  static MessageType parseType(String str) {
    switch (str.toLowerCase()) {
      case 'sos':
        return MessageType.sos;
      case 'note_share':
      case 'noteshare':
        return MessageType.noteShare;
      case 'telemetry':
        return MessageType.telemetry;
      case 'ack':
        return MessageType.ack;
      default:
        return MessageType.chat;
    }
  }

  static MessageStatus parseStatus(String str) {
    switch (str.toLowerCase()) {
      case 'queued':
        return MessageStatus.queued;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.draft;
    }
  }
}

