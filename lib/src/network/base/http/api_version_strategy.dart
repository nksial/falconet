import 'package:falconet/src/network/base/http/http_client.dart';
import 'package:falconet/src/network/base/http/http_request_options.dart';

/// Applies API versioning to outgoing requests when provided to [HttpClient].
///
/// When the strategy is null, or `apiVersion` is null or empty, the request is
/// left unchanged.
abstract class ApiVersionStrategy {
  const ApiVersionStrategy();

  ApiVersionResult apply({
    required String path,
    required HttpRequestOptions options,
    required String? apiVersion,
  });
}

class ApiVersionResult {
  const ApiVersionResult({
    required this.path,
    required this.options,
  });

  final String path;
  final HttpRequestOptions options;
}
