import 'package:falconet/src/network/base/http/http_redirect_record.dart';

class HttpResponse<T> {
  const HttpResponse({
    required this.data,
    required this.statusCode,
    this.statusMessage,
    this.headers = const {},
    this.isRedirect = false,
    this.redirects = const [],
    this.extra = const {},
    this.requestUri,
  });

  final T? data;
  final int statusCode;
  final String? statusMessage;
  final Map<String, List<String>> headers;
  final bool isRedirect;
  final List<HttpRedirectRecord> redirects;
  final Map<String, dynamic> extra;
  final Uri? requestUri;

  /// Final URI after redirects, when available.
  Uri? get realUri =>
      redirects.isNotEmpty ? redirects.last.location : requestUri;
}
