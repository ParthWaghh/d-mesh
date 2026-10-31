import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../data/models/emergency_event_model.dart';
import '../data/models/geo_note_model.dart';
import '../data/models/message_model.dart';
import '../data/models/node_model.dart';
import '../data/models/route_model.dart';
import '../features/shared/providers.dart';

class WebSocketService {
  final NodeListNotifier _nodeListNotifier;
  final MessageListNotifier _messageListNotifier;
  final NoteListNotifier _noteListNotifier;
  final EmergencyListNotifier _emergencyListNotifier;
  final RouteListNotifier _routeListNotifier;
  final GatewayNotifier _gatewayNotifier;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  String? _currentIp;
  int? _currentPort;

  WebSocketService({
    required NodeListNotifier nodeListNotifier,
    required MessageListNotifier messageListNotifier,
    required NoteListNotifier noteListNotifier,
    required EmergencyListNotifier emergencyListNotifier,
    required RouteListNotifier routeListNotifier,
    required GatewayNotifier gatewayNotifier,
  })  : _nodeListNotifier = nodeListNotifier,
        _messageListNotifier = messageListNotifier,
        _noteListNotifier = noteListNotifier,
        _emergencyListNotifier = emergencyListNotifier,
        _routeListNotifier = routeListNotifier,
        _gatewayNotifier = gatewayNotifier;

  bool get isConnected => _isConnected;

  void connect(String ip, int port) {
    _currentIp = ip;
    _currentPort = port;
    _reconnectTimer?.cancel();

    try {
      final wsUrl = Uri.parse('ws://$ip:$port/ws');
      _channel = WebSocketChannel.connect(wsUrl);

      _subscription = _channel?.stream.listen(
        (data) => _handleIncomingMessage(data),
        onDone: () => _handleDisconnect(),
        onError: (err) => _handleDisconnect(error: err.toString()),
      );

      _isConnected = true;
    } catch (e) {
      _handleDisconnect(error: e.toString());
    }
  }

  void _handleIncomingMessage(dynamic rawData) {
    try {
      final decoded = jsonDecode(rawData.toString());
      if (decoded is! Map<String, dynamic>) return;

      final event = decoded['event'] as String?;
      final data = decoded['data'] as Map<String, dynamic>? ?? decoded;

      switch (event) {
        case 'message_received':
          final msg = MessageModel.fromJson(data);
          _messageListNotifier.addMessage(msg);
          break;

        case 'message_ack':
          final msgId = (data['message_id'] ?? data['id'])?.toString();
          if (msgId != null) {
            _messageListNotifier.markDelivered(msgId);
          }
          break;

        case 'node_discovered':
        case 'node_status_changed':
          final node = NodeModel.fromJson(data);
          _nodeListNotifier.addOrUpdateNode(node);
          break;

        case 'node_location_updated':
          final nodeId = (data['node_id'] ?? data['id'])?.toString();
          final lat = (data['latitude'] as num?)?.toDouble();
          final lon = (data['longitude'] as num?)?.toDouble();
          if (nodeId != null && lat != null && lon != null) {
            _nodeListNotifier.updateLocation(nodeId, lat, lon);
          }
          break;

        case 'note_received':
          final note = GeoNoteModel.fromJson(data);
          _noteListNotifier.addOrUpdateNote(note);
          break;

        case 'emergency_received':
          final alert = EmergencyEventModel.fromJson(data);
          _emergencyListNotifier.addEvent(alert);
          break;

        case 'route_updated':
          final route = RouteModel.fromJson(data);
          _routeListNotifier.setRoutes([route]);
          break;

        case 'telemetry_updated':
          _gatewayNotifier.updateHeartbeat(
            battery: (data['battery'] as num?)?.toInt(),
            uptimeSeconds: (data['uptime'] as num?)?.toInt(),
          );
          break;
      }
    } catch (_) {}
  }

  void _handleDisconnect({String? error}) {
    _isConnected = false;
    _subscription?.cancel();
    _subscription = null;
    _channel = null;

    if (_currentIp != null && _currentPort != null) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 4), () {
        connect(_currentIp!, _currentPort!);
      });
    }
  }

  void send(Map<String, dynamic> payload) {
    if (_isConnected && _channel != null) {
      _channel?.sink.add(jsonEncode(payload));
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _currentIp = null;
    _currentPort = null;
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
  }
}

