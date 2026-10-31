import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DMeshDatabase - Schema & In-Memory Verification', () {
    late Database db;

    setUp(() async {
      db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            // Nodes Table
            await db.execute('''
              CREATE TABLE nodes (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                type TEXT NOT NULL,
                latitude REAL,
                longitude REAL,
                battery_percentage INTEGER NOT NULL DEFAULT 100,
                battery_voltage REAL NOT NULL DEFAULT 4.2,
                rssi INTEGER NOT NULL DEFAULT -80,
                snr REAL NOT NULL DEFAULT 8.0,
                hop_count INTEGER NOT NULL DEFAULT 0,
                is_online INTEGER NOT NULL DEFAULT 0,
                last_seen INTEGER NOT NULL,
                is_verified INTEGER NOT NULL DEFAULT 0,
                description TEXT
              )
            ''');

            // Messages Table
            await db.execute('''
              CREATE TABLE messages (
                id TEXT PRIMARY KEY,
                source_node TEXT NOT NULL,
                destination_node TEXT NOT NULL,
                content TEXT NOT NULL,
                timestamp INTEGER NOT NULL,
                type TEXT NOT NULL,
                status TEXT NOT NULL,
                rssi INTEGER,
                snr REAL,
                hop_count INTEGER NOT NULL DEFAULT 0,
                is_encrypted INTEGER NOT NULL DEFAULT 0,
                relay_nodes TEXT
              )
            ''');

            // Geo Notes Table
            await db.execute('''
              CREATE TABLE geo_notes (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                description TEXT NOT NULL,
                category TEXT NOT NULL,
                priority TEXT NOT NULL,
                latitude REAL NOT NULL,
                longitude REAL NOT NULL,
                author_node_id TEXT NOT NULL,
                created_at INTEGER NOT NULL,
                sync_status TEXT NOT NULL,
                target_node_id TEXT
              )
            ''');

            // Emergency Events Table
            await db.execute('''
              CREATE TABLE emergency_events (
                id TEXT PRIMARY KEY,
                emergency_type TEXT NOT NULL,
                source_node TEXT NOT NULL,
                latitude REAL NOT NULL,
                longitude REAL NOT NULL,
                severity TEXT NOT NULL,
                description TEXT NOT NULL,
                timestamp INTEGER NOT NULL,
                is_acknowledged INTEGER NOT NULL DEFAULT 0,
                acknowledged_by TEXT,
                rssi INTEGER,
                snr REAL
              )
            ''');
          },
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('should insert and query node records correctly', () async {
      await db.insert('nodes', {
        'id': 'NODE-001',
        'name': 'Alpha Search Lead',
        'type': 'client',
        'latitude': 19.9975,
        'longitude': 73.7898,
        'battery_percentage': 92,
        'battery_voltage': 4.1,
        'rssi': -78,
        'snr': 9.2,
        'hop_count': 1,
        'is_online': 1,
        'last_seen': DateTime.now().millisecondsSinceEpoch,
        'is_verified': 1,
        'description': 'Mobile field team',
      });

      final rows = await db.query('nodes', where: 'id = ?', whereArgs: ['NODE-001']);
      expect(rows, isNotEmpty);
      expect(rows.first['name'], equals('Alpha Search Lead'));
      expect(rows.first['is_online'], equals(1));
    });

    test('should insert and query geo_notes records correctly', () async {
      await db.insert('geo_notes', {
        'id': 'NOTE-001',
        'title': 'Bridge Washed Out',
        'description': 'Vehicle passage impossible at Sector 3',
        'category': 'hazard',
        'priority': 'critical',
        'latitude': 20.0010,
        'longitude': 73.7920,
        'author_node_id': 'NODE-002',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'sync_status': 'local',
      });

      final rows = await db.query('geo_notes');
      expect(rows.length, equals(1));
      expect(rows.first['category'], equals('hazard'));
      expect(rows.first['priority'], equals('critical'));
    });

    test('should insert and query emergency events with acknowledge update', () async {
      await db.insert('emergency_events', {
        'id': 'SOS-001',
        'emergency_type': 'medical',
        'source_node': 'NODE-004',
        'latitude': 19.9930,
        'longitude': 73.7850,
        'severity': 'life_threatening',
        'description': 'Severe casualty requiring air extraction',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'is_acknowledged': 0,
      });

      // Acknowledge alert
      await db.update(
        'emergency_events',
        {'is_acknowledged': 1, 'acknowledged_by': 'GATEWAY-01'},
        where: 'id = ?',
        whereArgs: ['SOS-001'],
      );

      final rows = await db.query('emergency_events', where: 'id = ?', whereArgs: ['SOS-001']);
      expect(rows.first['is_acknowledged'], equals(1));
      expect(rows.first['acknowledged_by'], equals('GATEWAY-01'));
    });
  });
}
