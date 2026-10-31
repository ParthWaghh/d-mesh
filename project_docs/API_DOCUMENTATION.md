# D-MESH: Hardware API Contract & Protocols

This document defines the formal interface contract between the Flutter Mobile Application and the ESP32 Gateway Node over Wi-Fi (REST HTTP and WebSocket).

---

### 1. Transport Protocols & Addressing
- **Gateway Default IP**: `192.168.4.1` (SoftAP Mode `DMESH-GATEWAY-01`) or DHCP assigned in Station Mode.
- **REST Port**: `80` (HTTP)
- **WebSocket Endpoint**: `ws://<ESP32_IP>:80/ws` (or port `81`)
- **Payload Format**: Standard JSON UTF-8.

---

### 2. REST API Endpoints

#### `GET /api/device/info`
Returns gateway hardware identity, firmware version, and radio configuration.
```json
{
  "status": "success",
  "data": {
    "device_name": "DMESH-GATEWAY-ALPHA",
    "node_id": "GATEWAY-01",
    "ip_address": "192.168.4.1",
    "mac_address": "C4:4F:33:0A:1B:2C",
    "firmware_version": "1.0.0",
    "hardware": {
      "mcu": "ESP32-WROOM-32",
      "lora_module": "SX1278 (433MHz)",
      "lora_freq_hz": 433000000,
      "spreading_factor": 7,
      "bandwidth_hz": 125000,
      "coding_rate": 5,
      "tx_power_dbm": 17,
      "gps_module": "u-blox NEO-6M",
      "oled_display": "SSD1306 (128x64)"
    },
    "uptime_seconds": 3840,
    "battery_percentage": 94,
    "battery_voltage": 4.14
  }
}
```

#### `GET /api/nodes`
Retrieves all active nodes currently registered in the gateway's mesh routing cache.
```json
{
  "status": "success",
  "data": [
    {
      "node_id": "NODE-001",
      "name": "Search Team Lead",
      "type": "client",
      "latitude": 19.9975,
      "longitude": 73.7898,
      "battery": 87,
      "rssi": -82,
      "snr": 8.5,
      "hops": 1,
      "is_online": true,
      "last_seen": 1793470020
    },
    {
      "node_id": "NODE-002",
      "name": "Relay Tower Hill",
      "type": "relay",
      "latitude": 20.0021,
      "longitude": 73.7954,
      "battery": 98,
      "rssi": -69,
      "snr": 11.2,
      "hops": 1,
      "is_online": true,
      "last_seen": 1793470045
    }
  ]
}
```

#### `POST /api/nodes/register`
Manually adds or edits a node definition in the gateway routing table.
**Request:**
```json
{
  "node_id": "NODE-004",
  "name": "Medical Triage West",
  "type": "medical",
  "latitude": 19.9912,
  "longitude": 73.7815,
  "description": "Field Hospital unit"
}
```
**Response:**
```json
{
  "status": "success",
  "message": "Node NODE-004 registered in gateway mesh table"
}
```

#### `POST /api/messages/send`
Submits an outbound message to the gateway for transmission over the SX1278 LoRa radio.
**Request:**
```json
{
  "message_id": "8fa21e42-1e90-4a8b-967b-40fae0078121",
  "source_node": "GATEWAY-01",
  "destination_node": "NODE-004",
  "content": "Medical team dispatched to Sector B.",
  "type": "chat",
  "timestamp": 1793470100,
  "priority": "normal"
}
```
**Response:**
```json
{
  "status": "queued",
  "message_id": "8fa21e42-1e90-4a8b-967b-40fae0078121",
  "queue_position": 1,
  "estimated_airtime_ms": 142
}
```

#### `POST /api/emergency/sos`
Immediate high-priority emergency broadcast override.
**Request:**
```json
{
  "alert_id": "sos-60291-a",
  "emergency_type": "medical",
  "source_node": "GATEWAY-01",
  "latitude": 19.9975,
  "longitude": 73.7898,
  "severity": "critical",
  "description": "Severe casualty requires immediate extraction",
  "timestamp": 1793470125
}
```
**Response:**
```json
{
  "status": "broadcast_transmitted",
  "alert_id": "sos-60291-a",
  "tx_power_dbm": 20,
  "channel": 433000000
}
```

---

### 3. WebSocket Real-Time Event Protocol

WebSocket connects to `ws://<ESP32_IP>/ws`. Communication uses structured JSON with standard envelopes:
```json
{
  "event": "<event_name>",
  "data": { ... }
}
```

#### Event: `message_received`
Fired when the ESP32 SX1278 transceiver receives an over-the-air packet addressed to the gateway or broadcast.
```json
{
  "event": "message_received",
  "data": {
    "message_id": "MSG_001_A9",
    "source_node": "NODE-004",
    "destination_node": "GATEWAY-01",
    "content": "Patient stabilized. Awaiting transport.",
    "type": "chat",
    "timestamp": 1793470150,
    "rssi": -87,
    "snr": 7.5,
    "hop_count": 2,
    "relay_nodes": ["NODE-002"]
  }
}
```

#### Event: `message_ack`
Fired when a downstream node returns an explicit radio ACK for a transmitted message ID.
```json
{
  "event": "message_ack",
  "data": {
    "message_id": "8fa21e42-1e90-4a8b-967b-40fae0078121",
    "ack_by_node": "NODE-004",
    "round_trip_ms": 320,
    "rssi": -85,
    "snr": 8.0
  }
}
```

#### Event: `node_discovered`
Fired when a new LoRa node beacon or packet is received from an unlisted node.
```json
{
  "event": "node_discovered",
  "data": {
    "node_id": "NODE-006",
    "name": "Rescue Drone Beacon",
    "type": "client",
    "latitude": 19.9988,
    "longitude": 73.7912,
    "battery": 72,
    "rssi": -93,
    "snr": 4.5,
    "hop_count": 1
  }
}
```

#### Event: `node_location_updated`
Fired when a remote node's GPS telemetry updates.
```json
{
  "event": "node_location_updated",
  "data": {
    "node_id": "NODE-001",
    "latitude": 19.9981,
    "longitude": 73.7904,
    "altitude_m": 580.4,
    "speed_mps": 1.2,
    "timestamp": 1793470180
  }
}
```

#### Event: `route_updated`
Fired when mesh routing topology discovers or invalidates an active multi-hop path.
```json
{
  "event": "route_updated",
  "data": {
    "source_node": "GATEWAY-01",
    "destination_node": "NODE-004",
    "path": ["GATEWAY-01", "NODE-002", "NODE-004"],
    "total_hops": 2,
    "link_metrics": [
      { "from": "GATEWAY-01", "to": "NODE-002", "rssi": -69, "snr": 11.2 },
      { "from": "NODE-002", "to": "NODE-004", "rssi": -84, "snr": 6.8 }
    ]
  }
}
```

#### Event: `emergency_received`
Fired immediately upon reception of any SOS broadcast packet.
```json
{
  "event": "emergency_received",
  "data": {
    "alert_id": "sos-9901",
    "source_node": "NODE-003",
    "emergency_type": "flood",
    "severity": "life_threatening",
    "latitude": 20.0015,
    "longitude": 73.7842,
    "description": "Flash flood washing out perimeter bridge",
    "timestamp": 1793470210,
    "rssi": -91,
    "snr": 5.1
  }
}
```

#### Event: `note_received`
Fired when an over-the-air geo-tagged note is broadcasted or shared.
```json
{
  "event": "note_received",
  "data": {
    "note_id": "NOTE-4421-B",
    "title": "Blocked Road - Landslide",
    "description": "Route 4 blocked by debris. Heavy machinery needed.",
    "category": "hazard",
    "priority": "high",
    "latitude": 20.0034,
    "longitude": 73.7891,
    "author_node_id": "NODE-002",
    "created_at": 1793470220
  }
}
```

