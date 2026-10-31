# D-MESH: Phased Implementation Roadmap

This roadmap defines the sequential, independently testable phases for the complete engineering and deployment of D-MESH.

---

### PHASE 0 — Project Inspection & Specification Baseline [COMPLETED]
- [x] Inspect existing workspace, toolchains, and hardware repositories.
- [x] Identify supported hardware capabilities and missing firmware dependencies.
- [x] Create persistent project documentation suite (`project_docs/`).
- [x] Establish bidirectional ESP32 API Contract (REST + WebSocket JSON specs).
- [x] User review and signoff on Phase 0 baseline before Phase 1 code generation.

---

### PHASE 1 — Application Foundation & Architecture Setup [COMPLETED]
- [x] Initialize Clean Architecture directory structure (`core/`, `data/`, `domain/`, `features/`, `services/`, `widgets/`).
- [x] Configure `pubspec.yaml` with essential production packages (`flutter_riverpod`, `flutter_map`, `latlong2`, `sqflite`, `path_provider`, `web_socket_channel`, `http`, `speech_to_text`, `uuid`, `crypto`, `encrypt`).
- [x] Implement dark-mode tactical command theme (Material 3: Navy/Charcoal `#0A0F1D`, `#131C31`, Cyan `#00E5FF`, Emerald `#00F59B`, Red SOS `#FF2A55`, Amber `#FF9E00`).
- [x] Build global navigation shell (6 primary bottom-nav destinations: Dashboard, Communication, Live Map, Emergency, Network, Settings).
- [x] Initialize SQLite database schema and database helper (`DMeshDatabase`) for tables: `nodes`, `messages`, `geo_notes`, `emergency_events`, `network_routes`.

---

### PHASE 2 — ESP32 Gateway Connectivity & Discovery Service [COMPLETED]
- [x] Implement `ESP32DiscoveryService` with local network broadcast discovery (UDP beacon / mDNS) and subnet pinging.
- [x] Build `ConnectionService` supporting Manual IP entry, input validation, reachability ping, and auto-discovery selection.
- [x] Implement `WebSocketService` with auto-reconnection backoff, heartbeat ping/pong, and connection state machine (`Connected`, `Connecting`, `Disconnected`, `Reconnecting`, `Error`).
- [x] Create Gateway Status Card and connection manager UI with real-time hardware status indicators.

---

### PHASE 3 — Node Management & Local Persistence [COMPLETED]
- [x] Implement `NodeRepository` and `NodeManagementService` backed by SQLite.
- [x] Build Manual Node Registration form with input validation (Node ID, Name, Type, GPS coords, Description).
- [x] Implement Automatic Node Discovery intake via gateway telemetry and LoRa beacon detection.
- [x] Differentiate between verified hardware communication and unverified offline registrations.
- [x] Build Node Directory UI with search, filter (Active, Relay, Gateway, Offline), and status badges (Battery, RSSI, SNR, Last-seen).

---

### PHASE 4 — Interactive Live Map & Geo-Tagged Tactical Notes [COMPLETED]
- [x] Integrate `flutter_map` with OpenStreetMap tile caching and offline tile store capabilities.
- [x] Implement GPS location tracking (`LocationService`) for user's device and ESP32 gateway.
- [x] Create specialized map markers: Gateway, Active Node, Relay Node, Offline Node, Emergency SOS, Medical, Rescue, Hazard, Tactical Note.
- [x] Implement Geo-Tagged Note Creation workflow:
  - Option A: Long-press / tap directly on map coordinate.
  - Option B: Use current GPS location.
  - Option C: Manual Lat/Long coordinate entry.
- [x] Build Note Management UI: Categorization, priority tags, editing, deletion, and SQLite persistence.
- [x] Implement bottom-sheet Note/Node Inspector with direct action shortcuts ("Send Message", "View Route", "Share Note").

---

### PHASE 5 — Real Hardware Messaging & LoRa Propagation [COMPLETED]
- [x] Implement `LoRaMessageService` and `GatewayCommunicationService`.
- [x] Build bi-directional WebSocket event dispatcher for `message_received`, `message_sent`, and `message_ack`.
- [x] Implement message deduplication via UUIDs and sequence numbers.
- [x] Create offline message queue with retry logic and transmission timeout handling.
- [x] Build Communication UI: Private peer-to-peer chats, group channels, and emergency broadcast.
- [x] Display link quality metrics (RSSI, SNR, Hops) alongside every received message.

---

### PHASE 6 — Over-The-Air Geo-Tagged Note Sharing [COMPLETED]
- [x] Implement Note serialization into compact LoRa binary/JSON payload.
- [x] Build "Share Note via LoRa" pipeline targeting specific nodes or mesh broadcast.
- [x] Implement remote note receiver: parse incoming note payload, save to SQLite, and render marker on Live Map.
- [x] Track delivery state: `Draft` -> `Queued` -> `Gateway Transmitted` -> `LoRa Dispatched` -> `Destination ACK`.

---

### PHASE 7 — Multi-Hop Mesh Routing & Dynamic Topology Graph [COMPLETED]
- [x] Implement `MeshRoutingService` parsing real hardware route tables.
- [x] Build visual route inspector displaying hop-by-hop nodes (`Source -> Relay 1 -> Relay 2 -> Destination`).
- [x] Color-code links by RSSI/SNR signal degradation and ACK status.
- [x] Build dynamic Network Topology Canvas graph screen visualizing mesh hierarchy, link qualities, and animated packet pulses.

---

### PHASE 8 — Emergency SOS & Triage Command Center [COMPLETED]
- [x] Build One-Touch Emergency SOS trigger with confirmation safeguard.
- [x] Implement prioritized Emergency Broadcast with GPS coordinates, emergency classification (Medical, Fire, Flood, Rescue, Hazard), and timestamp.
- [x] Create Emergency Event History log with response triage status tracking.
- [x] Implement acknowledgment and triage dispatch handling for received alerts.

---

### PHASE 9 — Speech-to-Text & Multimedia Dispatch [COMPLETED]
- [x] Integrate `speech_to_text` on-device dictation engine into message input bar.
- [x] Allow live transcription, correction, and single-tap LoRa broadcast.
- [x] Implement `MediaTransferService` for local Wi-Fi voice notes and compressed images with compact LoRa notification dispatch.

---

### PHASE 10 — Security, ESP32 Gateway Firmware & Optimization [COMPLETED]
- [x] Implement AES-256-GCM message payload encryption with HMAC-SHA256 authentication.
- [x] Author production ESP32 Gateway and Node Arduino C++ firmware:
  - `esp32_gateway.ino`: Wi-Fi AP/STA, AsyncWebServer, WebSockets, SX1278 SPI driver, NEO-6M GPS parser, SSD1306 OLED display driver, UDP beacon.
  - `esp32_mesh_node.ino`: SX1278 LoRa node with routing table, packet forwarding, ACK generation, and GPS telemetry.
- [x] Author PlatformIO environment configuration (`firmware/platformio.ini`).
- [x] Author comprehensive unit testing suite (`test/`) covering cryptography, geospatial math, data models, and packet deduplication.
