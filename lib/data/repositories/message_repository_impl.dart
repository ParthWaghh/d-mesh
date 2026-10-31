import '../../domain/entities/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/local/dmesh_database.dart';
import '../models/message_model.dart';

class MessageRepositoryImpl implements MessageRepository {
  final DMeshDatabase _database;

  MessageRepositoryImpl({DMeshDatabase? database})
      : _database = database ?? DMeshDatabase.instance;

  @override
  Future<List<MeshMessage>> getMessagesForNode(String localNodeId, String peerNodeId) async {
    final rows = await _database.getMessagesForConversation(localNodeId, peerNodeId);
    return rows.map((r) => MessageModel.fromMap(r)).toList();
  }

  @override
  Future<List<MeshMessage>> getAllMessages() async {
    final rows = await _database.getAllMessages();
    return rows.map((r) => MessageModel.fromMap(r)).toList();
  }

  @override
  Future<void> saveMessage(MeshMessage message) async {
    final model = MessageModel.fromEntity(message);
    await _database.insertMessage(model.toMap());
  }

  @override
  Future<void> markMessageDelivered(String messageId) async {
    await _database.updateMessageStatus(messageId, MessageStatus.delivered.name);
  }

  @override
  Future<void> markMessageFailed(String messageId) async {
    await _database.updateMessageStatus(messageId, MessageStatus.failed.name);
  }
}

