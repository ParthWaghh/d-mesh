import 'dart:async';
import '../domain/entities/message.dart';
import '../domain/repositories/message_repository.dart';
import 'gateway_communication_service.dart';

class LoRaMessageService {
  final MessageRepository _messageRepository;
  final GatewayCommunicationService _gatewayService;
  final Set<String> _processedMessageIds = {};
  final List<MeshMessage> _outboundQueue = [];
  bool _isProcessingQueue = false;

  LoRaMessageService(this._messageRepository, this._gatewayService);

  /// Deduplication check for received messages
  bool isDuplicate(String messageId) {
    if (_processedMessageIds.contains(messageId)) {
      return true;
    }
    _processedMessageIds.add(messageId);
    if (_processedMessageIds.length > 500) {
      _processedMessageIds.remove(_processedMessageIds.first);
    }
    return false;
  }

  /// Enqueue outbound message for delivery through gateway
  Future<void> queueMessage(MeshMessage message) async {
    await _messageRepository.saveMessage(message.copyWith(status: MessageStatus.queued));
    _outboundQueue.add(message);
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue || _outboundQueue.isEmpty) return;
    _isProcessingQueue = true;

    while (_outboundQueue.isNotEmpty) {
      final msg = _outboundQueue.removeAt(0);
      final success = await _gatewayService.sendMessage(msg);

      if (success) {
        await _messageRepository.saveMessage(msg.copyWith(status: MessageStatus.sent));
      } else {
        await _messageRepository.markMessageFailed(msg.id);
      }
      // Small pause between LoRa packet transmissions to avoid RF collisions
      await Future.delayed(const Duration(milliseconds: 350));
    }

    _isProcessingQueue = false;
  }
}

