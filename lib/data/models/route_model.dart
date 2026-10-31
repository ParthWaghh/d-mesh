import 'dart:convert';
import '../../domain/entities/mesh_route.dart';

class RouteModel extends MeshRoute {
  const RouteModel({
    required super.routeId,
    required super.sourceNode,
    required super.destinationNode,
    required super.hops,
    required super.totalHops,
    required super.avgRssi,
    required super.avgSnr,
    super.linkMetrics,
    required super.lastUpdated,
    super.isActive,
  });

  factory RouteModel.fromEntity(MeshRoute entity) {
    return RouteModel(
      routeId: entity.routeId,
      sourceNode: entity.sourceNode,
      destinationNode: entity.destinationNode,
      hops: entity.hops,
      totalHops: entity.totalHops,
      avgRssi: entity.avgRssi,
      avgSnr: entity.avgSnr,
      linkMetrics: entity.linkMetrics,
      lastUpdated: entity.lastUpdated,
      isActive: entity.isActive,
    );
  }

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    List<String> hopList = [];
    if (map['hops'] != null) {
      try {
        final decoded = jsonDecode(map['hops'].toString());
        if (decoded is List) {
          hopList = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    List<MeshLinkMetric> metrics = [];
    if (map['link_metrics'] != null) {
      try {
        final decoded = jsonDecode(map['link_metrics'].toString());
        if (decoded is List) {
          metrics = decoded.map((m) {
            return MeshLinkMetric(
              fromNode: m['from'] ?? '',
              toNode: m['to'] ?? '',
              rssi: (m['rssi'] as num?)?.toInt() ?? -80,
              snr: (m['snr'] as num?)?.toDouble() ?? 8.0,
              isFailed: m['failed'] == true,
            );
          }).toList();
        }
      } catch (_) {}
    }

    return RouteModel(
      routeId: map['route_id'] as String,
      sourceNode: map['source_node'] as String,
      destinationNode: map['destination_node'] as String,
      hops: hopList,
      totalHops: (map['total_hops'] as num).toInt(),
      avgRssi: (map['avg_rssi'] as num).toDouble(),
      avgSnr: (map['avg_snr'] as num).toDouble(),
      linkMetrics: metrics,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch((map['last_updated'] as num).toInt()),
      isActive: (map['is_active'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    final metricsJson = linkMetrics.map((m) => {
      'from': m.fromNode,
      'to': m.toNode,
      'rssi': m.rssi,
      'snr': m.snr,
      'failed': m.isFailed,
    }).toList();

    return {
      'route_id': routeId,
      'source_node': sourceNode,
      'destination_node': destinationNode,
      'hops': jsonEncode(hops),
      'total_hops': totalHops,
      'avg_rssi': avgRssi,
      'avg_snr': avgSnr,
      'link_metrics': jsonEncode(metricsJson),
      'last_updated': lastUpdated.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    List<String> hopList = [];
    if (json['path'] is List) {
      hopList = (json['path'] as List).map((e) => e.toString()).toList();
    } else if (json['hops'] is List) {
      hopList = (json['hops'] as List).map((e) => e.toString()).toList();
    }

    List<MeshLinkMetric> metrics = [];
    if (json['link_metrics'] is List) {
      metrics = (json['link_metrics'] as List).map((m) {
        return MeshLinkMetric(
          fromNode: m['from'] ?? '',
          toNode: m['to'] ?? '',
          rssi: (m['rssi'] as num?)?.toInt() ?? -80,
          snr: (m['snr'] as num?)?.toDouble() ?? 8.0,
          isFailed: m['failed'] == true,
        );
      }).toList();
    }

    return RouteModel(
      routeId: (json['route_id'] ?? '${json['source_node']}_${json['destination_node']}') as String,
      sourceNode: (json['source_node'] ?? 'GATEWAY-01') as String,
      destinationNode: (json['destination_node'] ?? '') as String,
      hops: hopList,
      totalHops: (json['total_hops'] as num?)?.toInt() ?? hopList.length,
      avgRssi: (json['avg_rssi'] as num?)?.toDouble() ?? -80.0,
      avgSnr: (json['avg_snr'] as num?)?.toDouble() ?? 8.0,
      linkMetrics: metrics,
      lastUpdated: DateTime.now(),
      isActive: json['is_active'] != false,
    );
  }
}

