# D-MESH: Decentralized Emergency Communication and Rescue Network
## PROJECT OVERVIEW

### 1. Executive Summary
**D-MESH** is a mission-critical, offline-first mobile and embedded mesh communication system designed specifically for emergency disaster response and search-and-rescue operations. In major catastrophic events (earthquakes, floods, tsunamis, landslides, power grid collapses, or cellular infrastructure destruction), commercial networks (4G/5G, Internet service providers, cellular towers) fail or become overwhelmed. D-MESH restores decentralized communication using low-power, long-range Sub-GHz LoRa (Long Range) RF transceivers integrated with ESP32 microcontrollers and a Flutter mobile command interface.

The mobile application connects directly to a portable ESP32 Gateway node via local Wi-Fi (SoftAP or local infrastructure) using REST and real-time WebSockets. The ESP32 Gateway bridges the smartphone to an ad-hoc LoRa mesh network (SX1278 433 MHz), extending communication across kilometers without any cellular or internet infrastructure.

---

### 2. Core Capabilities & Objectives
1. **Zero-Internet Local Operation**: Full functionality (messaging, mapping, tracking, routing, alerting) operates entirely on local device storage (SQLite) and peer-to-peer LoRa radio transmission.
2. **ESP32 Gateway Integration**: Real-time bi-directional connection between Flutter and ESP32 over local Wi-Fi (WebSocket + REST) with automated discovery and health monitoring.
3. **Decentralized Node Discovery & Registration**: Automatic and manual discovery and registration of LoRa nodes with hardware telemetry (RSSI, SNR, battery voltage/percentage, GPS coordinates, hop count, status).
4. **Interactive Offline Live Map**: OpenStreetMap integration with cached tiles, GPS location markers for user, gateway, active nodes, relay nodes, hazard zones, and geo-tagged notes with real-time telemetry updates.
5. **Geo-Tagged Tactical Notes**: Creation, spatial rendering, SQLite persistence, and over-the-air LoRa propagation of emergency notes categorized by emergency type (Medical, Rescue, Fire, Accident, Flood, Earthquake, Hazard).
6. **Robust Real-Time Messaging**: Private, group, and broadcast emergency messaging with end-to-end unique message IDs, delivery acknowledgements (ACK), and local offline queuing.
7. **Speech-to-Text & Emergency Audio**: Speech-to-text voice recognition for rapid hands-free emergency message composition, with local Wi-Fi audio dispatching for high-bandwidth links.
8. **Multi-Hop Mesh Routing & Topology Graph**: Dynamic network topology visualization displaying nodes, link qualities (RSSI/SNR), active routes, relay nodes, packet transmission status, and packet delivery ratios (PDR).
9. **One-Touch Emergency SOS & Triage Alerts**: Prioritized emergency SOS broadcasting with GPS telemetry, severity levels, delivery tracking, and rapid response coordination.
10. **Cryptographic Integrity & Security**: AES-256-GCM encryption with message authentication to prevent spoofing or unauthorized interception in tactical disaster zones.

---

### 3. Technology Stack Breakdown

| Component | Technology / Library | Role & Function |
| :--- | :--- | :--- |
| **Mobile Framework** | Flutter 3.x / Dart 3.x | Cross-platform, responsive tactical UI |
| **Architecture** | Clean Architecture (Domain, Data, Core, Feature layers) | Decoupled UI, logic, hardware, and persistence |
| **State Management** | Riverpod / StateNotifier | Reactive state management, dependency injection |
| **Local Database** | SQLite (sqflite / drift) | Zero-dependency offline persistence for nodes, messages, notes |
| **Mapping & GIS** | `flutter_map` + `latlong2` + OpenStreetMap | Interactive offline mapping, custom vector markers, telemetry overlays |
| **Hardware MCU** | ESP32-WROOM-32 / ESP32-S3 | Dual-core 240MHz MCU bridging Wi-Fi and LoRa |
| **LoRa Transceiver** | Semtech SX1278 (433 MHz) | Long-range RF modulation, spread spectrum mesh transmission |
| **GNSS / GPS** | u-blox NEO-6M | High-precision latitude/longitude/altitude/timestamp acquisition |
| **Display & HMI** | 0.96" I2C SSD1306 OLED (128x64) | Standalone gateway hardware status display |
| **Local Bridge** | Wi-Fi 802.11 b/g/n (SoftAP / STA) | High-speed mobile-to-gateway REST & WebSocket link |
| **Speech Processing**| `speech_to_text` | On-device speech recognition to editable text |
| **Security** | AES-256-GCM + SHA-256 | Authenticated encryption for over-the-air packets |

---

### 4. Hardware Specifications & Pinout Blueprint

#### ESP32 Gateway Node Pinout
- **LoRa Module (SX1278 SPI)**:
  - `SCK`: GPIO 18
  - `MISO`: GPIO 19
  - `MOSI`: GPIO 23
  - `NSS / CS`: GPIO 5
  - `RST`: GPIO 14
  - `DIO0`: GPIO 2
- **GPS Module (NEO-6M UART)**:
  - `TX`: GPIO 16 (ESP32 RX2)
  - `RX`: GPIO 17 (ESP32 TX2)
  - `Baud`: 9600 bps
- **OLED Display (SSD1306 I2C)**:
  - `SDA`: GPIO 21
  - `SCL`: GPIO 22
- **Emergency Button / Status LEDs**:
  - `SOS Button`: GPIO 4 (Pullup)
  - `Status LED`: GPIO 13

---

### 5. Architectural Quality Standards
- Strict separation between Demo/Simulation mode and Real Hardware communication mode.
- Non-blocking asynchronous I/O across all networking layers.
- Verified coordinate accuracy and real hardware telemetry (no synthetic coordinates masquerading as hardware GPS).
- Deterministic SQLite migrations and local storage integrity.
- Graceful recovery from Wi-Fi link drops, socket disconnects, and packet collisions.

