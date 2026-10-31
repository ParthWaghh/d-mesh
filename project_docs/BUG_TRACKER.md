# D-MESH: Defect & Bug Tracker

This document tracks unresolved, active, and resolved defects across hardware firmware and mobile application code.

---

### Defect & Limitation Log

| Issue ID | Module | Severity | Description | Status | Resolution / Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **BUG-000** | Environment | Low | Flutter SDK not registered in active shell PATH on host | Open (Host specific) | Source code structured cleanly for compilation on any standard Flutter environment. |
| **HW-001** | Hardware / RF | High | Antenna requirement for SX1278 | Known Precaution | Never power or transmit on SX1278 without an antenna attached. High VSWR can destroy output power amplifier. |
| **HW-002** | GPS / Indoors | Medium | NEO-6M Cold Start & Indoor TTFF | Known Limitation | NEO-6M requires outdoor line of sight to satellites for first GPS fix. Firmware falls back gracefully to default staging coordinates (19.9975, 73.7898). |
| **HW-003** | LoRa Airtime | Medium | Duty Cycle & MTU constraints | Handled by Protocol | SX1278 MTU capped at 220 bytes. High-bandwidth media (audio/images) is routed over local Wi-Fi, sending only compact metadata notifications over LoRa. |
| **NET-001** | Discovery | Low | UDP broadcast isolation on some Wi-Fi APs | Handled by Protocol | If UDP beacon on port 8266 is blocked by AP client isolation, `ESP32DiscoveryService` automatically falls back to direct HTTP probe at `192.168.4.1:80`. |

---

### Triage Guidelines
- **Critical (P0)**: Application crash, packet loss under normal transmission, incorrect coordinate translation leading to dangerous rescue misdirection, or failure to persist emergency notes.
- **High (P1)**: WebSocket disconnect without auto-recovery, failure to send messages over LoRa queue, or inaccurate battery reporting.
- **Medium (P2)**: Sub-optimal UI layout on smaller screens, sluggish map pan, or delayed ACK indicator.
- **Low (P3)**: Minor visual styling discrepancy or documentation typos.
