class GeocodingException implements Exception {
  final String technicalMessage;
  final String userMessage;
  final int? statusCode;
  final bool retryable;

  GeocodingException({
    required this.technicalMessage,
    required this.userMessage,
    this.statusCode,
    this.retryable = true,
  });

  @override
  String toString() => userMessage;
}

class RouteException implements Exception {
  final String technicalMessage;
  final String userMessage;
  final int? statusCode;
  final bool retryable;

  RouteException({
    required this.technicalMessage,
    required this.userMessage,
    this.statusCode,
    this.retryable = true,
  });

  @override
  String toString() => userMessage;
}
