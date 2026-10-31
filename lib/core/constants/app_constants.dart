class AppConstants {
  static const String appName = 'D-MESH';
  static const String appTagline = 'Decentralized Emergency Mesh Network';
  static const String appVersion = '1.0.0';

  // Networking Defaults
  static const String defaultGatewayIp = '192.168.4.1';
  static const int defaultGatewayHttpPort = 80;
  static const int defaultGatewayWsPort = 80;
  static const String defaultWsPath = '/ws';
  static const int discoveryUdpPort = 8266;
  static const int connectionTimeoutMs = 5000;
  static const int pingIntervalSeconds = 4;
  static const int maxReconnectAttempts = 5;

  // Local Gateway Identifier
  static const String localGatewayNodeId = 'GATEWAY-01';
  static const String broadcastAddress = 'BROADCAST';

  // Map Defaults (Disaster response staging region default)
  static const double defaultLatitude = 19.9975;
  static const double defaultLongitude = 73.7898;
  static const double defaultMapZoom = 14.0;
  static const double minMapZoom = 3.0;
  static const double maxMapZoom = 18.0;

  // Storage Keys
  static const String keyGatewayIp = 'dmesh_gateway_ip';
  static const String keyGatewayPort = 'dmesh_gateway_port';
  static const String keyNodeId = 'dmesh_local_node_id';
  static const String keyAesKey = 'dmesh_aes_encryption_key';
  static const String keyOfflineMapEnabled = 'dmesh_offline_map_enabled';
}
