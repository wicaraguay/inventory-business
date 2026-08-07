/// Raised when a business rule is violated. Adapters translate it to HTTP 400.
class DomainException implements Exception {
  DomainException(this.message);
  final String message;

  @override
  String toString() => 'DomainException: $message';
}
