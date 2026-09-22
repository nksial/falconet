/// A single redirect hop in a response chain.
class HttpRedirectRecord {
  const HttpRedirectRecord({
    required this.statusCode,
    required this.method,
    required this.location,
  });

  final int statusCode;
  final String method;
  final Uri location;
}
