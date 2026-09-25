import 'package:falconet/src/network/base/http/http.dart';

class HttpInterceptorContext {
  HttpInterceptorContext({
    required this.path,
    required this.options,
    this.response,
    this.error,
    this.retryRequest = false,
  });

  String path;
  HttpRequestOptions options;
  HttpResponse<dynamic>? response;
  Object? error;

  /// When set in [HttpInterceptor.onError], the Dio adapter re-dispatches
  /// the (possibly mutated) request via `dio.fetch` and resolves the error
  /// chain with that response.
  bool retryRequest;
}

abstract class HttpInterceptor {
  Future<void> onRequest(HttpInterceptorContext context) async {}

  Future<void> onResponse(HttpInterceptorContext context) async {}

  Future<void> onError(HttpInterceptorContext context) async {}
}
