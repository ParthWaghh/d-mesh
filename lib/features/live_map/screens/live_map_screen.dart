import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../domain/entities/geo_note.dart';
import '../../../domain/entities/node.dart';
import '../../shared/providers.dart';
import '../services/offline_tile_manager.dart';

class LiveMapScreen extends ConsumerStatefulWidget {
  const LiveMapScreen({super.key});

  @override
  ConsumerState<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends ConsumerState<LiveMapScreen> {
  final MapController _mapController = MapController();
  final LatLng _currentCenter = const LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude);
  final double _currentZoom = AppConstants.defaultMapZoom;

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(nodeListProvider);
    final notes = ref.watch(noteListProvider);
    final gateway = ref.watch(gatewayStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TACTICAL LIVE MAP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Center on Gateway',
            onPressed: () {
              _mapController.move(
                const LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude),
                AppConstants.defaultMapZoom,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            tooltip: 'Map Layer Controls & Offline Cache',
            onPressed: () => _showLayerControls(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: _currentZoom,
              onLongPress: (tapPosition, point) {
                _showCreateNoteDialog(context, initialLocation: point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.dmesh.emergency.network',
              ),

              // Markers Layer
              MarkerLayer(
                markers: [
                  // Gateway Marker
                  Marker(
                    point: const LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude),
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () => _showGatewayInfo(context, gateway),
                      child: _buildMarkerIcon(
                        icon: Icons.router,
                        color: AppColors.cyan,
                        label: 'GW',
                      ),
                    ),
                  ),

                  // Node Markers
                  ...nodes.where((n) => n.hasValidLocation).map((node) {
                    final color = node.isOnline ? AppColors.greenOnline : AppColors.greyOffline;
                    return Marker(
                      point: LatLng(node.latitude!, node.longitude!),
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _showNodeDetails(context, node),
                        child: _buildMarkerIcon(
                          icon: _getNodeIcon(node.type),
                          color: color,
                          label: node.id.replaceAll('NODE-', 'N'),
                        ),
                      ),
                    );
                  }),

                  // Geo-Notes Markers
                  ...notes.map((note) {
                    return Marker(
                      point: LatLng(note.latitude, note.longitude),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => _showNoteDetails(context, note),
                        child: _buildMarkerIcon(
                          icon: _getCategoryIcon(note.category),
                          color: _getCategoryColor(note.category),
                          label: '',
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Map Control Buttons Overlay (Right Edge)
          Positioned(
            right: 16,
            bottom: 90,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.cyan,
                  onPressed: () {
                    final zoom = _mapController.camera.zoom + 1;
                    _mapController.move(_mapController.camera.center, zoom);
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.cyan,
                  onPressed: () {
                    final zoom = _mapController.camera.zoom - 1;
                    _mapController.move(_mapController.camera.center, zoom);
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // Map Legend / Compass Badge (Top Left)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.darkBackground.withOpacity(0.85),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.explore, color: AppColors.cyan, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${nodes.where((n) => n.isOnline).length} ACTIVE NODES',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.cyan,
        foregroundColor: AppColors.darkBackground,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('NEW NOTE', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showCreateNoteDialog(context),
      ),
    );
  }

  Widget _buildMarkerIcon({required IconData icon, required Color color, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 6,
                spreadRadius: 1,
              )
            ],
          ),
          child: Icon(icon, size: 18, color: AppColors.darkBackground),
        ),
        if (label.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              label,
              style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
      ],
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

  IconData _getCategoryIcon(NoteCategory category) {
    switch (category) {
      case NoteCategory.medical:
        return Icons.medical_services;
      case NoteCategory.rescue:
        return Icons.health_and_safety;
      case NoteCategory.fire:
        return Icons.local_fire_department;
      case NoteCategory.flood:
        return Icons.flood;
      case NoteCategory.earthquake:
        return Icons.landscape;
      case NoteCategory.hazard:
        return Icons.warning;
      case NoteCategory.accident:
        return Icons.car_crash;
      default:
        return Icons.note_alt;
    }
  }

  Color _getCategoryColor(NoteCategory category) {
    switch (category) {
      case NoteCategory.medical:
      case NoteCategory.emergency:
        return AppColors.redEmergency;
      case NoteCategory.fire:
      case NoteCategory.accident:
        return AppColors.orangeWarning;
      case NoteCategory.hazard:
      case NoteCategory.flood:
        return AppColors.yellowNote;
      default:
        return AppColors.blueAccent;
    }
  }

  void _showGatewayInfo(BuildContext context, GatewayState gateway) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.router, color: AppColors.cyan, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(gateway.deviceName ?? 'ESP32 GATEWAY', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('IP: ${gateway.ip} • Port: ${gateway.port}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                'Coordinates: ${GeoUtils.formatCoordinates(AppConstants.defaultLatitude, AppConstants.defaultLongitude)}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              const Text('Hardware: SX1278 433MHz + NEO-6M GPS + SSD1306 OLED', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                icon: const Icon(Icons.share_location),
                label: const Text('BROADCAST GATEWAY COORDINATES'),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Broadcasting gateway beacon via LoRa...')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNodeDetails(BuildContext context, MeshNode node) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(node.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('NODE ID: ${node.id} • TYPE: ${node.typeString.toUpperCase()}',
                          style: const TextStyle(color: AppColors.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: node.isOnline ? AppColors.greenOnline.withOpacity(0.2) : AppColors.greyOffline.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      node.isOnline ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        color: node.isOnline ? AppColors.greenOnline : AppColors.greyOffline,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('BATTERY', '${node.batteryPercentage}%', Icons.battery_charging_full),
                  _buildStatItem('RSSI', '${node.rssi} dBm', Icons.signal_cellular_alt),
                  _buildStatItem('SNR', '${node.snr} dB', Icons.graphic_eq),
                  _buildStatItem('HOPS', '${node.hopCount}', Icons.alt_route),
                ],
              ),
              const SizedBox(height: 16),
              if (node.hasValidLocation)
                Text(
                  'GPS: ${GeoUtils.formatCoordinates(node.latitude!, node.longitude!)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.chat),
                      label: const Text('Send Message'),
                      onPressed: () {
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Share Note'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showCreateNoteDialog(context, targetNodeId: node.id);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNoteDetails(BuildContext context, GeoNote note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getCategoryIcon(note.category), color: _getCategoryColor(note.category), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(note.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('CATEGORY: ${note.category.name.toUpperCase()} • PRIORITY: ${note.priority.name.toUpperCase()}',
                            style: TextStyle(color: _getCategoryColor(note.category), fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(note.description, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Text('Location: ${GeoUtils.formatCoordinates(note.latitude, note.longitude)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('Author: ${note.authorNodeId} • Status: ${note.syncStatus.name.toUpperCase()}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('BROADCAST VIA LORA'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref.read(noteListProvider.notifier).updateSyncStatus(note.id, NoteSyncStatus.sharing);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Dispatched note "${note.title}" over LoRa mesh...')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.redEmergency),
                    onPressed: () {
                      ref.read(noteListProvider.notifier).removeNote(note.id);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.cyan, size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }

  void _showCreateNoteDialog(BuildContext context, {LatLng? initialLocation, String? targetNodeId}) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final latController = TextEditingController(
      text: (initialLocation?.latitude ?? AppConstants.defaultLatitude).toStringAsFixed(5),
    );
    final lonController = TextEditingController(
      text: (initialLocation?.longitude ?? AppConstants.defaultLongitude).toStringAsFixed(5),
    );
    NoteCategory selectedCategory = NoteCategory.general;
    NotePriority selectedPriority = NotePriority.normal;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('ADD GEO-TAGGED NOTE'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title / Subject'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Incident Description'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<NoteCategory>(
                            value: selectedCategory,
                            dropdownColor: AppColors.surface,
                            decoration: const InputDecoration(labelText: 'Category'),
                            items: NoteCategory.values
                                .map((c) => DropdownMenuItem(value: c, child: Text(c.name.toUpperCase())))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setDialogState(() => selectedCategory = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<NotePriority>(
                            value: selectedPriority,
                            dropdownColor: AppColors.surface,
                            decoration: const InputDecoration(labelText: 'Priority'),
                            items: NotePriority.values
                                .map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase())))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setDialogState(() => selectedPriority = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: latController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Latitude'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: lonController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    final title = titleController.text.trim();
                    final desc = descController.text.trim();
                    final lat = double.tryParse(latController.text.trim()) ?? AppConstants.defaultLatitude;
                    final lon = double.tryParse(lonController.text.trim()) ?? AppConstants.defaultLongitude;

                    if (title.isEmpty) return;

                    final newNote = GeoNote(
                      id: const Uuid().v4(),
                      title: title,
                      description: desc,
                      category: selectedCategory,
                      priority: selectedPriority,
                      latitude: lat,
                      longitude: lon,
                      authorNodeId: 'GATEWAY-01',
                      createdAt: DateTime.now(),
                      syncStatus: NoteSyncStatus.local,
                      targetNodeId: targetNodeId,
                    );

                    ref.read(noteListProvider.notifier).addOrUpdateNote(newNote);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Note'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLayerControls(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MAP LAYERS & CACHING', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Offline Tile Cache'),
                subtitle: const Text('Store viewed OpenStreetMap tiles in local device memory'),
                value: true,
                onChanged: (val) {},
              ),
              SwitchListTile(
                title: const Text('Show LoRa RF Range Rings'),
                subtitle: const Text('Render 3km & 8km estimated RF propagation circles'),
                value: true,
                onChanged: (val) {},
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  backgroundColor: AppColors.surfaceLight,
                  foregroundColor: AppColors.cyan,
                  side: const BorderSide(color: AppColors.cyan),
                ),
                icon: const Icon(Icons.download_for_offline),
                label: const Text('PRE-CACHE DISASTER REGION TILES'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showPrecacheDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPrecacheDialog(BuildContext context) {
    int downloaded = 0;
    int total = 1;
    bool isDownloading = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('PRE-CACHE OFFLINE MAP TILES'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pre-download all OpenStreetMap tiles for the 10km disaster staging area surrounding the gateway (Zoom levels 12 to 14) for 100% offline navigation.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  if (isDownloading) ...[
                    LinearProgressIndicator(
                      value: total > 0 ? (downloaded / total) : 0,
                      backgroundColor: AppColors.charcoal,
                      color: AppColors.cyan,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cached $downloaded / $total tiles...',
                      style: const TextStyle(fontSize: 12, color: AppColors.cyan),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDownloading ? null : () => Navigator.pop(ctx),
                  child: const Text('Close', style: TextStyle(color: AppColors.textMuted)),
                ),
                if (!isDownloading)
                  ElevatedButton(
                    onPressed: () async {
                      setDialogState(() => isDownloading = true);

                      await OfflineTileManager.cacheDisasterRegion(
                        minLat: AppConstants.defaultLatitude - 0.05,
                        maxLat: AppConstants.defaultLatitude + 0.05,
                        minLon: AppConstants.defaultLongitude - 0.05,
                        maxLon: AppConstants.defaultLongitude + 0.05,
                        minZoom: 12,
                        maxZoom: 14,
                        onProgress: (dl, tot) {
                          setDialogState(() {
                            downloaded = dl;
                            total = tot;
                          });
                        },
                      );

                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.greenOnline,
                            content: Text('Successfully pre-cached $downloaded offline map tiles!'),
                          ),
                        );
                      }
                    },
                    child: const Text('Start Download'),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
