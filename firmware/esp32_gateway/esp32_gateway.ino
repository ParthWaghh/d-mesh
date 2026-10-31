/*
 * ==============================================================================
 * D-MESH: Decentralized Emergency Communication System
 * Firmware: ESP32 Hardware Gateway Bridge
 * ==============================================================================
 * Components:
 *   - ESP32-WROOM-32 (240MHz Dual-Core)
 *   - Semtech SX1278 LoRa Transceiver (433.175 MHz, SPI)
 *   - u-blox NEO-6M GPS Module (HardwareSerial2)
 *   - SSD1306 0.96" OLED Display (I2C @ 0x3C)
 *   - Wi-Fi SoftAP & AsyncWebServer + WebSockets
 * ==============================================================================
 */

#include <WiFi.h>
#include <AsyncTCP.h>
#include <ESPAsyncWebServer.h>
#include <SPI.h>
#include <LoRa.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <TinyGPS++.h>
#include <ArduinoJson.h>
#include <WiFiUdp.h>

// --- PIN ASSIGNMENTS ---
#define LORA_SCK     18
#define LORA_MISO    19
#define LORA_MOSI    23
#define LORA_CS      5
#define LORA_RST     14
#define LORA_DIO0    2

#define GPS_RX_PIN   16 // Connects to GPS Module TX
#define GPS_TX_PIN   17 // Connects to GPS Module RX
#define GPS_BAUDRATE 9600

#define OLED_SDA     21
#define OLED_SCL     22
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET   -1
#define SCREEN_ADDRESS 0x3C

#define BTN_SOS      4
#define LED_STATUS   13

// --- LORA CONFIGURATION ---
#define LORA_BAND        433.175E6
#define LORA_SF          9
#define LORA_BW          125E3
#define LORA_CR          7
#define LORA_TX_POWER    17
#define LORA_SYNC_WORD   0x12

// --- WI-FI ACCESS POINT DEFAULTS ---
const char* AP_SSID = "DMESH-GATEWAY-ALPHA";
const char* AP_PASS = "dmeshrescue2026";
IPAddress local_ip(192, 168, 4, 1);
IPAddress gateway_ip(192, 168, 4, 1);
IPAddress subnet(255, 255, 255, 0);

// --- PERIPHERAL INSTANCES ---
AsyncWebServer server(80);
AsyncWebSocket ws("/ws");
WiFiUDP udpDiscovery;
HardwareSerial gpsSerial(2);
TinyGPSPlus gps;
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// --- IN-MEMORY NODE REGISTRY CACHE ---
struct MeshNodeEntry {
  char id[16];
  char name[32];
  char type[16];
  double lat;
  double lon;
  int battery;
  int rssi;
  float snr;
  int hops;
  bool is_online;
  unsigned long last_seen_ms;
};

#define MAX_NODES 32
MeshNodeEntry nodeTable[MAX_NODES];
int nodeCount = 0;

// Device identifiers
const char* DEVICE_NAME = "DMESH-GATEWAY-ALPHA";
const char* NODE_ID = "GATEWAY-01";
const char* FIRMWARE_VER = "1.0.0-lora";

unsigned long lastBeaconMs = 0;
unsigned long lastDisplayMs = 0;

// ==============================================================================
// OLED DISPLAY HELPER
// ==============================================================================
void updateDisplay(const char* statusLine, int packetRssi = 0) {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);

  display.setCursor(0, 0);
  display.println("D-MESH RESCUE GATEWAY");
  display.drawLine(0, 10, 127, 10, SSD1306_WHITE);

  display.setCursor(0, 14);
  display.print("AP IP: ");
  display.println(WiFi.softAPIP().toString());

  display.setCursor(0, 26);
  display.print("LoRa: 433.175M SF9");

  display.setCursor(0, 38);
  display.print("Peers: ");
  display.print(nodeCount);
  display.print(" | GPS: ");
  display.print(gps.location.isValid() ? "FIX" : "NO FIX");

  display.setCursor(0, 50);
  display.print(statusLine);

  display.display();
}

// ==============================================================================
// WEBSOCKET BROADCAST DISPATCHER
// ==============================================================================
void broadcastWsEvent(const char* eventName, JsonDocument& doc) {
  JsonDocument root;
  root["event"] = eventName;
  root["data"] = doc;

  String output;
  serializeJson(root, output);
  ws.textAll(output);
}

// ==============================================================================
// LORA PACKET TRANSMITTER
// ==============================================================================
bool transmitLoRaPacket(const String& payload) {
  digitalWrite(LED_STATUS, HIGH);
  LoRa.beginPacket();
  LoRa.print(payload);
  bool res = LoRa.endPacket();
  digitalWrite(LED_STATUS, LOW);
  return res;
}

// ==============================================================================
// LORA PACKET RECEIVER (CALLED IN LOOP)
// ==============================================================================
void checkLoRaIncoming() {
  int packetSize = LoRa.parsePacket();
  if (packetSize == 0) return;

  String incoming = "";
  while (LoRa.available()) {
    incoming += (char)LoRa.read();
  }

  int rssi = LoRa.packetRssi();
  float snr = LoRa.packetSnr();

  digitalWrite(LED_STATUS, HIGH);

  // Attempt to parse structured JSON
  JsonDocument doc;
  DeserializationError err = deserializeJson(doc, incoming);

  if (!err) {
    const char* type = doc["type"] | "chat";

    if (strcmp(type, "sos") == 0) {
      doc["rssi"] = rssi;
      doc["snr"] = snr;
      broadcastWsEvent("emergency_received", doc);
      updateDisplay("! SOS RECEIVED !", rssi);
    } else if (strcmp(type, "note_share") == 0) {
      broadcastWsEvent("note_received", doc);
      updateDisplay("Note Sync RX", rssi);
    } else if (strcmp(type, "ack") == 0) {
      doc["rssi"] = rssi;
      doc["snr"] = snr;
      broadcastWsEvent("message_ack", doc);
    } else {
      doc["rssi"] = rssi;
      doc["snr"] = snr;
      broadcastWsEvent("message_received", doc);
      updateDisplay("Message RX", rssi);
    }

    // Update node table entry if source is present
    const char* src = doc["source_node"];
    if (src) {
      bool found = false;
      for (int i = 0; i < nodeCount; i++) {
        if (strcmp(nodeTable[i].id, src) == 0) {
          nodeTable[i].rssi = rssi;
          nodeTable[i].snr = snr;
          nodeTable[i].is_online = true;
          nodeTable[i].last_seen_ms = millis();
          if (doc["latitude"]) nodeTable[i].lat = doc["latitude"];
          if (doc["longitude"]) nodeTable[i].lon = doc["longitude"];
          found = true;
          break;
        }
      }
      if (!found && nodeCount < MAX_NODES) {
        strlcpy(nodeTable[nodeCount].id, src, 16);
        strlcpy(nodeTable[nodeCount].name, src, 32);
        strlcpy(nodeTable[nodeCount].type, "client", 16);
        nodeTable[nodeCount].lat = doc["latitude"] | 19.9975;
        nodeTable[nodeCount].lon = doc["longitude"] | 73.7898;
        nodeTable[nodeCount].battery = doc["battery"] | 90;
        nodeTable[nodeCount].rssi = rssi;
        nodeTable[nodeCount].snr = snr;
        nodeTable[nodeCount].hops = doc["hops"] | 1;
        nodeTable[nodeCount].is_online = true;
        nodeTable[nodeCount].last_seen_ms = millis();
        nodeCount++;

        // Notify client app
        JsonDocument nDoc;
        nDoc["node_id"] = src;
        nDoc["name"] = src;
        nDoc["type"] = "client";
        nDoc["latitude"] = nodeTable[nodeCount-1].lat;
        nDoc["longitude"] = nodeTable[nodeCount-1].lon;
        nDoc["battery"] = nodeTable[nodeCount-1].battery;
        nDoc["rssi"] = rssi;
        nDoc["snr"] = snr;
        nDoc["hops"] = 1;
        nDoc["is_online"] = true;
        broadcastWsEvent("node_discovered", nDoc);
      }
    }
  }

  digitalWrite(LED_STATUS, LOW);
}

// ==============================================================================
// REST API ROUTING SETUP
// ==============================================================================
void setupRestApi() {
  // CORS header
  DefaultHeaders::Instance().addHeader("Access-Control-Allow-Origin", "*");
  DefaultHeaders::Instance().addHeader("Access-Control-Allow-Headers", "*");

  // 1. GET /api/device/info
  server.on("/api/device/info", HTTP_GET, [](AsyncWebServerRequest *request) {
    JsonDocument doc;
    doc["status"] = "success";
    JsonObject data = doc["data"].to<JsonObject>();
    data["device_name"] = DEVICE_NAME;
    data["node_id"] = NODE_ID;
    data["ip_address"] = WiFi.softAPIP().toString();
    data["mac_address"] = WiFi.macAddress();
    data["firmware_version"] = FIRMWARE_VER;
    data["uptime_seconds"] = millis() / 1000;
    data["battery_percentage"] = 96;
    data["battery_voltage"] = 4.15;

    JsonObject hw = data["hardware"].to<JsonObject>();
    hw["lora_freq_hz"] = LORA_BAND;
    hw["spreading_factor"] = LORA_SF;
    hw["bandwidth_hz"] = LORA_BW;
    hw["tx_power_dbm"] = LORA_TX_POWER;

    String response;
    serializeJson(doc, response);
    request->send(200, "application/json", response);
  });

  // 2. GET /api/nodes
  server.on("/api/nodes", HTTP_GET, [](AsyncWebServerRequest *request) {
    JsonDocument doc;
    doc["status"] = "success";
    JsonArray arr = doc["data"].to<JsonArray>();

    for (int i = 0; i < nodeCount; i++) {
      JsonObject n = arr.add<JsonObject>();
      n["node_id"] = nodeTable[i].id;
      n["name"] = nodeTable[i].name;
      n["type"] = nodeTable[i].type;
      n["latitude"] = nodeTable[i].lat;
      n["longitude"] = nodeTable[i].lon;
      n["battery"] = nodeTable[i].battery;
      n["rssi"] = nodeTable[i].rssi;
      n["snr"] = nodeTable[i].snr;
      n["hops"] = nodeTable[i].hops;
      n["is_online"] = nodeTable[i].is_online;
      n["last_seen"] = nodeTable[i].last_seen_ms / 1000;
    }

    String response;
    serializeJson(doc, response);
    request->send(200, "application/json", response);
  });

  // 3. POST /api/nodes/register
  server.on("/api/nodes/register", HTTP_POST, [](AsyncWebServerRequest *request) {}, NULL,
    [](AsyncWebServerRequest *request, uint8_t *data, size_t len, size_t index, size_t total) {
      JsonDocument doc;
      deserializeJson(doc, (const char*)data);

      const char* nid = doc["node_id"];
      if (nid && nodeCount < MAX_NODES) {
        strlcpy(nodeTable[nodeCount].id, nid, 16);
        strlcpy(nodeTable[nodeCount].name, doc["name"] | nid, 32);
        strlcpy(nodeTable[nodeCount].type, doc["type"] | "client", 16);
        nodeTable[nodeCount].lat = doc["latitude"] | 19.9975;
        nodeTable[nodeCount].lon = doc["longitude"] | 73.7898;
        nodeTable[nodeCount].battery = 100;
        nodeTable[nodeCount].rssi = -75;
        nodeTable[nodeCount].snr = 9.0;
        nodeTable[nodeCount].hops = 1;
        nodeTable[nodeCount].is_online = true;
        nodeTable[nodeCount].last_seen_ms = millis();
        nodeCount++;
      }
      request->send(200, "application/json", "{\"status\":\"success\"}");
    });

  // 4. POST /api/messages/send
  server.on("/api/messages/send", HTTP_POST, [](AsyncWebServerRequest *request) {}, NULL,
    [](AsyncWebServerRequest *request, uint8_t *data, size_t len, size_t index, size_t total) {
      String payload = String((const char*)data);
      bool transmitted = transmitLoRaPacket(payload);

      JsonDocument resp;
      resp["status"] = transmitted ? "sent" : "failed";
      resp["airtime_ms"] = 120;

      String out;
      serializeJson(resp, out);
      request->send(transmitted ? 200 : 500, "application/json", out);
    });

  // 5. POST /api/emergency/sos
  server.on("/api/emergency/sos", HTTP_POST, [](AsyncWebServerRequest *request) {}, NULL,
    [](AsyncWebServerRequest *request, uint8_t *data, size_t len, size_t index, size_t total) {
      String payload = String((const char*)data);
      // High power emergency transmit
      LoRa.setTxPower(20);
      transmitLoRaPacket(payload);
      LoRa.setTxPower(LORA_TX_POWER);

      request->send(200, "application/json", "{\"status\":\"broadcast_transmitted\"}");
    });

  // 6. GET /api/gateway/status
  server.on("/api/gateway/status", HTTP_GET, [](AsyncWebServerRequest *request) {
    JsonDocument doc;
    doc["battery_percentage"] = 96;
    doc["uptime_seconds"] = millis() / 1000;
    doc["active_nodes"] = nodeCount;
    String response;
    serializeJson(doc, response);
    request->send(200, "application/json", response);
  });
}

// ==============================================================================
// ARDUINO SETUP
// ==============================================================================
void setup() {
  Serial.begin(115200);
  pinMode(LED_STATUS, OUTPUT);
  pinMode(BTN_SOS, INPUT_PULLUP);

  // Initialize OLED Display
  Wire.begin(OLED_SDA, OLED_SCL);
  if (display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDRESS)) {
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 20);
    display.println("BOOTING D-MESH...");
    display.display();
  }

  // Initialize GPS Serial
  gpsSerial.begin(GPS_BAUDRATE, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);

  // Initialize LoRa Transceiver (SX1278)
  SPI.begin(LORA_SCK, LORA_MISO, LORA_MOSI, LORA_CS);
  LoRa.setPins(LORA_CS, LORA_RST, LORA_DIO0);

  if (!LoRa.begin(LORA_BAND)) {
    Serial.println("[ERROR] SX1278 LoRa initialization failed!");
    updateDisplay("LORA INIT FAILED!");
    while (1) {
      digitalWrite(LED_STATUS, !digitalRead(LED_STATUS));
      delay(200);
    }
  }

  LoRa.setSpreadingFactor(LORA_SF);
  LoRa.setSignalBandwidth(LORA_BW);
  LoRa.setCodingRate4(LORA_CR);
  LoRa.setTxPower(LORA_TX_POWER);
  LoRa.setSyncWord(LORA_SYNC_WORD);

  // Configure SoftAP Wi-Fi Network
  WiFi.mode(WIFI_AP);
  WiFi.softAPConfig(local_ip, gateway_ip, subnet);
  WiFi.softAP(AP_SSID, AP_PASS);

  // Initialize REST & WebSockets
  setupRestApi();
  server.addHandler(&ws);
  server.begin();

  // UDP Beacon Service
  udpDiscovery.begin(8266);

  updateDisplay("GATEWAY READY");
}

// ==============================================================================
// ARDUINO MAIN LOOP
// ==============================================================================
void loop() {
  // Read incoming GPS NMEA sentences
  while (gpsSerial.available() > 0) {
    gps.encode(gpsSerial.read());
  }

  // Check incoming LoRa packets
  checkLoRaIncoming();

  // Handle hardware SOS pushbutton
  if (digitalRead(BTN_SOS) == LOW) {
    delay(50); // Debounce
    if (digitalRead(BTN_SOS) == LOW) {
      JsonDocument sosDoc;
      sosDoc["alert_id"] = "SOS-HARDWARE-BTN";
      sosDoc["source_node"] = NODE_ID;
      sosDoc["emergency_type"] = "general_sos";
      sosDoc["severity"] = "life_threatening";
      sosDoc["latitude"] = gps.location.isValid() ? gps.location.lat() : 19.9975;
      sosDoc["longitude"] = gps.location.isValid() ? gps.location.lng() : 73.7898;
      sosDoc["description"] = "Hardware SOS pushbutton pressed on Gateway!";
      sosDoc["timestamp"] = millis() / 1000;

      String sosStr;
      serializeJson(sosDoc, sosStr);
      transmitLoRaPacket(sosStr);
      broadcastWsEvent("emergency_received", sosDoc);
      updateDisplay("HW SOS PRESSED!");
      delay(1000);
    }
  }

  // Periodic UDP broadcast beacon (every 3000ms)
  unsigned long now = millis();
  if (now - lastBeaconMs > 3000) {
    lastBeaconMs = now;
    udpDiscovery.beginPacket(IPAddress(192, 168, 4, 255), 8266);
    udpDiscovery.print("{\"service\":\"dmesh_gateway\",\"id\":\"GATEWAY-01\",\"port\":80}");
    udpDiscovery.endPacket();
  }

  // Periodic display refresh (every 5000ms)
  if (now - lastDisplayMs > 5000) {
    lastDisplayMs = now;
    updateDisplay("LISTENING 433MHz");
  }

  ws.cleanupClients();
}

