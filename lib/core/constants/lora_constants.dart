class LoRaConstants {
  // RF Physical Layer (SX1278 433 MHz)
  static const double defaultFrequencyMhz = 433.175;
  static const int defaultSpreadingFactor = 9; // SF7-SF12
  static const double defaultBandwidthKhz = 125.0;
  static const int defaultCodingRate = 7; // 4/7
  static const int defaultTxPowerDbm = 17; // Up to 20 dBm (100mW)
  static const int syncWord = 0x12;

  // Signal Strength (RSSI in dBm) thresholds
  static const int rssiExcellent = -70; // -70 dBm or better
  static const int rssiGood = -85;      // -71 to -85 dBm
  static const int rssiFair = -100;     // -86 to -100 dBm
  static const int rssiPoor = -115;     // -101 to -115 dBm
  // Below -115 dBm is critical / edge of reception (SX1278 floor ~ -125 to -135 depending on SF)

  // Signal-to-Noise Ratio (SNR in dB) thresholds
  static const double snrStrong = 7.0;
  static const double snrModerate = 0.0;
  static const double snrPoor = -7.0;

  // Packet Limits
  static const int maxLoRaPayloadBytes = 220; // Safe MTU for single unfragmented LoRa packet
  static const int messageTimeoutSeconds = 12;
  static const int maxHopCount = 7;
}

enum LinkQuality {
  excellent,
  good,
  fair,
  poor,
  critical,
  unknown,
}

LinkQuality evaluateLinkQuality(int rssi, double snr) {
  if (rssi >= LoRaConstants.rssiExcellent && snr >= LoRaConstants.snrStrong) {
    return LinkQuality.excellent;
  } else if (rssi >= LoRaConstants.rssiGood && snr >= LoRaConstants.snrModerate) {
    return LinkQuality.good;
  } else if (rssi >= LoRaConstants.rssiFair && snr >= LoRaConstants.snrPoor) {
    return LinkQuality.fair;
  } else if (rssi >= LoRaConstants.rssiPoor) {
    return LinkQuality.poor;
  } else {
    return LinkQuality.critical;
  }
}
