abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => '$runtimeType: $message (code: $code)';
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

class HardwareFailure extends Failure {
  const HardwareFailure(super.message, {super.code});
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code});
}

class EncryptionFailure extends Failure {
  const EncryptionFailure(super.message, {super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

