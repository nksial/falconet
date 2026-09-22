class HttpException implements Exception {
  const HttpException(
    this.message, {
    this.statusCode,
    this.type,
    this.code,
    this.rawBody,
  });

  final String message;
  final int? statusCode;

  /// UX category string set by the app's error mapper (e.g. `unauthorized`).
  final String? type;

  /// Stable id for localization set by the app's error mapper / API body.
  final String? code;

  final Object? rawBody;

  @override
  String toString() => message;
}

class HttpResponseException implements Exception {
  HttpResponseException({
    required this.statusCode,
    required this.rawBody,
  });

  final int statusCode;
  final Object? rawBody;
}
