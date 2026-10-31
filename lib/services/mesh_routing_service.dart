import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../data/models/route_model.dart';
import '../domain/entities/mesh_route.dart';

class MeshRoutingService {
  final String gatewayIp;
  final int port;

  MeshRoutingService({
    this.gatewayIp = AppConstants.defaultGatewayIp,
    this.port = AppConstants.defaultGatewayHttpPort,
  });

  /// Fetches active routing topology table from ESP32 gateway
  Future<List<MeshRoute>> fetchRoutes() async {
    try {
      final uri = Uri.parse('http://$gatewayIp:$port/api/network/routes');
      final resp = await http.get(uri).timeout(const Duration(seconds: 4));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final list = data['data'] ?? data;
        if (list is List) {
          return list.map((item) => RouteModel.fromJson(item)).toList();
        }
      }
    } catch (_) {}

    return [];
  }
}

