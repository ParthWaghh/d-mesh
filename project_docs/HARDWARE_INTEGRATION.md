# D-MESH: Hardware Integration Guide

This document details physical connections, module configurations, power considerations, and firmware integration specifications for D-MESH hardware.

---

### 1. Hardware Architecture Overview

A D-MESH deployment consists of two primary hardware classes:
1. **ESP32 Gateway Node**: Bridges the local smartphone user (via Wi-Fi SoftAP / Station) to the LoRa mesh network. Hosts REST and WebSocket servers, GPS module, and OLED display.
2. **ESP32 Mesh Node (Client / Relay)**: Remote field units with LoRa transceiver, GPS, OLED, and pushbuttons for tactical search-and-rescue teams.

---

### 2. Component Specifications

#### Microcontroller: ESP32-WROOM-32 / ESP32-S3
- **CPU**: Xtensa Dual-Core 32-bit LX6 running at 240 MHz
- **RAM**: 520 KB SRAM
- **Flash**: 4MB or 8MB SPI Flash
- **Peripherals**: 3x UART, 3x SPI, 2x I2C, Wi-Fi 802.11 b/g/n, Bluetooth v4.2 BR/EDR & BLE

#### LoRa Transceiver: Semtech SX1278 (Ra-02 / HopeRF RFM95W)
- **Frequency**: 433 MHz (Sub-GHz ISM Band, 410–525 MHz)
- **Modulation**: LoRa Spread Spectrum (FSK, GFSK, MSK, GMSK, LoRa, OOK)
- **Sensitivity**: Down to -148 dBm
- **Transmit Power**: Up to +20 dBm (100 mW)
- **Link Budget**: Up to 168 dB
- **Interface**: Hardware SPI (up to 10 MHz)

#### GPS / GNSS Module: u-blox NEO-6M
- **Channels**: 50 positioning channels
- **Time-to-First-Fix (TTFF)**: Cold start 27s, Hot start 1s
- **Horizontal Position Accuracy**: 2.5m CEP
- **Update Rate**: 1 Hz default, configurable up to 5 Hz
- **Protocol**: NMEA 0183 (GGA, RMC, GSV, GSA sentences)
- **Interface**: Hardware UART at 9600 bps

#### Display: 0.96-inch OLED SSD1306
- **Resolution**: 128 x 64 pixels
- **Technology**: Monochrome white or blue OLED
- **Interface**: I2C (Address `0x3C`)
- **Display Content**: Gateway IP, Wi-Fi clients, LoRa channel, active nodes, last packet RSSI.

---

### 3. Wiring & Pinout Table

| Module | Module Pin | ESP32 GPIO | Description / Mode |
| :--- | :--- | :--- | :--- |
| **SX1278 LoRa** | `SCK` | `GPIO 18` | Hardware SPI Clock |
| | `MISO` | `GPIO 19` | Hardware SPI Master In / Slave Out |
| | `MOSI` | `GPIO 23` | Hardware SPI Master Out / Slave In |
| | `NSS / CS` | `GPIO 5` | SPI Chip Select (Active Low) |
| | `RST` | `GPIO 14` | Hardware Reset (Active Low) |
| | `DIO0` | `GPIO 2` | Packet Rx / Tx Done Interrupt |
| | `VCC` | `3.3V` | Regulated 3.3V (Max 120mA peak during Tx) |
| | `GND` | `GND` | Ground reference |
| **NEO-6M GPS** | `TX` | `GPIO 16` | Connects to ESP32 RX2 (UART2) |
| | `RX` | `GPIO 17` | Connects to ESP32 TX2 (UART2) |
| | `VCC` | `3.3V` / `5V` | Regulated power |
| | `GND` | `GND` | Ground reference |
| **SSD1306 OLED** | `SDA` | `GPIO 21` | Hardware I2C Data |
| | `SCL` | `GPIO 22` | Hardware I2C Clock |
| | `VCC` | `3.3V` | OLED Power |
| | `GND` | `GND` | Ground reference |
| **Tactical Button**| `SOS PIN` | `GPIO 4` | Active Low push-button with internal pull-up |
| **Status LED** | `STATUS` | `GPIO 13` | Active High LED indicator |

> [!CAUTION]
> Always attach a suitable 433MHz spring or SMA whip antenna to the SX1278 module BEFORE powering on. Operating the LoRa transmitter without an antenna can permanently damage the RF power amplifier stage due to high reflected power (VSWR).

---

### 4. RF Link & LoRa Parameter Optimization

For emergency search-and-rescue over mountainous or urban disaster debris:
- **Frequency**: 433.175 MHz
- **Bandwidth**: 125.0 kHz (optimal balance of noise floor and data rate)
- **Spreading Factor (SF)**: SF9 (Default) or SF10 (Extended Range).
  - *SF7*: High data rate, lower range (~2-3 km urban).
  - *SF9*: Balanced disaster default (~5-8 km semi-open).
  - *SF12*: Maximum sensitivity, very slow airtime (~15+ km line of sight).
- **Coding Rate (CR)**: 4/7 or 4/8 (Forward Error Correction against burst interference).
- **Preamble Length**: 8 symbols.
- **Sync Word**: `0x12` (Private network isolation to prevent interference with public LoRaWAN).

---

### 5. Wi-Fi AP & Gateway Networking Configuration
- **SoftAP SSID**: `DMESH-GATEWAY-ALPHA`
- **SoftAP Password**: `dmeshrescue2026` (or open for emergency responders)
- **SoftAP IP Address**: `192.168.4.1`
- **Subnet Mask**: `255.255.255.0`
- **mDNS Hostname**: `dmesh-gateway.local`
- **UDP Discovery Port**: `8266` (Broadcasting JSON beacon every 3 seconds: `{"service":"dmesh","id":"GATEWAY-01","ip":"192.168.4.1","port":80}`)

