class SydleException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic raw;

  const SydleException(this.message, {this.statusCode, this.raw});

  @override
  String toString() => 'SydleException($statusCode): $message';
}

class SydleAuthException extends SydleException {
  const SydleAuthException(super.message);
}

class SydleNotFoundException extends SydleException {
  const SydleNotFoundException(super.message);
}