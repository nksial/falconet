import 'package:falconet/src/network/base/http/http.dart';

class HttpInterceptorContext {
  HttpInterceptorContext({
    required this.path,
    required this.options,
    this.response,
    this.error,
  });

  String path;
  HttpRequestOptions options;
  HttpResponse<dynamic>? response;
  Object? error;
}

abstract class HttpInterceptor {
  Future<void> onRequest(HttpInterceptorContext context) async {}

  Future<void> onResponse(HttpInterceptorContext context) async {}

  Future<void> onError(HttpInterceptorContext context) async {}
}
