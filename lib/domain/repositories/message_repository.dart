import '../entities/message.dart';

abstract class MessageRepository {
  Future<List<MeshMessage>> getMessagesForNode(String localNodeId, String peerNodeId);
  Future<List<MeshMessage>> getAllMessages();
  Future<void> saveMessage(MeshMessage message);
  Future<void> markMessageDelivered(String messageId);
  Future<void> markMessageFailed(String messageId);
}

