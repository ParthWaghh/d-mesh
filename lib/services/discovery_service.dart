import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

class DiscoveredDevice {
  final String ip;
  final int port;
  final String name;
  final String nodeId;
  final String macAddress;

  const DiscoveredDevice({
    required this.ip,
    required this.port,
    required this.name,
    required this.nodeId,
    required this.macAddress,
  });
}

class ESP32DiscoveryService {
  RawDatagramSocket? _udpSocket;
  final StreamController<DiscoveredDevice> _deviceController = StreamController<DiscoveredDevice>.broadcast();

  Stream<DiscoveredDevice> get onDeviceDiscovered => _deviceController.stream;

  /// Starts listening for UDP broadcast beacons from ESP32 gateways (Port 8266)
  Future<void> startUdpDiscovery() async {
    try {
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, AppConstants.discoveryUdpPort);
      _udpSocket?.broadcastEnabled = true;

      _udpSocket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _udpSocket?.receive();
          if (datagram != null) {
            try {
              final text = utf8.decode(datagram.data);
              final json = jsonDecode(text);
              if (json['service'] == 'dmesh' || json['service'] == 'dmesh_gateway') {
                final device = DiscoveredDevice(
                  ip: datagram.address.address,
                  port: (json['port'] as num?)?.toInt() ?? 80,
                  name: (json['name'] ?? 'ESP32 LoRa Gateway') as String,
                  nodeId: (json['id'] ?? json['node_id'] ?? 'GATEWAY-01') as String,
                  macAddress: (json['mac'] ?? '') as String,
                );
                _deviceController.add(device);
              }
            } catch (_) {}
          }
        }
      });
    } catch (_) {
      // If UDP bind fails, rely on active HTTP probing
    }
  }

  /// Active direct probe for the standard ESP32 SoftAP gateway address (192.168.4.1)
  Future<DiscoveredDevice?> probeDefaultGateway() async {
    try {
      final uri = Uri.parse('http://${AppConstants.defaultGatewayIp}:${AppConstants.defaultGatewayHttpPort}/api/device/info');
      final resp = await http.get(uri).timeout(const Duration(milliseconds: 1500));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final payload = data['data'] ?? data;
        final dev = DiscoveredDevice(
          ip: AppConstants.defaultGatewayIp,
          port: AppConstants.defaultGatewayHttpPort,
          name: payload['device_name'] ?? 'ESP32 Gateway',
          nodeId: payload['node_id'] ?? 'GATEWAY-01',
          macAddress: payload['mac_address'] ?? '',
        );
        _deviceController.add(dev);
        return dev;
      }
    } catch (_) {}
    return null;
  }

  void stop() {
    _udpSocket?.close();
    _udpSocket = null;
  }
}

