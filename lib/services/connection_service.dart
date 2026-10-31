import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../features/shared/providers.dart';

class ConnectionService {
  final GatewayNotifier _gatewayNotifier;
  Timer? _healthCheckTimer;
  bool _isDisposed = false;
  int _reconnectAttempts = 0;

  ConnectionService(this._gatewayNotifier);

  /// Test connectivity and fetch device info via REST GET /api/device/info
  Future<bool> connect(String ip, int port) async {
    _gatewayNotifier.setConnecting(ip, port);
    _reconnectAttempts = 0;

    try {
      final uri = Uri.parse('http://$ip:$port/api/device/info');
      final response = await http.get(uri).timeout(
        const Duration(milliseconds: AppConstants.connectionTimeoutMs),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final payload = data['data'] ?? data;

        _gatewayNotifier.setConnected(
          deviceName: payload['device_name'] ?? 'ESP32-GATEWAY-LORA',
          nodeId: payload['node_id'] ?? 'GATEWAY-01',
          firmwareVersion: payload['firmware_version'] ?? '1.0.0',
          battery: payload['battery_percentage'] ?? 100,
          uptimeSeconds: payload['uptime_seconds'] ?? 0,
        );

        _startHealthMonitoring(ip, port);
        return true;
      } else {
        _gatewayNotifier.setError('Gateway returned HTTP ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _gatewayNotifier.setError('Failed to connect to ESP32: $e');
      return false;
    }
  }

  void disconnect() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _gatewayNotifier.setDisconnected();
  }

  void _startHealthMonitoring(String ip, int port) {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(
      const Duration(seconds: AppConstants.pingIntervalSeconds),
      (_) => _checkHealth(ip, port),
    );
  }

  Future<void> _checkHealth(String ip, int port) async {
    if (_isDisposed) return;
    try {
      final uri = Uri.parse('http://$ip:$port/api/gateway/status');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 3),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _reconnectAttempts = 0;
        _gatewayNotifier.updateHeartbeat(
          battery: data['battery_percentage'],
          uptimeSeconds: data['uptime_seconds'],
        );
      } else {
        _handleMissedHeartbeat(ip, port);
      }
    } catch (_) {
      _handleMissedHeartbeat(ip, port);
    }
  }

  void _handleMissedHeartbeat(String ip, int port) {
    _reconnectAttempts++;
    if (_reconnectAttempts > AppConstants.maxReconnectAttempts) {
      _gatewayNotifier.setError('Gateway heartbeat lost. Reconnecting...');
      _gatewayNotifier.setReconnecting();
      // Try to re-establish
      connect(ip, port);
    }
  }

  void dispose() {
    _isDisposed = true;
    _healthCheckTimer?.cancel();
  }
}

