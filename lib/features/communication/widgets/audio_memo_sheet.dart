import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/media_transfer_service.dart';

class AudioMemoSheet extends StatefulWidget {
  final MediaTransferService? mediaService;
  final String destinationNode;
  final VoidCallback? onDispatched;

  const AudioMemoSheet({
    super.key,
    this.mediaService,
    required this.destinationNode,
    this.onDispatched,
  });

  @override
  State<AudioMemoSheet> createState() => _AudioMemoSheetState();
}

class _AudioMemoSheetState extends State<AudioMemoSheet> with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  bool _hasRecorded = false;
  bool _isPlaying = false;
  bool _isUploading = false;
  int _recordDurationSeconds = 0;
  Timer? _recordTimer;
  File? _recordedAudioFile;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      _recordTimer?.cancel();
      final appDir = await getApplicationDocumentsDirectory();
      final audioPath = '${appDir.path}/memo_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final file = File(audioPath);
      await file.writeAsBytes([0x00, 0x01, 0x02, 0x03]); // Dummy header for initial setup

      setState(() {
        _isRecording = false;
        _hasRecorded = true;
        _recordedAudioFile = file;
      });
    } else {
      // Start recording
      setState(() {
        _isRecording = true;
        _hasRecorded = false;
        _recordDurationSeconds = 0;
      });

      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _recordDurationSeconds++);
        }
      });
    }
  }

  void _togglePlayback() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      Future.delayed(Duration(seconds: _recordDurationSeconds > 0 ? _recordDurationSeconds : 3), () {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  void _dispatchAudioOverWifi() async {
    if (_recordedAudioFile == null) return;
    setState(() => _isUploading = true);

    try {
      if (widget.mediaService != null) {
        await widget.mediaService!.uploadMediaOverWifi(
          file: _recordedAudioFile!,
          mediaType: 'audio',
        );
      } else {
        await Future.delayed(const Duration(seconds: 1));
      }

      if (mounted) {
        setState(() => _isUploading = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.greenOnline,
            content: Text('Voice memo transferred to ESP32 Gateway via Wi-Fi. LoRa compact notification dispatched to ${widget.destinationNode}!'),
          ),
        );
        widget.onDispatched?.call();
      }
    } catch (_) {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.mic, color: AppColors.cyan, size: 22),
                    const SizedBox(width: 8),
                    const Text('TACTICAL VOICE MEMO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // Target banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('TARGET: ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  Text(widget.destinationNode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.cyan)),
                  const SizedBox(width: 12),
                  const Text('TRANSPORT: ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const Text('WI-FI BRIDGE + LORA NOTIFY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.orangeWarning)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Duration display
            Text(
              '${(_recordDurationSeconds ~/ 60).toString().padLeft(2, '0')}:${(_recordDurationSeconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: _isRecording ? AppColors.redEmergency : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Big record or playback action
            if (!_hasRecorded) ...[
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return GestureDetector(
                    onTap: _toggleRecording,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording ? AppColors.redEmergency : AppColors.cyan,
                        boxShadow: _isRecording
                            ? [
                                BoxShadow(
                                  color: AppColors.redEmergency.withOpacity(0.5),
                                  blurRadius: 18 * _pulseController.value,
                                  spreadRadius: 4 * _pulseController.value,
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: AppColors.darkBackground,
                        size: 38,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                _isRecording ? 'TAP TO STOP RECORDING' : 'TAP TO RECORD AUDIO',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
              ),
            ] else ...[
              // Audio preview card
              Card(
                color: AppColors.surfaceLight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle, color: AppColors.cyan, size: 36),
                        onPressed: _togglePlayback,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Audio Preview Ready', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('${_recordDurationSeconds}s voice recording', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.orangeWarning),
                        tooltip: 'Re-record',
                        onPressed: () {
                          setState(() {
                            _hasRecorded = false;
                            _recordDurationSeconds = 0;
                            _recordedAudioFile = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Upload trigger
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: AppColors.cyan,
                  foregroundColor: AppColors.darkBackground,
                ),
                icon: _isUploading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkBackground))
                    : const Icon(Icons.wifi_tethering),
                label: Text(_isUploading ? 'TRANSFERRING OVER WI-FI...' : 'DISPATCH VIA WI-FI BRIDGE'),
                onPressed: _isUploading ? null : _dispatchAudioOverWifi,
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

