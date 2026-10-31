import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/security/encryption_service.dart';

void main() {
  group('EncryptionService - AES-256-GCM & HMAC-SHA256', () {
    late EncryptionService encryptionService;

    setUp(() {
      encryptionService = EncryptionService();
      encryptionService.initKey('DMESH-TACTICAL-KEY-TEST-2026');
    });

    test('should encrypt and successfully decrypt message payload', () {
      const plaintext = 'Tactical Alert: Evacuation Team en route to Sector B-4';
      final encrypted = encryptionService.encryptPayload(plaintext);

      expect(encrypted, isNotEmpty);
      expect(encrypted, contains(':')); // IV:Ciphertext format

      final decrypted = encryptionService.decryptPayload(encrypted);
      expect(decrypted, equals(plaintext));
    });

    test('should generate and verify valid HMAC-SHA256 signature', () {
      const message = 'NODE-001:GPS:19.9975,73.7898:BAT:95';
      const secret = 'SHARED-TACTICAL-SECRET';

      final signature = encryptionService.signMessage(message, secret);
      expect(signature, isNotEmpty);

      final isValid = encryptionService.verifySignature(message, signature, secret);
      expect(isValid, isTrue);

      // Verify tampered message fails
      final isTamperedValid = encryptionService.verifySignature(
        'NODE-001:GPS:19.9975,73.7898:BAT:20', // tampered battery
        signature,
        secret,
      );
      expect(isTamperedValid, isFalse);
    });

    test('should fail decryption when ciphertext is tampered', () {
      const plaintext = 'Sensitive emergency coordinates';
      final encrypted = encryptionService.encryptPayload(plaintext);
      final parts = encrypted.split(':');

      // Tamper ciphertext
      final tamperedCiphertext = '${parts[0]}:corruptedbase64payload==';

      expect(
        () => encryptionService.decryptPayload(tamperedCiphertext),
        throwsA(isA<Exception>()),
      );
    });
  });
}

