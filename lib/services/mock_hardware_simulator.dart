import 'dart:async';
import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../domain/entities/emergency_event.dart';
import '../domain/entities/message.dart';
import '../domain/entities/node.dart';
import '../features/shared/providers.dart';

class MockHardwareSimulator {
  final NodeListNotifier _nodeListNotifier;
  final MessageListNotifier _messageListNotifier;
  final EmergencyListNotifier _emergencyListNotifier;
  Timer? _simulationTimer;
  bool _isRunning = false;
  final math.Random _random = math.Random();

  MockHardwareSimulator({
    required NodeListNotifier nodeListNotifier,
    required MessageListNotifier messageListNotifier,
    required EmergencyListNotifier emergencyListNotifier,
  })  : _nodeListNotifier = nodeListNotifier,
        _messageListNotifier = messageListNotifier,
        _emergencyListNotifier = emergencyListNotifier;

  bool get isRunning => _isRunning;

  void start() {
    if (_isRunning) return;
    _isRunning = true;

    // Seed initial simulated mesh field nodes
    _seedInitialNodes();

    // Periodic simulation cycle every 7 seconds
    _simulationTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      _simulateMeshActivity();
    });
  }

  void stop() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _isRunning = false;
  }

  void _seedInitialNodes() {
    final nodes = [
      MeshNode(
        id: 'NODE-002',
        name: 'Relay Tower Hill',
        type: NodeType.relay,
        latitude: AppConstants.defaultLatitude + 0.0045,
        longitude: AppConstants.defaultLongitude + 0.0055,
        batteryPercentage: 96,
        batteryVoltage: 4.16,
        rssi: -72,
        snr: 10.4,
        hopCount: 1,
        isOnline: true,
        lastSeen: DateTime.now(),
        isVerified: true,
        description: 'Mountaintop solar relay station',
      ),
      MeshNode(
        id: 'NODE-003',
        name: 'Search Team Alpha',
        type: NodeType.client,
        latitude: AppConstants.defaultLatitude - 0.0032,
        longitude: AppConstants.defaultLongitude + 0.0028,
        batteryPercentage: 84,
        batteryVoltage: 3.98,
        rssi: -84,
        snr: 7.2,
        hopCount: 2,
        isOnline: true,
        lastSeen: DateTime.now(),
        isVerified: true,
        description: 'Ground search team',
      ),
      MeshNode(
        id: 'NODE-004',
        name: 'Medical Triage West',
        type: NodeType.medical,
        latitude: AppConstants.defaultLatitude - 0.0060,
        longitude: AppConstants.defaultLongitude - 0.0080,
        batteryPercentage: 91,
        batteryVoltage: 4.08,
        rssi: -88,
        snr: 6.5,
        hopCount: 2,
        isOnline: true,
        lastSeen: DateTime.now(),
        isVerified: true,
        description: 'Casualty stabilization post',
      ),
    ];

    for (final n in nodes) {
      _nodeListNotifier.addOrUpdateNode(n);
    }
  }

  void _simulateMeshActivity() {
    if (!_isRunning) return;

    final actionChoice = _random.nextInt(3);

    if (actionChoice == 0) {
      // 1. Simulate subtle GPS movement for ground team (Search Team Alpha)
      final deltaLat = (_random.nextDouble() - 0.5) * 0.0004;
      final deltaLon = (_random.nextDouble() - 0.5) * 0.0004;
      _nodeListNotifier.updateLocation(
        'NODE-003',
        AppConstants.defaultLatitude - 0.0032 + deltaLat,
        AppConstants.defaultLongitude + 0.0028 + deltaLon,
      );
    } else if (actionChoice == 1) {
      // 2. Simulate incoming LoRa radio message
      final sampleTexts = [
        'Sector 4 cleared. No trapped casualties located.',
        'Perimeter river levels rising. Moving to higher ground.',
        'Relay beacon ping OK. Signal margin steady at 9 dB.',
        'Medical supplies received from field drop.',
      ];

      final randomText = sampleTexts[_random.nextInt(sampleTexts.length)];
      final incoming = MeshMessage(
        id: const Uuid().v4(),
        sourceNode: _random.nextBool() ? 'NODE-003' : 'NODE-004',
        destinationNode: 'GATEWAY-01',
        content: randomText,
        timestamp: DateTime.now(),
        status: MessageStatus.delivered,
        rssi: -80 - _random.nextInt(15),
        snr: 6.0 + _random.nextDouble() * 4.0,
        hopCount: _random.nextInt(2) + 1,
      );

      _messageListNotifier.addMessage(incoming);
    } else {
      // 3. Update battery & RSSI telemetry
      _nodeListNotifier.updateTelemetry(
        id: 'NODE-002',
        battery: 95 - _random.nextInt(3),
        rssi: -72 + _random.nextInt(6),
        snr: 10.0 + _random.nextDouble() * 2.0,
        hopCount: 1,
        isOnline: true,
      );
    }
  }
}
