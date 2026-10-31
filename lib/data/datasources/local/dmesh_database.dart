import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DMeshDatabase {
  static final DMeshDatabase instance = DMeshDatabase._init();
  static Database? _database;

  DMeshDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dmesh_tactical.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Nodes Table
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

    // 2. Messages Table
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

    // 3. Geo-Tagged Notes Table
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

    // 4. Emergency Events Table
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

    // 5. Network Routes Table
    await db.execute('''
      CREATE TABLE network_routes (
        route_id TEXT PRIMARY KEY,
        source_node TEXT NOT NULL,
        destination_node TEXT NOT NULL,
        hops TEXT NOT NULL,
        total_hops INTEGER NOT NULL,
        avg_rssi REAL NOT NULL,
        avg_snr REAL NOT NULL,
        link_metrics TEXT,
        last_updated INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Indices for performance
    await db.execute('CREATE INDEX idx_messages_dest ON messages(destination_node);');
    await db.execute('CREATE INDEX idx_messages_timestamp ON messages(timestamp);');
    await db.execute('CREATE INDEX idx_notes_coords ON geo_notes(latitude, longitude);');
    await db.execute('CREATE INDEX idx_emergency_ts ON emergency_events(timestamp);');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Migration hooks for future versions
  }

  // --- CRUD HELPERS FOR NODES ---

  Future<int> insertOrUpdateNode(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(
      'nodes',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllNodes() async {
    final db = await database;
    return await db.query('nodes', orderBy: 'last_seen DESC');
  }

  Future<Map<String, dynamic>?> getNodeById(String id) async {
    final db = await database;
    final res = await db.query('nodes', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> deleteNode(String id) async {
    final db = await database;
    return await db.delete('nodes', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD HELPERS FOR MESSAGES ---

  Future<int> insertMessage(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(
      'messages',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getMessagesForConversation(String nodeA, String nodeB) async {
    final db = await database;
    return await db.query(
      'messages',
      where: '(source_node = ? AND destination_node = ?) OR (source_node = ? AND destination_node = ?) OR destination_node = ?',
      whereArgs: [nodeA, nodeB, nodeB, nodeA, 'BROADCAST'],
      orderBy: 'timestamp ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllMessages() async {
    final db = await database;
    return await db.query('messages', orderBy: 'timestamp DESC');
  }

  Future<int> updateMessageStatus(String id, String status) async {
    final db = await database;
    return await db.update(
      'messages',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD HELPERS FOR GEO NOTES ---

  Future<int> insertOrUpdateNote(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(
      'geo_notes',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllNotes() async {
    final db = await database;
    return await db.query('geo_notes', orderBy: 'created_at DESC');
  }

  Future<Map<String, dynamic>?> getNoteById(String id) async {
    final db = await database;
    final res = await db.query('geo_notes', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> deleteNote(String id) async {
    final db = await database;
    return await db.delete('geo_notes', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD HELPERS FOR EMERGENCY EVENTS ---

  Future<int> insertEmergencyEvent(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(
      'emergency_events',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllEmergencyEvents() async {
    final db = await database;
    return await db.query('emergency_events', orderBy: 'timestamp DESC');
  }

  Future<int> acknowledgeEmergency(String id, String ackBy) async {
    final db = await database;
    return await db.update(
      'emergency_events',
      {
        'is_acknowledged': 1,
        'acknowledged_by': ackBy,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD HELPERS FOR ROUTES ---

  Future<int> insertOrUpdateRoute(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(
      'network_routes',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllRoutes() async {
    final db = await database;
    return await db.query('network_routes', orderBy: 'last_updated DESC');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}

