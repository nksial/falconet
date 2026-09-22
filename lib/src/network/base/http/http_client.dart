import 'package:falconet/src/network/base/http/http_multipart_file.dart';
import 'package:falconet/src/network/base/http/http_request_options.dart';
import 'package:falconet/src/network/base/http/http_response.dart';
import 'package:falconet/src/network/base/http/http_response_body.dart';
import 'package:falconet/src/network/base/http/http_types.dart';
import 'package:falconet/src/network/base/interceptor/interceptor.dart';

abstract class HttpClient {
  Future<HttpResponse<T>> get<T>(
    String path, {
    HttpRequestOptions? options,
  });

  Future<HttpResponse<T>> post<T>(
    String path, {
    Object? body,
    HttpRequestOptions? options,
  });

  Future<HttpResponse<T>> put<T>(
    String path, {
    Object? body,
    HttpRequestOptions? options,
  });

  Future<HttpResponse<T>> patch<T>(
    String path, {
    Object? body,
    HttpRequestOptions? options,
  });

  Future<HttpResponse<T>> delete<T>(
    String path, {
    Object? body,
    HttpRequestOptions? options,
  });

  Future<HttpResponse<T>> upload<T>(
    String path, {
    Map<String, dynamic>? fields,
    List<HttpMultipartFile>? files,
    HttpRequestOptions? options,
  });

  Future<HttpResponse<List<int>>> download(
    String path, {
    String? savePath,
    HttpRequestOptions? options,
  });

  /// Raw streaming response — use with [HttpResponseType.stream].
  Future<HttpResponse<HttpResponseBody>> getStream(
    String path, {
    HttpRequestOptions? options,
  });

  /// Plain-text response — use with [HttpResponseType.plain].
  Future<HttpResponse<String>> getPlain(
    String path, {
    HttpRequestOptions? options,
  });

  void addInterceptor(HttpInterceptor interceptor);

  void removeInterceptor(HttpInterceptor interceptor);
}

/// JSON map response shorthand for REST endpoints.
typedef JsonHttpResponse = HttpResponse<Map<String, dynamic>>;
