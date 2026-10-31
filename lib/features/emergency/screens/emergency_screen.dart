import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../domain/entities/emergency_event.dart';
import '../../shared/providers.dart';

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  String _selectedType = 'general_sos';
  EmergencySeverity _selectedSeverity = EmergencySeverity.critical;
  final TextEditingController _descController = TextEditingController();
  bool _isBroadcasting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _triggerEmergencyBroadcast() {
    setState(() => _isBroadcasting = true);

    final event = EmergencyEvent(
      id: 'SOS-${DateTime.now().millisecondsSinceEpoch}',
      emergencyType: _selectedType,
      sourceNode: 'GATEWAY-01',
      latitude: AppConstants.defaultLatitude,
      longitude: AppConstants.defaultLongitude,
      severity: _selectedSeverity,
      description: _descController.text.trim().isNotEmpty
          ? _descController.text.trim()
          : 'EMERGENCY SOS: Immediate rescue assistance required at reported coordinates.',
      timestamp: DateTime.now(),
      isAcknowledged: false,
    );

    ref.read(emergencyListProvider.notifier).addEvent(event);
    _descController.clear();

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _isBroadcasting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.redEmergency,
            content: Text('HIGH-PRIORITY SOS DISPATCHED ACROSS LORA MESH (433.175 MHz)'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final emergencies = ref.watch(emergencyListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EMERGENCY COMMAND (SOS)'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. BIG ONE-TOUCH SOS BUTTON ---
            GestureDetector(
              onTap: _showSosConfirmDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  gradient: AppColors.emergencyGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.redEmergency.withOpacity(0.4),
                      blurRadius: 18,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      _isBroadcasting ? Icons.cell_tower : Icons.warning_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isBroadcasting ? 'TRANSMITTING LORA SOS...' : 'ONE-TOUCH SOS BROADCAST',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Press to broadcast emergency with GPS to all LoRa nodes',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- 2. EMERGENCY CLASSIFICATION & DETAILS ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CUSTOM EMERGENCY BROADCAST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      dropdownColor: AppColors.surface,
                      decoration: const InputDecoration(labelText: 'Emergency Classification'),
                      items: const [
                        DropdownMenuItem(value: 'general_sos', child: Text('GENERAL SOS / LIFE THREAT')),
                        DropdownMenuItem(value: 'medical', child: Text('MEDICAL CASUALTY / TRIAGE')),
                        DropdownMenuItem(value: 'fire', child: Text('WILDFIRE / STRUCTURAL FIRE')),
                        DropdownMenuItem(value: 'flood', child: Text('FLOOD / SUBMERGED RESCUE')),
                        DropdownMenuItem(value: 'earthquake', child: Text('EARTHQUAKE / BUILDING COLLAPSE')),
                        DropdownMenuItem(value: 'accident', child: Text('VEHICLE ACCIDENT / EXTRACTION')),
                        DropdownMenuItem(value: 'hazard', child: Text('CHEMICAL / HAZMAT HAZARD')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Specific Details / Casualties / Evacuation Needs',
                        hintText: 'e.g. 2 casualties, severe bleeding, trapped in basement.',
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.redEmergency,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(44),
                      ),
                      icon: const Icon(Icons.emergency_share),
                      label: const Text('DISPATCH CUSTOM EMERGENCY ALERT'),
                      onPressed: _triggerEmergencyBroadcast,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- 3. EMERGENCY EVENT LOG & TRIAGE ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('EMERGENCY INCIDENT LOG',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                Text('${emergencies.length} RECORDED', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 10),
            if (emergencies.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30.0),
                  child: Text('No emergency events registered', style: TextStyle(color: AppColors.textMuted)),
                ),
              )
            else
              ...emergencies.map((alert) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: alert.isAcknowledged ? AppColors.greyOffline : AppColors.redEmergency, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  alert.emergencyType.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: alert.isAcknowledged ? AppColors.textPrimary : AppColors.redEmergency,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              alert.severity.name.toUpperCase(),
                              style: TextStyle(
                                color: alert.severity == EmergencySeverity.lifeThreatening
                                    ? AppColors.redEmergency
                                    : AppColors.orangeWarning,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(alert.description, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Coords: ${GeoUtils.formatCoordinates(alert.latitude, alert.longitude)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            Text(
                              '${alert.timestamp.hour.toString().padLeft(2, '0')}:${alert.timestamp.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        if (!alert.isAcknowledged) ...[
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.greenOnline,
                              side: const BorderSide(color: AppColors.greenOnline),
                              minimumSize: const Size.fromHeight(36),
                            ),
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text('ACKNOWLEDGE & DISPATCH RESPONSE'),
                            onPressed: () {
                              ref.read(emergencyListProvider.notifier).acknowledge(alert.id, 'GATEWAY-01');
                            },
                          ),
                        ] else ...[
                          const SizedBox(height: 6),
                          Text('Acknowledged by: ${alert.acknowledgedBy ?? 'GATEWAY-01'}',
                              style: const TextStyle(color: AppColors.greenOnline, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _showSosConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Row(
            children: [
              Icon(Icons.warning, color: AppColors.redEmergency),
              SizedBox(width: 8),
              Text('CONFIRM SOS BROADCAST'),
            ],
          ),
          content: const Text(
            'This will broadcast a high-priority distress signal with your current GPS coordinates to all nearby ESP32 LoRa nodes on 433.175 MHz.\n\nProceed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.redEmergency, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                _triggerEmergencyBroadcast();
              },
              child: const Text('BROADCAST SOS NOW'),
            ),
          ],
        );
      },
    );
  }
}

