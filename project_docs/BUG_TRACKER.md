# D-MESH: Defect & Bug Tracker

This document tracks unresolved, active, and resolved defects across hardware firmware and mobile application code.

---

### Defect Log

| Issue ID | Date | Module | Severity | Description | Status | Resolution / Notes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **BUG-000** | 2026-10-31 | Environment | Low | Flutter SDK not registered in active shell PATH | Open (Expected) | Source code structured cleanly for compilation on any standard Flutter environment. |

---

### Triage Guidelines
- **Critical (P0)**: Application crash, packet loss under normal transmission, incorrect coordinate translation leading to dangerous rescue misdirection, or failure to persist emergency notes.
- **High (P1)**: WebSocket disconnect without auto-recovery, failure to send messages over LoRa queue, or inaccurate battery reporting.
- **Medium (P2)**: Sub-optimal UI layout on smaller screens, sluggish map pan, or delayed ACK indicator.
- **Low (P3)**: Minor visual styling discrepancy or documentation typos.

