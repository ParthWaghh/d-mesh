/*
 * ==============================================================================
 * D-MESH: Decentralized Emergency Communication System
 * Firmware: Remote LoRa Mesh Node (Client / Relay / Rescue Unit)
 * ==============================================================================
 * Components:
 *   - ESP32-WROOM-32 MCU
 *   - Semtech SX1278 LoRa Module (433.175 MHz)
 *   - u-blox NEO-6M GPS Module (Serial2)
 *   - SSD1306 0.96" OLED Display (I2C)
 *   - Pushbutton SOS trigger
 * ==============================================================================
 */

#include <SPI.h>
#include <LoRa.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <TinyGPS++.h>
#include <ArduinoJson.h>

// --- NODE IDENTITY ---
const char* NODE_ID = "NODE-002";
const char* NODE_NAME = "Relay Tower Hill";
const char* NODE_ROLE = "relay"; // "client", "relay", "medical"

// --- PIN ASSIGNMENTS ---
#define LORA_SCK     18
#define LORA_MISO    19
#define LORA_MOSI    23
#define LORA_CS      5
#define LORA_RST     14
#define LORA_DIO0    2

#define GPS_RX_PIN   16
#define GPS_TX_PIN   17
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

// --- INSTANCES ---
HardwareSerial gpsSerial(2);
TinyGPSPlus gps;
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

unsigned long lastBeaconMs = 0;
unsigned long lastDisplayMs = 0;

void updateDisplay(const char* line1, const char* line2 = "") {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);

  display.setCursor(0, 0);
  display.print("D-MESH: ");
  display.println(NODE_ID);
  display.drawLine(0, 10, 127, 10, SSD1306_WHITE);

  display.setCursor(0, 16);
  display.print("Role: ");
  display.println(NODE_ROLE);

  display.setCursor(0, 28);
  display.print("GPS: ");
  if (gps.location.isValid()) {
    display.print(gps.location.lat(), 4);
    display.print(",");
    display.println(gps.location.lng(), 4);
  } else {
    display.println("Searching...");
  }

  display.setCursor(0, 42);
  display.println(line1);

  display.setCursor(0, 54);
  display.println(line2);

  display.display();
}

bool transmitPacket(const String& payload) {
  digitalWrite(LED_STATUS, HIGH);
  LoRa.beginPacket();
  LoRa.print(payload);
  bool res = LoRa.endPacket();
  digitalWrite(LED_STATUS, LOW);
  return res;
}

void sendAck(const char* messageId, const char* destNode) {
  JsonDocument doc;
  doc["type"] = "ack";
  doc["message_id"] = messageId;
  doc["source_node"] = NODE_ID;
  doc["destination_node"] = destNode;
  doc["timestamp"] = millis() / 1000;

  String out;
  serializeJson(doc, out);
  delay(100); // Backoff before ACK transmission
  transmitPacket(out);
}

void sendTelemetryBeacon() {
  JsonDocument doc;
  doc["type"] = "telemetry";
  doc["source_node"] = NODE_ID;
  doc["destination_node"] = "BROADCAST";
  doc["name"] = NODE_NAME;
  doc["role"] = NODE_ROLE;
  doc["battery"] = 92;
  doc["latitude"] = gps.location.isValid() ? gps.location.lat() : 20.0021;
  doc["longitude"] = gps.location.isValid() ? gps.location.lng() : 73.7954;
  doc["hops"] = 1;
  doc["timestamp"] = millis() / 1000;

  String out;
  serializeJson(doc, out);
  transmitPacket(out);
}

void checkIncomingPacket() {
  int packetSize = LoRa.parsePacket();
  if (packetSize == 0) return;

  String incoming = "";
  while (LoRa.available()) {
    incoming += (char)LoRa.read();
  }

  int rssi = LoRa.packetRssi();
  float snr = LoRa.packetSnr();

  JsonDocument doc;
  DeserializationError err = deserializeJson(doc, incoming);
  if (!err) {
    const char* dest = doc["destination_node"];
    const char* src = doc["source_node"];
    const char* msgId = doc["message_id"];
    const char* type = doc["type"] | "chat";

    bool forMe = (dest && (strcmp(dest, NODE_ID) == 0 || strcmp(dest, "BROADCAST") == 0));

    if (forMe) {
      if (strcmp(type, "sos") == 0) {
        updateDisplay("EMERGENCY ALERT RX!", src);
      } else if (strcmp(type, "chat") == 0) {
        updateDisplay("NEW MSG FROM:", src);
        if (dest && strcmp(dest, NODE_ID) == 0 && msgId) {
          sendAck(msgId, src);
        }
      } else if (strcmp(type, "note_share") == 0) {
        updateDisplay("GEO-NOTE RX:", src);
        if (dest && strcmp(dest, NODE_ID) == 0 && msgId) {
          sendAck(msgId, src);
        }
      }
    } else if (strcmp(NODE_ROLE, "relay") == 0) {
      // Mesh Packet Forwarding
      int hops = doc["hops"] | 0;
      if (hops < 7) {
        doc["hops"] = hops + 1;
        String forwarded;
        serializeJson(doc, forwarded);
        delay(150 + random(50, 200)); // Jitter to prevent collision
        transmitPacket(forwarded);
        updateDisplay("FORWARDED PACKET", src);
      }
    }
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(LED_STATUS, OUTPUT);
  pinMode(BTN_SOS, INPUT_PULLUP);

  Wire.begin(OLED_SDA, OLED_SCL);
  if (display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDRESS)) {
    display.clearDisplay();
    display.display();
  }

  gpsSerial.begin(GPS_BAUDRATE, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);

  SPI.begin(LORA_SCK, LORA_MISO, LORA_MOSI, LORA_CS);
  LoRa.setPins(LORA_CS, LORA_RST, LORA_DIO0);

  if (!LoRa.begin(LORA_BAND)) {
    updateDisplay("LORA INIT FAILED!");
    while (1) {
      digitalWrite(LED_STATUS, !digitalRead(LED_STATUS));
      delay(300);
    }
  }

  LoRa.setSpreadingFactor(LORA_SF);
  LoRa.setSignalBandwidth(LORA_BW);
  LoRa.setCodingRate4(LORA_CR);
  LoRa.setTxPower(LORA_TX_POWER);
  LoRa.setSyncWord(LORA_SYNC_WORD);

  updateDisplay("NODE INITIALIZED");
}

void loop() {
  while (gpsSerial.available() > 0) {
    gps.encode(gpsSerial.read());
  }

  checkIncomingPacket();

  // Pushbutton SOS
  if (digitalRead(BTN_SOS) == LOW) {
    delay(50);
    if (digitalRead(BTN_SOS) == LOW) {
      JsonDocument sos;
      sos["type"] = "sos";
      sos["source_node"] = NODE_ID;
      sos["destination_node"] = "BROADCAST";
      sos["latitude"] = gps.location.isValid() ? gps.location.lat() : 20.0021;
      sos["longitude"] = gps.location.isValid() ? gps.location.lng() : 73.7954;
      sos["description"] = "Field Node SOS triggered via Pushbutton!";
      sos["timestamp"] = millis() / 1000;

      String out;
      serializeJson(sos, out);
      LoRa.setTxPower(20);
      transmitPacket(out);
      LoRa.setTxPower(LORA_TX_POWER);

      updateDisplay("! SOS TRANSMITTED !");
      delay(1500);
    }
  }

  // Periodic Telemetry Beacon (every 30 seconds)
  unsigned long now = millis();
  if (now - lastBeaconMs > 30000) {
    lastBeaconMs = now;
    sendTelemetryBeacon();
  }

  if (now - lastDisplayMs > 6000) {
    lastDisplayMs = now;
    updateDisplay("LISTENING 433MHz");
  }
}

