import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../domain/entities/emergency_event.dart';
import '../domain/entities/geo_note.dart';
import '../domain/entities/message.dart';
import '../domain/entities/node.dart';

class GatewayCommunicationService {
  final String gatewayIp;
  final int port;

  GatewayCommunicationService({
    this.gatewayIp = AppConstants.defaultGatewayIp,
    this.port = AppConstants.defaultGatewayHttpPort,
  });

  /// Sends a message through the ESP32 gateway over SX1278 LoRa
  Future<bool> sendMessage(MeshMessage message) async {
    try {
      final uri = Uri.parse('http://$gatewayIp:$port/api/messages/send');
      final body = jsonEncode({
        'message_id': message.id,
        'source_node': message.sourceNode,
        'destination_node': message.destinationNode,
        'content': message.content,
        'type': message.type.name,
        'timestamp': message.timestamp.millisecondsSinceEpoch ~/ 1000,
      });

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 202;
    } catch (_) {
      return false;
    }
  }

  /// Registers a node definition in the gateway routing table
  Future<bool> registerNode(MeshNode node) async {
    try {
      final uri = Uri.parse('http://$gatewayIp:$port/api/nodes/register');
      final body = jsonEncode({
        'node_id': node.id,
        'name': node.name,
        'type': node.typeString,
        'latitude': node.latitude,
        'longitude': node.longitude,
        'description': node.description,
      });

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 4));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Dispatches an emergency SOS broadcast to the gateway
  Future<bool> broadcastEmergency(EmergencyEvent event) async {
    try {
      final uri = Uri.parse('http://$gatewayIp:$port/api/emergency/sos');
      final body = jsonEncode({
        'alert_id': event.id,
        'emergency_type': event.emergencyType,
        'source_node': event.sourceNode,
        'latitude': event.latitude,
        'longitude': event.longitude,
        'severity': event.severity.name,
        'description': event.description,
        'timestamp': event.timestamp.millisecondsSinceEpoch ~/ 1000,
      });

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 4));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Shares a Geo-Tagged Note over the LoRa network
  Future<bool> shareNote(GeoNote note, {String? targetNodeId}) async {
    try {
      final uri = Uri.parse('http://$gatewayIp:$port/api/messages/send');
      final body = jsonEncode({
        'message_id': 'NOTE-${note.id}',
        'source_node': note.authorNodeId,
        'destination_node': targetNodeId ?? 'BROADCAST',
        'type': 'note_share',
        'content': jsonEncode({
          'note_id': note.id,
          'title': note.title,
          'description': note.description,
          'category': note.category.name,
          'priority': note.priority.name,
          'latitude': note.latitude,
          'longitude': note.longitude,
          'author': note.authorNodeId,
        }),
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200 || response.statusCode == 202;
    } catch (_) {
      return false;
    }
  }
}

