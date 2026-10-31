import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../shared/providers.dart';

class DashboardScreen extends ConsumerWidget {
  final Function(int)? onNavigateToTab;

  const DashboardScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gatewayState = ref.watch(gatewayStateProvider);
    final nodes = ref.watch(nodeListProvider);
    final notes = ref.watch(noteListProvider);
    final emergencies = ref.watch(emergencyListProvider);
    final messages = ref.watch(messageListProvider);

    final activeNodes = nodes.where((n) => n.isOnline).length;
    final criticalAlerts = emergencies.where((e) => !e.isAcknowledged).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gatewayState.isConnected
                    ? AppColors.greenOnline
                    : (gatewayState.status == GatewayConnectionStatus.connecting
                        ? AppColors.orangeWarning
                        : AppColors.greyOffline),
                boxShadow: gatewayState.isConnected
                    ? [
                        BoxShadow(
                          color: AppColors.greenOnline.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            const Text('D-MESH COMMAND'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'System Health & Battery',
            icon: const Icon(Icons.battery_charging_full, color: AppColors.greenOnline),
            onPressed: () {},
          ),
          IconButton(
            tooltip: 'Emergency SOS Broadcast',
            icon: const Icon(Icons.warning_amber_rounded, color: AppColors.redEmergency),
            onPressed: () => onNavigateToTab?.call(3), // Navigate to Emergency
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(nodeListProvider.notifier).loadNodes();
          ref.read(noteListProvider.notifier).loadNotes();
          ref.read(messageListProvider.notifier).loadMessages();
          ref.read(emergencyListProvider.notifier).loadEvents();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. GATEWAY HARDWARE STATUS BANNER ---
              _buildGatewayCard(context, ref, gatewayState),
              const SizedBox(height: 16),

              // --- 2. VITAL SYSTEM METRICS CARDS (2x2 GRID) ---
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'ACTIVE NODES',
                      value: '$activeNodes / ${nodes.length}',
                      subtitle: activeNodes > 0 ? 'LoRa mesh synced' : 'No peers detected',
                      icon: Icons.hub,
                      accentColor: AppColors.cyan,
                      onTap: () => onNavigateToTab?.call(4), // Network
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'PENDING ALERTS',
                      value: '$criticalAlerts',
                      subtitle: criticalAlerts > 0 ? 'Urgent attention' : 'All clear',
                      icon: Icons.emergency,
                      accentColor: criticalAlerts > 0 ? AppColors.redEmergency : AppColors.greenOnline,
                      onTap: () => onNavigateToTab?.call(3), // Emergency
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'GEO NOTES',
                      value: '${notes.length}',
                      subtitle: 'Tactical markers',
                      icon: Icons.location_on,
                      accentColor: AppColors.yellowNote,
                      onTap: () => onNavigateToTab?.call(2), // Map
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'MESSAGES',
                      value: '${messages.length}',
                      subtitle: 'LoRa radio logs',
                      icon: Icons.chat_bubble_outline,
                      accentColor: AppColors.blueAccent,
                      onTap: () => onNavigateToTab?.call(1), // Communication
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- 3. RAPID TACTICAL ACTIONS ---
              const Text(
                'TACTICAL QUICK ACTIONS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceLight,
                        foregroundColor: AppColors.cyan,
                        side: const BorderSide(color: AppColors.surfaceBorder),
                      ),
                      onPressed: () => onNavigateToTab?.call(2), // Open Live Map
                      icon: const Icon(Icons.add_location_alt, size: 18),
                      label: const Text('Add Note'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceLight,
                        foregroundColor: AppColors.cyan,
                        side: const BorderSide(color: AppColors.surfaceBorder),
                      ),
                      onPressed: () => onNavigateToTab?.call(1), // Compose message
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Send LoRa'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- 4. RECENT CRITICAL EVENTS OR RECENT LOGS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RECENT MESH ALERTS & EVENTS',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onNavigateToTab?.call(3),
                    child: const Text('View All', style: TextStyle(color: AppColors.cyan, fontSize: 12)),
                  ),
                ],
              ),
              if (emergencies.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.shield_outlined, size: 40, color: AppColors.greenOnline.withOpacity(0.7)),
                          const SizedBox(height: 8),
                          const Text(
                            'No active emergency alerts recorded',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const Text(
                            'Mesh monitoring frequency 433.175 MHz',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...emergencies.take(3).map((alert) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: alert.isAcknowledged
                              ? AppColors.surfaceLight
                              : AppColors.redEmergency.withOpacity(0.2),
                          child: Icon(
                            Icons.warning,
                            color: alert.isAcknowledged ? AppColors.greyOffline : AppColors.redEmergency,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          alert.emergencyType.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: alert.isAcknowledged ? AppColors.textPrimary : AppColors.redEmergency,
                          ),
                        ),
                        subtitle: Text(
                          'From: ${alert.sourceNode} • ${alert.description}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          alert.isAcknowledged ? 'ACK' : 'ACTIVE',
                          style: TextStyle(
                            color: alert.isAcknowledged ? AppColors.greenOnline : AppColors.redEmergency,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGatewayCard(BuildContext context, WidgetRef ref, GatewayState state) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: state.isConnected ? AppColors.cyan.withOpacity(0.4) : AppColors.surfaceBorder,
          ),
          gradient: AppColors.activeHeaderGradient,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.router, color: AppColors.cyan, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      state.deviceName ?? 'ESP32 GATEWAY BRIDGE',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: state.isConnected
                        ? AppColors.greenOnline.withOpacity(0.15)
                        : (state.status == GatewayConnectionStatus.connecting
                            ? AppColors.orangeWarning.withOpacity(0.15)
                            : AppColors.redEmergency.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: state.isConnected
                          ? AppColors.greenOnline
                          : (state.status == GatewayConnectionStatus.connecting
                              ? AppColors.orangeWarning
                              : AppColors.redEmergency),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    state.status.name.toUpperCase(),
                    style: TextStyle(
                      color: state.isConnected
                          ? AppColors.greenOnline
                          : (state.status == GatewayConnectionStatus.connecting
                              ? AppColors.orangeWarning
                              : AppColors.redEmergency),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(Icons.wifi, 'IP: ${state.ip}'),
                const SizedBox(width: 12),
                _buildInfoChip(
                  Icons.memory,
                  state.nodeId ?? 'GATEWAY-01',
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  Icons.radio,
                  '433.175 MHz',
                ),
              ],
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                'Connection notice: ${state.errorMessage}',
                style: const TextStyle(color: AppColors.orangeWarning, fontSize: 12),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: AppColors.cyan, width: 1),
                    ),
                    onPressed: () {
                      if (state.isConnected) {
                        ref.read(gatewayStateProvider.notifier).setDisconnected();
                      } else {
                        ref.read(gatewayStateProvider.notifier).setConnecting(state.ip, state.port);
                        // Mock connection trigger for initial testing
                        Future.delayed(const Duration(milliseconds: 600), () {
                          ref.read(gatewayStateProvider.notifier).setConnected(
                                deviceName: 'ESP32-GATEWAY-ALPHA',
                                nodeId: 'GATEWAY-01',
                                firmwareVersion: 'v1.0.0-lora',
                                battery: 94,
                                uptimeSeconds: 120,
                              );
                        });
                      }
                    },
                    child: Text(state.isConnected ? 'DISCONNECT' : 'TEST CONNECT'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Icon(icon, color: accentColor, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

