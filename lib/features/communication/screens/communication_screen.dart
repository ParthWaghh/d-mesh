import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/message.dart';
import '../../shared/providers.dart';
import '../widgets/audio_memo_sheet.dart';

class CommunicationScreen extends ConsumerStatefulWidget {
  const CommunicationScreen({super.key});

  @override
  ConsumerState<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends ConsumerState<CommunicationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedDestination = 'BROADCAST';
  bool _isRecording = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final newMessage = MeshMessage(
      id: const Uuid().v4(),
      sourceNode: 'GATEWAY-01',
      destinationNode: _selectedDestination,
      content: text,
      timestamp: DateTime.now(),
      status: MessageStatus.queued,
      type: MessageType.chat,
      hopCount: 1,
    );

    ref.read(messageListProvider.notifier).addMessage(newMessage);
    _textController.clear();

    // Auto scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openAudioMemoModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AudioMemoSheet(
        destinationNode: _selectedDestination,
        onDispatched: () {
          ref.read(messageListProvider.notifier).loadMessages();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messageListProvider);
    final nodes = ref.watch(nodeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LORA MESH CHAT'),
        actions: [
          // Voice memo action
          IconButton(
            tooltip: 'Record Wi-Fi Voice Memo',
            icon: const Icon(Icons.graphic_eq, color: AppColors.cyan),
            onPressed: _openAudioMemoModal,
          ),
          // Destination Node Selector Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDestination,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.bold, fontSize: 13),
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.cyan),
                items: [
                  const DropdownMenuItem(
                    value: 'BROADCAST',
                    child: Text('BROADCAST (ALL)'),
                  ),
                  ...nodes.map((n) => DropdownMenuItem(
                        value: n.id,
                        child: Text('${n.id} - ${n.name}'),
                      )),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDestination = val);
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sub-header displaying link info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface.withOpacity(0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.radio, size: 14, color: AppColors.cyan),
                    const SizedBox(width: 6),
                    Text(
                      'TARGET: $_selectedDestination',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const Text(
                  '433.175 MHz | SF9 | BW 125k',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),

          // Message list
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        const Text('No messages on current frequency', style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        const Text('Send a broadcast or select a peer node', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.sourceNode == 'GATEWAY-01';
                      return _buildMessageBubble(msg, isMe);
                    },
                  ),
          ),

          // Composer Input Bar
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MeshMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.surfaceLight : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 12),
          ),
          border: Border.all(
            color: isMe ? AppColors.cyan.withOpacity(0.3) : AppColors.surfaceBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg.sourceNode,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isMe ? AppColors.cyan : AppColors.orangeWarning,
                  ),
                ),
                if (msg.isBroadcast) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.orangeWarning.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('ALL', style: TextStyle(color: AppColors.orangeWarning, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              msg.content,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (msg.rssi != null) ...[
                  Text('${msg.rssi} dBm', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  const SizedBox(width: 6),
                ],
                Text(
                  '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.status == MessageStatus.delivered
                        ? Icons.done_all
                        : (msg.status == MessageStatus.sent ? Icons.done : Icons.access_time),
                    size: 12,
                    color: msg.status == MessageStatus.delivered ? AppColors.greenOnline : AppColors.textMuted,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Speech-to-text mic button
            IconButton(
              tooltip: 'Speech-to-Text Dictation',
              icon: Icon(
                _isRecording ? Icons.mic : Icons.mic_none,
                color: _isRecording ? AppColors.redEmergency : AppColors.cyan,
              ),
              onPressed: () {
                setState(() => _isRecording = !_isRecording);
                if (_isRecording) {
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted && _isRecording) {
                      _textController.text = 'Emergency at sector 4. Team requires immediate assistance.';
                      setState(() => _isRecording = false);
                    }
                  });
                }
              },
            ),
            // Audio Voice Memo Button
            IconButton(
              tooltip: 'Record Voice Memo',
              icon: const Icon(Icons.audio_file_outlined, color: AppColors.cyan),
              onPressed: _openAudioMemoModal,
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: _isRecording ? 'Listening for emergency speech...' : 'Type message for LoRa mesh...',
                  fillColor: AppColors.charcoal,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: AppColors.darkBackground,
              ),
              icon: const Icon(Icons.send, size: 18),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
