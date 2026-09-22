import 'dart:async';

import 'package:falconet/src/network/base/http/http_request_options.dart';
import 'package:falconet/src/network/base/http/http_response_body.dart';

/// How response data should be transformed.
enum HttpResponseType {
  json,
  plain,
  bytes,
  stream,
}

/// How list query parameters are serialized.
enum HttpListFormat {
  csv,
  ssv,
  tsv,
  pipes,
  multi,
  multiCompatible,
}

/// Validates whether an HTTP status code is treated as success.
typedef HttpStatusValidator = bool Function(int? status);

/// Progress callback for upload/download.
typedef HttpProgressCallback = void Function(int count, int total);

/// Encodes a request body string before sending.
typedef HttpRequestEncoder =
    FutureOr<List<int>> Function(
      String request,
      ResolvedHttpRequestOptions options,
    );

/// Decodes raw response bytes before transformation.
typedef HttpResponseDecoder =
    FutureOr<String?> Function(
      List<int> responseBytes,
      ResolvedHttpRequestOptions options, {
      HttpResponseBody? responseBody,
    });

/// Accepts every status so non-2xx responses reach the error mapper.
bool httpAcceptAllStatuses(int? status) => true;

/// Default success range (2xx).
bool httpDefaultValidateStatus(int? status) {
  return status != null && status >= 200 && status < 300;
}
