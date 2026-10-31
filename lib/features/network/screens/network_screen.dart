import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/node.dart';
import '../../shared/providers.dart';

class NetworkScreen extends ConsumerStatefulWidget {
  const NetworkScreen({super.key});

  @override
  ConsumerState<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends ConsumerState<NetworkScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(nodeListProvider);
    final gateway = ref.watch(gatewayStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LORA MESH NETWORK'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.cyan,
          labelColor: AppColors.cyan,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.hub), text: 'NODES DIRECTORY'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'MESH TOPOLOGY & METRICS'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Register New Node',
            onPressed: () => _showAddNodeDialog(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: NODES DIRECTORY
          _buildNodesList(nodes),

          // TAB 2: TOPOLOGY & DIAGNOSTICS
          _buildTopologyAndDiagnostics(nodes, gateway),
        ],
      ),
    );
  }

  Widget _buildNodesList(List<MeshNode> nodes) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Gateway Card
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.surfaceLight,
              child: Icon(Icons.router, color: AppColors.cyan),
            ),
            title: const Text('GATEWAY-01 (LOCAL ESP32)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Wi-Fi Bridge • 433.175 MHz • SF9', style: TextStyle(fontSize: 12)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.greenOnline.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('HOST', style: TextStyle(color: AppColors.greenOnline, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        const Text('PEER LORA NODES',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 8),

        if (nodes.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text('No peer nodes registered yet.\nTap "+" to manually register or wait for radio discovery.',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
              ),
            ),
          )
        else
          ...nodes.map((node) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: node.isOnline ? AppColors.greenOnline.withOpacity(0.15) : AppColors.greyOffline.withOpacity(0.15),
                  child: Icon(
                    _getNodeIcon(node.type),
                    color: node.isOnline ? AppColors.greenOnline : AppColors.greyOffline,
                  ),
                ),
                title: Text(node.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  'ID: ${node.id} • Hops: ${node.hopCount} • RSSI: ${node.rssi} dBm • Bat: ${node.batteryPercentage}%',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textMuted),
                  onPressed: () => ref.read(nodeListProvider.notifier).removeNode(node.id),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildTopologyAndDiagnostics(List<MeshNode> nodes, GatewayState gateway) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MULTI-HOP COMMUNICATION ROUTE',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildRouteHop('GATEWAY-01', 'Host Gateway (Wi-Fi Bridge)', Icons.router, AppColors.cyan, isStart: true),
                  _buildHopConnector('Direct Sub-GHz LoRa (433.175 MHz) • -78 dBm • SNR 9.2 dB'),
                  _buildRouteHop('NODE-002', 'Tower Relay (Router)', Icons.cell_tower, AppColors.purpleRelay),
                  _buildHopConnector('Mesh Hop #2 • -86 dBm • SNR 6.5 dB'),
                  _buildRouteHop('NODE-004', 'Field Search Team Alpha', Icons.person_pin_circle, AppColors.greenOnline, isEnd: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text('HARDWARE TELEMETRY & LINK METRICS',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTelemetryBox('PACKET DELIVERY', '98.4%', 'LoRa ACK verification', AppColors.greenOnline),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTelemetryBox('AVG LATENCY', '142 ms', 'Per mesh hop', AppColors.cyan),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTelemetryBox('AVERAGE RSSI', '-82 dBm', 'Good signal floor', AppColors.cyan),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTelemetryBox('LORA DUTY CYCLE', '1.2%', 'Regulatory compliant', AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteHop(String id, String label, IconData icon, Color color, {bool isStart = false, bool isEnd = false}) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(id, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildHopConnector(String metric) {
    return Container(
      margin: const EdgeInsets.only(left: 15),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.surfaceBorder, width: 2)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Text(metric, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ),
    );
  }

  Widget _buildTelemetryBox(String label, String value, String desc, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(desc, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  IconData _getNodeIcon(NodeType type) {
    switch (type) {
      case NodeType.gateway:
        return Icons.router;
      case NodeType.relay:
        return Icons.cell_tower;
      case NodeType.medical:
        return Icons.local_hospital;
      case NodeType.command:
        return Icons.military_tech;
      default:
        return Icons.person_pin_circle;
    }
  }

  void _showAddNodeDialog(BuildContext context) {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final latController = TextEditingController(text: AppConstants.defaultLatitude.toString());
    final lonController = TextEditingController(text: AppConstants.defaultLongitude.toString());
    NodeType selectedType = NodeType.client;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('REGISTER LORA NODE'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: idController,
                      decoration: const InputDecoration(labelText: 'Node ID (e.g. NODE-004)'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Display Name (e.g. Search Alpha)'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<NodeType>(
                      value: selectedType,
                      dropdownColor: AppColors.surface,
                      decoration: const InputDecoration(labelText: 'Node Role'),
                      items: NodeType.values
                          .map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase())))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => selectedType = v);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: latController,
                            decoration: const InputDecoration(labelText: 'Latitude'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: lonController,
                            decoration: const InputDecoration(labelText: 'Longitude'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final id = idController.text.trim();
                    final name = nameController.text.trim();
                    final lat = double.tryParse(latController.text.trim());
                    final lon = double.tryParse(lonController.text.trim());

                    if (id.isEmpty || name.isEmpty) return;

                    final node = MeshNode(
                      id: id,
                      name: name,
                      type: selectedType,
                      latitude: lat,
                      longitude: lon,
                      isOnline: true,
                      lastSeen: DateTime.now(),
                      isVerified: true,
                    );

                    ref.read(nodeListProvider.notifier).addOrUpdateNode(node);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Register Node'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

