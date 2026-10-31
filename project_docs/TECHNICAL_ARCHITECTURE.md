# D-MESH: Technical Architecture & System Design

### 1. High-Level Architectural Diagram

```
+-----------------------------------------------------------------------+
|                    D-MESH MOBILE APPLICATION (FLUTTER)                |
|                                                                       |
|  [Presentation Layer - Material 3 Tactical Dark Command Center]      |
|  - Dashboard | Messages | Live Map | Emergency | Network | Settings  |
|                                                                       |
|  [State Management - Riverpod StateNotifiers & Controllers]          |
|  - ConnectionState | NodeRegistry | MapState | ChatState | AlertState |
|                                                                       |
|  [Domain Layer - Clean Architecture Entities & Use Cases]            |
|  - Node, Message, GeoNote, EmergencyAlert, MeshRoute, LinkMetric      |
|                                                                       |
|  [Data & Service Layer]                                               |
|  - SQLite Database (sqflite)           - Hardware Connection Service  |
|  - Offline Tile Store (flutter_map)    - WebSocket Real-time Client   |
|  - Local Storage Repository            - ESP32 REST API Client        |
+-----------------------------------------------------------------------+
                                  |
                                  | Wi-Fi 802.11 b/g/n
                                  | (REST on HTTP 80 / WebSockets on WS 80)
                                  v
+-----------------------------------------------------------------------+
|                       ESP32 GATEWAY NODE                              |
|                                                                       |
|  - Dual Core ESP32 MCU (240MHz)                                       |
|  - Wi-Fi SoftAP / Station Server (ESPAsyncWebServer)                  |
|  - Real-Time WebSocket Server (Broadcast & Inbound Telemetry)         |
|  - NEO-6M GNSS NMEA Parser (Hardware Serial2: GPIO 16/17)             |
|  - SSD1306 OLED I2C Status Display Driver (GPIO 21/22)                |
|  - Semtech SX1278 LoRa SPI Transceiver Driver (GPIO 18,19,23,5,14,2)  |
|  - Mesh Routing Controller & In-Memory Packet Buffer                  |
+-----------------------------------------------------------------------+
                                  |
                                  | Sub-GHz LoRa RF (433.0 - 434.79 MHz)
                                  | Spreading Factor: SF7-SF12, BW: 125kHz
                                  v
+-----------------------------------------------------------------------+
|                         LORA MESH NETWORK                             |
|                                                                       |
|    +-------------------+                 +-------------------+        |
|    |  ESP32 Node #02   |<===============>|  ESP32 Node #03   |        |
|    |  (Relay / Router) |                 |  (Search Team)    |        |
|    +-------------------+                 +-------------------+        |
|              ^                                     ^                  |
|              |                                     |                  |
|              v                                     v                  |
|    +-------------------+                 +-------------------+        |
|    |  ESP32 Node #04   |<===============>|  ESP32 Node #05   |        |
|    |  (Medical Unit)   |                 |  (Field Station)  |        |
|    +-------------------+                 +-------------------+        |
+-----------------------------------------------------------------------+
```

---

### 2. Software Architecture (Flutter Clean Architecture)

The Flutter mobile application is organized into layered directories adhering to Clean Architecture principles:

```
lib/
├── core/
│   ├── constants/       # App constants, LoRa limits, map defaults
│   ├── errors/          # Custom exceptions & failure definitions
│   ├── network/         # HTTP client & WebSocket connection engine
│   ├── security/        # AES-256-GCM encryption & HMAC signers
│   ├── theme/           # Tactical dark-mode palette and typography
│   └── utils/           # Coordinate converters, distance math, formatters
├── data/
│   ├── datasources/
│   │   ├── local/       # SQLite db helper, tile cache, shared prefs
│   │   └── remote/      # ESP32 REST client, WebSocket client
│   ├── models/          # DTOs with JSON serialization (Node, Message, Note)
│   └── repositories/    # Implementation of domain repositories
├── domain/
│   ├── entities/        # Immutable domain models (Node, Message, GeoNote)
│   ├── repositories/    # Abstract interfaces for data access
│   └── usecases/        # Specific business logic interactors
├── features/
│   ├── dashboard/       # System health, gateway cards, quick actions
│   ├── communication/   # P2P, group, broadcast messaging, speech-to-text
│   ├── live_map/        # OpenStreetMap, offline tiles, marker rendering
│   ├── notes/           # Geo-tagged emergency note creation & sharing
│   ├── emergency/       # One-touch SOS, broadcast, emergency event log
│   ├── network/         # Multi-hop routes, topology visualizer, metrics
│   └── settings/        # ESP32 IP configuration, radio channel, key config
├── services/
│   ├── connection_service.dart     # Gateway link manager & heartbeat
│   ├── discovery_service.dart      # UDP/mDNS gateway auto-finder
│   ├── websocket_service.dart      # Real-time event subscription bus
│   ├── lora_message_service.dart   # Outbound/inbound LoRa dispatcher
│   ├── node_service.dart           # Node registry & telemetry tracker
│   ├── location_service.dart       # Local GPS & distance calculations
│   └── storage_service.dart        # SQLite persistence coordinator
└── widgets/
    ├── common/          # Badges, tactical cards, pulse indicators
    ├── dialogs/         # Confirmation, note editors, node details
    └── map/             # Custom markers, range rings, telemetry popups
```

---

### 3. Local Database Schema (SQLite)

#### Table: `nodes`
- `id` (TEXT PRIMARY KEY) - Unique node identifier (e.g., `NODE-001`)
- `name` (TEXT) - Friendly display name (e.g., "Field Rescue Alpha")
- `type` (TEXT) - `gateway`, `relay`, `client`, `medical`, `command`
- `latitude` (REAL) - Latitude coordinate
- `longitude` (REAL) - Longitude coordinate
- `battery_percentage` (INTEGER) - 0 to 100%
- `battery_voltage` (REAL) - e.g. 4.12V
- `rssi` (INTEGER) - Signal strength in dBm (e.g., -85)
- `snr` (REAL) - Signal-to-noise ratio in dB (e.g., 8.5)
- `hop_count` (INTEGER) - Network hops from gateway
- `is_online` (INTEGER) - 1 if active, 0 if offline
- `last_seen` (INTEGER) - Unix epoch timestamp (ms)
- `is_verified` (INTEGER) - 1 if validated via telemetry, 0 if manual unverified

#### Table: `messages`
- `id` (TEXT PRIMARY KEY) - Unique UUID
- `source_node` (TEXT) - Origin node ID
- `destination_node` (TEXT) - Target node ID (or `BROADCAST`)
- `content` (TEXT) - Text message body
- `timestamp` (INTEGER) - Unix epoch timestamp (ms)
- `type` (TEXT) - `chat`, `sos`, `note_share`, `telemetry`
- `status` (TEXT) - `draft`, `queued`, `sent`, `delivered`, `failed`
- `rssi` (INTEGER) - Measured packet RSSI
- `snr` (REAL) - Measured packet SNR
- `hop_count` (INTEGER) - Actual transmission hops
- `is_encrypted` (INTEGER) - 1 if encrypted, 0 if plaintext

#### Table: `geo_notes`
- `id` (TEXT PRIMARY KEY) - Unique UUID
- `title` (TEXT) - Short summary
- `description` (TEXT) - Detailed emergency report
- `category` (TEXT) - `general`, `medical`, `rescue`, `fire`, `accident`, `flood`, `earthquake`, `hazard`
- `priority` (TEXT) - `low`, `normal`, `high`, `critical`
- `latitude` (REAL) - Geographic latitude
- `longitude` (REAL) - Geographic longitude
- `author_node_id` (TEXT) - Creator node identifier
- `created_at` (INTEGER) - Creation timestamp
- `sync_status` (TEXT) - `local`, `sharing`, `synced`, `received`

#### Table: `emergency_events`
- `id` (TEXT PRIMARY KEY) - Unique UUID
- `emergency_type` (TEXT) - SOS category
- `source_node` (TEXT) - Originating node
- `latitude` (REAL) - Incident latitude
- `longitude` (REAL) - Incident longitude
- `severity` (TEXT) - `advisory`, `warning`, `critical`, `life_threatening`
- `timestamp` (INTEGER) - Alert timestamp
- `is_acknowledged` (INTEGER) - 1 if ACKed, 0 otherwise
- `acknowledged_by` (TEXT) - Responding node

#### Table: `network_routes`
- `route_id` (TEXT PRIMARY KEY)
- `source_node` (TEXT)
- `destination_node` (TEXT)
- `hops` (TEXT) - JSON array of intermediate relay node IDs
- `total_hops` (INTEGER)
- `avg_rssi` (REAL)
- `last_updated` (INTEGER)

