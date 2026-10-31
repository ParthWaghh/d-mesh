import 'package:flutter_test/flutter_test.dart';
import '../../lib/data/models/emergency_event_model.dart';
import '../../lib/data/models/geo_note_model.dart';
import '../../lib/data/models/message_model.dart';
import '../../lib/data/models/node_model.dart';
import '../../lib/domain/entities/emergency_event.dart';
import '../../lib/domain/entities/geo_note.dart';
import '../../lib/domain/entities/message.dart';
import '../../lib/domain/entities/node.dart';

void main() {
  group('Data Models - Serialization & Parsing', () {
    test('NodeModel should serialize to SQLite map and deserialize correctly', () {
      final now = DateTime.now();
      final node = NodeModel(
        id: 'NODE-004',
        name: 'Field Medical Team',
        type: NodeType.medical,
        latitude: 19.9912,
        longitude: 73.7815,
        batteryPercentage: 88,
        batteryVoltage: 4.05,
        rssi: -79,
        snr: 9.4,
        hopCount: 1,
        isOnline: true,
        lastSeen: now,
        isVerified: true,
        description: 'Triage outpost',
      );

      final map = node.toMap();
      expect(map['id'], equals('NODE-004'));
      expect(map['is_online'], equals(1));

      final restored = NodeModel.fromMap(map);
      expect(restored.id, equals(node.id));
      expect(restored.type, equals(NodeType.medical));
      expect(restored.latitude, equals(node.latitude));
      expect(restored.isOnline, isTrue);
    });

    test('MessageModel should serialize to and from JSON', () {
      final now = DateTime.now();
      final message = MessageModel(
        id: 'MSG-TEST-001',
        sourceNode: 'NODE-002',
        destinationNode: 'GATEWAY-01',
        content: 'Bridge intact. Crossing sector now.',
        timestamp: now,
        type: MessageType.chat,
        status: MessageStatus.delivered,
        rssi: -84,
        snr: 7.2,
        hopCount: 2,
        relayNodes: ['NODE-003'],
      );

      final json = message.toJson();
      expect(json['message_id'], equals('MSG-TEST-001'));
      expect(json['source_node'], equals('NODE-002'));

      final restored = MessageModel.fromJson(json);
      expect(restored.id, equals(message.id));
      expect(restored.content, equals(message.content));
      expect(restored.relayNodes, contains('NODE-003'));
    });

    test('GeoNoteModel should roundtrip through SQLite Map', () {
      final now = DateTime.now();
      final note = GeoNoteModel(
        id: 'NOTE-101',
        title: 'Blocked Roadway',
        description: 'Fallen trees blocking two lanes.',
        category: NoteCategory.hazard,
        priority: NotePriority.high,
        latitude: 19.9985,
        longitude: 73.7892,
        authorNodeId: 'NODE-001',
        createdAt: now,
        syncStatus: NoteSyncStatus.synced,
      );

      final map = note.toMap();
      final restored = GeoNoteModel.fromMap(map);

      expect(restored.id, equals(note.id));
      expect(restored.category, equals(NoteCategory.hazard));
      expect(restored.priority, equals(NotePriority.high));
      expect(restored.syncStatus, equals(NoteSyncStatus.synced));
    });

    test('EmergencyEventModel should roundtrip through JSON', () {
      final now = DateTime.now();
      final alert = EmergencyEventModel(
        id: 'SOS-991',
        emergencyType: 'medical',
        sourceNode: 'NODE-005',
        latitude: 19.9950,
        longitude: 73.7820,
        severity: EmergencySeverity.lifeThreatening,
        description: 'Immediate casualty extraction needed',
        timestamp: now,
        isAcknowledged: false,
      );

      final json = alert.toJson();
      final restored = EmergencyEventModel.fromJson(json);

      expect(restored.id, equals('SOS-991'));
      expect(restored.severity, equals(EmergencySeverity.lifeThreatening));
      expect(restored.isAcknowledged, isFalse);
    });
  });
}

