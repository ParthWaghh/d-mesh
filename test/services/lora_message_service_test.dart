import 'package:flutter_test/flutter_test.dart';
import '../../lib/domain/entities/message.dart';
import '../../lib/domain/repositories/message_repository.dart';
import '../../lib/services/gateway_communication_service.dart';
import '../../lib/services/lora_message_service.dart';

class MockMessageRepository implements MessageRepository {
  final List<MeshMessage> savedMessages = [];

  @override
  Future<void> saveMessage(MeshMessage message) async {
    savedMessages.add(message);
  }

  @override
  Future<List<MeshMessage>> getAllMessages() async => savedMessages;

  @override
  Future<List<MeshMessage>> getMessagesForNode(String localNodeId, String peerNodeId) async => savedMessages;

  @override
  Future<void> markMessageDelivered(String messageId) async {}

  @override
  Future<void> markMessageFailed(String messageId) async {}
}

class MockGatewayCommService extends GatewayCommunicationService {
  int transmittedPackets = 0;

  @override
  Future<bool> sendMessage(MeshMessage message) async {
    transmittedPackets++;
    return true;
  }
}

void main() {
  group('LoRaMessageService - Deduplication & Queuing', () {
    late LoRaMessageService service;
    late MockMessageRepository mockRepo;
    late MockGatewayCommService mockGateway;

    setUp(() {
      mockRepo = MockMessageRepository();
      mockGateway = MockGatewayCommService();
      service = LoRaMessageService(mockRepo, mockGateway);
    });

    test('isDuplicate should correctly identify duplicate message IDs', () {
      const msgId = 'MSG-UNIQUE-99';

      expect(service.isDuplicate(msgId), isFalse); // First arrival: not duplicate
      expect(service.isDuplicate(msgId), isTrue);  // Second arrival: duplicate!
      expect(service.isDuplicate(msgId), isTrue);  // Third arrival: duplicate!

      expect(service.isDuplicate('MSG-NEW-100'), isFalse);
    });

    test('queueMessage should save to repository and transmit via gateway', () async {
      final message = MeshMessage(
        id: 'MSG-TX-1',
        sourceNode: 'GATEWAY-01',
        destinationNode: 'NODE-002',
        content: 'Check signal status',
        timestamp: DateTime.now(),
      );

      await service.queueMessage(message);

      // Verify repository recorded message
      expect(mockRepo.savedMessages, isNotEmpty);
      expect(mockRepo.savedMessages.first.id, equals('MSG-TX-1'));

      // Verify packet was submitted to gateway
      expect(mockGateway.transmittedPackets, equals(1));
    });
  });
}

