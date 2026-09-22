/// Raw streaming response body.
class HttpResponseBody {
  const HttpResponseBody({
    required this.stream,
    this.statusCode,
    this.headers = const {},
    this.contentLength,
  });

  final Stream<List<int>> stream;
  final int? statusCode;
  final Map<String, List<String>> headers;
  final int? contentLength;
}
