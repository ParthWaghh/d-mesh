class MeshLinkMetric {
  final String fromNode;
  final String toNode;
  final int rssi;
  final double snr;
  final bool isFailed;

  const MeshLinkMetric({
    required this.fromNode,
    required this.toNode,
    required this.rssi,
    required this.snr,
    this.isFailed = false,
  });
}

class MeshRoute {
  final String routeId;
  final String sourceNode;
  final String destinationNode;
  final List<String> hops;
  final int totalHops;
  final double avgRssi;
  final double avgSnr;
  final List<MeshLinkMetric> linkMetrics;
  final DateTime lastUpdated;
  final bool isActive;

  const MeshRoute({
    required this.routeId,
    required this.sourceNode,
    required this.destinationNode,
    required this.hops,
    required this.totalHops,
    required this.avgRssi,
    required this.avgSnr,
    this.linkMetrics = const [],
    required this.lastUpdated,
    this.isActive = true,
  });

  MeshRoute copyWith({
    String? routeId,
    String? sourceNode,
    String? destinationNode,
    List<String>? hops,
    int? totalHops,
    double? avgRssi,
    double? avgSnr,
    List<MeshLinkMetric>? linkMetrics,
    DateTime? lastUpdated,
    bool? isActive,
  }) {
    return MeshRoute(
      routeId: routeId ?? this.routeId,
      sourceNode: sourceNode ?? this.sourceNode,
      destinationNode: destinationNode ?? this.destinationNode,
      hops: hops ?? this.hops,
      totalHops: totalHops ?? this.totalHops,
      avgRssi: avgRssi ?? this.avgRssi,
      avgSnr: avgSnr ?? this.avgSnr,
      linkMetrics: linkMetrics ?? this.linkMetrics,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
    );
  }
}

