# D-MESH: Phased Implementation Roadmap

This roadmap defines the sequential, independently testable phases for the complete engineering and deployment of D-MESH.

---

### PHASE 0 — Project Inspection & Specification Baseline [CURRENT]
- [x] Inspect existing workspace, toolchains, and hardware repositories.
- [x] Identify supported hardware capabilities and missing firmware dependencies.
- [x] Create persistent project documentation suite (`project_docs/`).
- [x] Establish bidirectional ESP32 API Contract (REST + WebSocket JSON specs).
- [ ] User review and signoff on Phase 0 baseline before Phase 1 code generation.

---

### PHASE 1 — Application Foundation & Architecture Setup
- [ ] Initialize Clean Architecture directory structure (`core/`, `data/`, `domain/`, `features/`, `services/`, `widgets/`).
- [ ] Configure `pubspec.yaml` with essential production packages (`flutter_riverpod`, `flutter_map`, `latlong2`, `sqflite`, `path_provider`, `web_socket_channel`, `http`, `speech_to_text`, `uuid`, `crypto`, `encrypt`).
- [ ] Implement dark-mode tactical command theme (Material 3: Navy/Charcoal `#0B132B`, `#1C2541`, Cyan `#48CAE4`, Emerald `#06D6A0`, Red SOS `#EF476F`, Amber `#FFD166`).
- [ ] Build global navigation shell (6 primary bottom-nav destinations: Dashboard, Communication, Live Map, Emergency, Network, Settings).
- [ ] Initialize SQLite database schema and database helper (`DMeshDatabase`) for tables: `nodes`, `messages`, `notes`, `emergency_events`, `network_metrics`, `routes`.

---

### PHASE 2 — ESP32 Gateway Connectivity & Discovery Service
- [ ] Implement `ESP32DiscoveryService` with local network broadcast discovery (UDP beacon / mDNS) and subnet pinging.
- [ ] Build `ConnectionService` supporting Manual IP entry, input validation, reachability ping, and auto-discovery selection.
- [ ] Implement `WebSocketService` with auto-reconnection backoff, heartbeat ping/pong, and connection state machine (`Connected`, `Connecting`, `Disconnected`, `Reconnecting`, `Error`).
- [ ] Create Gateway Status Card and connection manager UI with real-time hardware status indicators.

---

### PHASE 3 — Node Management & Local Persistence
- [ ] Implement `NodeRepository` and `NodeManagementService` backed by SQLite.
- [ ] Build Manual Node Registration form with input validation (Node ID, Name, Type, GPS coords, Description).
- [ ] Implement Automatic Node Discovery intake via gateway telemetry and LoRa beacon detection.
- [ ] Differentiate between verified hardware communication and unverified offline registrations.
- [ ] Build Node Directory UI with search, filter (Active, Relay, Gateway, Offline), and status badges (Battery, RSSI, SNR, Last-seen).

---

### PHASE 4 — Interactive Live Map & Geo-Tagged Tactical Notes
- [ ] Integrate `flutter_map` with OpenStreetMap tile caching and offline tile store capabilities.
- [ ] Implement GPS location tracking (`LocationService`) for user's device and ESP32 gateway.
- [ ] Create specialized map markers: Gateway, Active Node, Relay Node, Offline Node, Emergency SOS, Medical, Rescue, Hazard, Tactical Note.
- [ ] Implement Geo-Tagged Note Creation workflow:
  - Option A: Long-press / tap directly on map coordinate.
  - Option B: Use current GPS location.
  - Option C: Manual Lat/Long coordinate entry.
- [ ] Build Note Management UI: Categorization, priority tags, editing, deletion, and SQLite persistence.
- [ ] Implement bottom-sheet Note/Node Inspector with direct action shortcuts ("Send Message", "View Route", "Share Note").

---

### PHASE 5 — Real Hardware Messaging & LoRa Propagation
- [ ] Implement `LoRaMessageService` and `GatewayCommunicationService`.
- [ ] Build bi-directional WebSocket event dispatcher for `message_received`, `message_sent`, and `message_ack`.
- [ ] Implement message deduplication via UUIDs and sequence numbers.
- [ ] Create offline message queue with retry logic and transmission timeout handling.
- [ ] Build Communication UI: Private peer-to-peer chats, group channels, and emergency broadcast.
- [ ] Display link quality metrics (RSSI, SNR, Hops) alongside every received message.

---

### PHASE 6 — Over-The-Air Geo-Tagged Note Sharing
- [ ] Implement Note serialization into compact LoRa binary/JSON payload.
- [ ] Build "Share Note via LoRa" pipeline targeting specific nodes or mesh broadcast.
- [ ] Implement remote note receiver: parse incoming note payload, save to SQLite, and render marker on Live Map.
- [ ] Track delivery state: `Draft` -> `Queued` -> `Gateway Transmitted` -> `LoRa Dispatched` -> `Destination ACK`.

---

### PHASE 7 — Multi-Hop Mesh Routing & Dynamic Topology Graph
- [ ] Implement `MeshRoutingService` parsing real hardware route tables.
- [ ] Build visual route inspector displaying hop-by-hop nodes (`Source -> Relay 1 -> Relay 2 -> Destination`).
- [ ] Color-code links by RSSI/SNR signal degradation and ACK status.
- [ ] Build dynamic Network Topology graph screen visualizing mesh hierarchy and active routing trees.

---

### PHASE 8 — Emergency SOS & Triage Command Center
- [ ] Build One-Touch Emergency SOS trigger with confirmation safeguard.
- [ ] Implement prioritized Emergency Broadcast with GPS coordinates, emergency classification (Medical, Fire, Flood, Rescue, Hazard), and timestamp.
- [ ] Create Emergency Event History log with response triage status tracking.
- [ ] Implement sound alert / haptic feedback for received emergency broadcasts.

---

### PHASE 9 — Speech-to-Text & Multimedia Dispatch
- [ ] Integrate `speech_to_text` on-device dictation engine into message input bar.
- [ ] Allow live transcription, correction, and single-tap LoRa broadcast.
- [ ] Implement local Wi-Fi voice memo and compressed image sharing service for gateway-connected clients.

---

### PHASE 10 — Security, ESP32 Gateway Firmware & Optimization
- [ ] Implement AES-256-GCM message payload encryption with HMAC-SHA256 authentication.
- [ ] Author production ESP32 Gateway and Node Arduino C++ firmware:
  - `esp32_gateway.ino`: Wi-Fi AP/STA, AsyncWebServer, WebSockets, SX1278 SPI driver, NEO-6M GPS parser, SSD1306 OLED display driver.
  - `esp32_mesh_node.ino`: SX1278 LoRa node with routing table, packet forwarding, ACK generation, and GPS telemetry.
- [ ] End-to-end integration testing, memory leak audits, and production packaging.

