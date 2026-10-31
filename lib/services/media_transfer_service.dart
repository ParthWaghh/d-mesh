import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../domain/entities/message.dart';
import 'gateway_communication_service.dart';

class MediaMetadata {
  final String mediaId;
  final String mediaType; // 'audio' or 'image'
  final String fileName;
  final int fileSizeBytes;
  final String sha256Checksum;
  final String localFilePath;
  final String? gatewayDownloadUrl;

  const MediaMetadata({
    required this.mediaId,
    required this.mediaType,
    required this.fileName,
    required this.fileSizeBytes,
    required this.sha256Checksum,
    required this.localFilePath,
    this.gatewayDownloadUrl,
  });

  Map<String, dynamic> toJson() => {
    'media_id': mediaId,
    'media_type': mediaType,
    'file_name': fileName,
    'size_bytes': fileSizeBytes,
    'sha256': sha256Checksum,
    'url': gatewayDownloadUrl,
  };
}

class MediaTransferService {
  final String gatewayIp;
  final int port;
  final GatewayCommunicationService _gatewayCommService;

  MediaTransferService(
    this._gatewayCommService, {
    this.gatewayIp = AppConstants.defaultGatewayIp,
    this.port = AppConstants.defaultGatewayHttpPort,
  });

  /// Computes SHA-256 checksum of local media file
  Future<String> calculateChecksum(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  /// Transfers high-bandwidth media (voice memo / compressed image) to ESP32 gateway over local Wi-Fi
  Future<MediaMetadata?> uploadMediaOverWifi({
    required File file,
    required String mediaType, // 'audio' or 'image'
    void Function(double progress)? onProgress,
  }) async {
    try {
      final checksum = await calculateChecksum(file);
      final fileName = file.uri.pathSegments.last;
      final fileLength = await file.length();
      final mediaId = 'MED-${DateTime.now().millisecondsSinceEpoch}';

      final uri = Uri.parse('http://$gatewayIp:$port/api/media/upload');
      final request = http.MultipartRequest('POST', uri);
      request.fields['media_id'] = mediaId;
      request.fields['media_type'] = mediaType;
      request.fields['sha256'] = checksum;

      final multipartFile = await http.MultipartFile.fromPath('file', file.path);
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final downloadUrl = 'http://$gatewayIp:$port/api/media/$mediaId';
        final metadata = MediaMetadata(
          mediaId: mediaId,
          mediaType: mediaType,
          fileName: fileName,
          fileSizeBytes: fileLength,
          sha256Checksum: checksum,
          localFilePath: file.path,
          gatewayDownloadUrl: downloadUrl,
        );

        // After successful Wi-Fi upload, broadcast a compact LoRa notification packet!
        await _dispatchLoRaMediaNotification(metadata);

        return metadata;
      }
    } catch (_) {}
    return null;
  }

  /// Dispatches compact LoRa notification (~60 bytes) informing remote mesh nodes of media availability
  Future<bool> _dispatchLoRaMediaNotification(MediaMetadata meta) async {
    final compactNotice = MeshMessage(
      id: meta.mediaId,
      sourceNode: 'GATEWAY-01',
      destinationNode: 'BROADCAST',
      type: MessageType.chat,
      content: '[MEDIA:${meta.mediaType.toUpperCase()}] ${meta.fileName} (${(meta.fileSizeBytes / 1024).toStringAsFixed(1)} KB) - Hash: ${meta.sha256Checksum.substring(0, 8)}',
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );

    return await _gatewayCommService.sendMessage(compactNotice);
  }
}

