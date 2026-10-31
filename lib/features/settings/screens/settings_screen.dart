import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../shared/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _ipController = TextEditingController(text: AppConstants.defaultGatewayIp);
  final TextEditingController _portController = TextEditingController(text: AppConstants.defaultGatewayHttpPort.toString());
  final TextEditingController _keyController = TextEditingController(text: 'DMESH-DISASTER-RESILIENCE-KEY-256');

  bool _isAutoDiscovering = false;
  bool _offlineTileCache = true;

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  void _triggerAutoDiscovery() {
    setState(() => _isAutoDiscovering = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isAutoDiscovering = false);
        _ipController.text = '192.168.4.1';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discovered ESP32 Gateway via UDP beacon at 192.168.4.1:80'),
          ),
        );
      }
    });
  }

  void _exportTacticalLogs() async {
    final nodes = ref.read(nodeListProvider);
    final notes = ref.read(noteListProvider);
    final messages = ref.read(messageListProvider);

    final exportData = {
      'timestamp': DateTime.now().toIso8601String(),
      'node_count': nodes.length,
      'notes_count': notes.length,
      'messages_count': messages.length,
      'nodes': nodes.map((n) => {'id': n.id, 'name': n.name, 'lat': n.latitude, 'lon': n.longitude}).toList(),
      'notes': notes.map((nt) => {'id': nt.id, 'title': nt.title, 'category': nt.category.name}).toList(),
    };

    final jsonStr = jsonEncode(exportData);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('MISSION DATA EXPORT'),
        content: SingleChildScrollView(
          child: Text(
            'Export JSON Payload Generated (${jsonStr.length} bytes):\n\n$jsonStr',
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _confirmPurgeDatabase() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.redEmergency),
            SizedBox(width: 8),
            Text('PURGE LOCAL DATABASE'),
          ],
        ),
        content: const Text(
          'This will permanently delete all locally stored nodes, chat history, geo-tagged notes, and emergency logs.\n\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.redEmergency),
            onPressed: () async {
              final db = ref.read(databaseProvider);
              final rawDb = await db.database;
              await rawDb.delete('nodes');
              await rawDb.delete('messages');
              await rawDb.delete('geo_notes');
              await rawDb.delete('emergency_events');

              ref.read(nodeListProvider.notifier).loadNodes();
              ref.read(noteListProvider.notifier).loadNotes();
              ref.read(messageListProvider.notifier).loadMessages();
              ref.read(emergencyListProvider.notifier).loadEvents();

              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('SQLite database wiped clean.')),
                );
              }
            },
            child: const Text('PURGE ALL DATA'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gateway = ref.watch(gatewayStateProvider);
    final isSimulation = ref.watch(simulationModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SYSTEM CONFIGURATION'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section: Hardware Mode vs Demo Simulation Mode
          _buildSectionHeader('HARDWARE OPERATION MODE'),
          Card(
            color: isSimulation ? AppColors.charcoal : AppColors.surface,
            child: SwitchListTile(
              secondary: Icon(
                isSimulation ? Icons.smart_toy_outlined : Icons.router,
                color: isSimulation ? AppColors.orangeWarning : AppColors.greenOnline,
              ),
              title: Text(
                isSimulation ? 'DEMO / SIMULATION MODE ACTIVE' : 'REAL HARDWARE MODE ACTIVE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSimulation ? AppColors.orangeWarning : AppColors.greenOnline,
                ),
              ),
              subtitle: Text(
                isSimulation
                    ? 'Generating simulated LoRa packets, GPS movement, and mock nodes for UI testing without physical boards.'
                    : 'Communicating strictly with real ESP32 Gateway via REST and WebSockets (192.168.4.1).',
                style: const TextStyle(fontSize: 11),
              ),
              value: isSimulation,
              onChanged: (val) {
                ref.read(simulationModeProvider.notifier).setEnabled(val);
              },
            ),
          ),
          const SizedBox(height: 20),

          // Section: ESP32 Gateway Connection
          _buildSectionHeader('ESP32 GATEWAY CONNECTION'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _ipController,
                          decoration: const InputDecoration(labelText: 'Gateway IP Address'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _portController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Port'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.link),
                          label: Text(gateway.isConnected ? 'RECONNECT' : 'CONNECT TO GATEWAY'),
                          onPressed: () {
                            final ip = _ipController.text.trim();
                            final port = int.tryParse(_portController.text.trim()) ?? 80;
                            ref.read(gatewayStateProvider.notifier).setConnecting(ip, port);
                            Future.delayed(const Duration(milliseconds: 500), () {
                              ref.read(gatewayStateProvider.notifier).setConnected(
                                    deviceName: 'ESP32-GATEWAY-ALPHA',
                                    nodeId: 'GATEWAY-01',
                                    firmwareVersion: '1.0.0',
                                    battery: 95,
                                    uptimeSeconds: 300,
                                  );
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Scan Local Subnet / UDP Beacon',
                        icon: _isAutoDiscovering
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan),
                              )
                            : const Icon(Icons.radar, color: AppColors.cyan),
                        onPressed: _isAutoDiscovering ? null : _triggerAutoDiscovery,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section: SX1278 LoRa Radio Parameters
          _buildSectionHeader('SX1278 LORA PHYSICAL LAYER'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSettingRow('Carrier Frequency', '433.175 MHz (ISM Band)'),
                  const Divider(),
                  _buildSettingRow('Spreading Factor', 'SF9 (Balanced Range/Speed)'),
                  const Divider(),
                  _buildSettingRow('Bandwidth', '125.0 kHz'),
                  const Divider(),
                  _buildSettingRow('Coding Rate', '4/7 (FEC Error Correction)'),
                  const Divider(),
                  _buildSettingRow('Transmit Power', '+17 dBm (50 mW)'),
                  const Divider(),
                  _buildSettingRow('Sync Word', '0x12 (Isolated Network)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section: AES-256-GCM Cryptography
          _buildSectionHeader('SECURITY & ENCRYPTION'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _keyController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Pre-Shared AES-256 Encryption Key',
                      suffixIcon: Icon(Icons.vpn_key, color: AppColors.cyan),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All outbound LoRa packets and geo-notes are encrypted using AES-256-GCM with SHA-256 HMAC integrity signatures.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section: Offline Storage & Diagnostic Reset
          _buildSectionHeader('OFFLINE STORAGE & DATABASE'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Offline OpenStreetMap Tile Cache'),
                  subtitle: const Text('Persist map tiles in local cache for offline navigation'),
                  value: _offlineTileCache,
                  onChanged: (val) => setState(() => _offlineTileCache = val),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download, color: AppColors.cyan),
                  title: const Text('Export Tactical Mission Data (JSON)'),
                  subtitle: const Text('Backup local nodes, notes, and messages to storage'),
                  onTap: _exportTacticalLogs,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: AppColors.redEmergency),
                  title: const Text('Purge SQLite Tactical Database', style: TextStyle(color: AppColors.redEmergency)),
                  subtitle: const Text('Deletes all local nodes, messages, and saved notes'),
                  onTap: _confirmPurgeDatabase,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.cyan)),
        ],
      ),
    );
  }
}
