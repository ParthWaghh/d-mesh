import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptionService {
  static const String defaultEmergencySalt = 'D_MESH_TACTICAL_SALT_2026';
  
  // 32-byte (256-bit) default pre-shared emergency key
  static const String fallbackPsk = 'DMESH-DISASTER-RESILIENCE-KEY-256';

  late enc.Encrypter _encrypter;
  late enc.Key _key;
  bool _isInitialized = false;

  EncryptionService() {
    initKey(fallbackPsk);
  }

  /// Initializes AES-256-GCM key derived from passphrase
  void initKey(String passphrase) {
    final keyBytes = sha256.convert(utf8.encode(passphrase + defaultEmergencySalt)).bytes;
    _key = enc.Key(Uint8List.fromList(keyBytes));
    // AESMode.gcm or AESMode.cbc (GCM supported in encrypt package)
    _encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.gcm));
    _isInitialized = true;
  }

  /// Encrypts plaintext string to Base64 IV + Ciphertext
  String encryptPayload(String plaintext) {
    if (!_isInitialized) initKey(fallbackPsk);
    try {
      // 12-byte IV for GCM
      final iv = enc.IV.fromSecureRandom(12);
      final encrypted = _encrypter.encrypt(plaintext, iv: iv);
      // Combine IV (Base64) + ":" + Ciphertext (Base64)
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      // Fallback or rethrow
      throw Exception('Encryption failed: $e');
    }
  }

  /// Decrypts payload from formatted Base64 string
  String decryptPayload(String encryptedPayload) {
    if (!_isInitialized) initKey(fallbackPsk);
    try {
      final parts = encryptedPayload.split(':');
      if (parts.length != 2) {
        throw const FormatException('Invalid encrypted payload format');
      }
      final iv = enc.IV.fromBase64(parts[0]);
      final encrypted = enc.Encrypted.fromBase64(parts[1]);
      return _encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Generates HMAC-SHA256 signature for message authentication
  String signMessage(String message, String secretKey) {
    final hmac = Hmac(sha256, utf8.encode(secretKey));
    final digest = hmac.convert(utf8.encode(message));
    return digest.toString();
  }

  /// Verifies message authenticity against signature
  bool verifySignature(String message, String signature, String secretKey) {
    final expectedSig = signMessage(message, secretKey);
    return expectedSig == signature;
  }
}

