import 'package:falconet/falconet.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpErrorMapper extends Mock implements HttpErrorMapper {}

class MockApiVersionStrategy extends Mock implements ApiVersionStrategy {}

class MockHttpInterceptor extends Mock implements HttpInterceptor {}

class MockHttpCancelToken extends Mock implements HttpCancelToken {}

class MockBootstrap extends Mock implements Bootstrap {}

class MockNativeSplashAdapter extends Mock implements NativeSplashAdapter {}

class FakeHttpInterceptor extends HttpInterceptor {
  FakeHttpInterceptor({
    this.onRequestCallback,
    this.onResponseCallback,
    this.onErrorCallback,
  });

  Future<void> Function(HttpInterceptorContext context)? onRequestCallback;
  Future<void> Function(HttpInterceptorContext context)? onResponseCallback;
  Future<void> Function(HttpInterceptorContext context)? onErrorCallback;

  @override
  Future<void> onRequest(HttpInterceptorContext context) async {
    await onRequestCallback?.call(context);
  }

  @override
  Future<void> onResponse(HttpInterceptorContext context) async {
    await onResponseCallback?.call(context);
  }

  @override
  Future<void> onError(HttpInterceptorContext context) async {
    await onErrorCallback?.call(context);
  }
}

void registerFalconetFallbackValues() {
  registerFallbackValue(const HttpRequestOptions());
  registerFallbackValue(StackTrace.empty);
  registerFallbackValue(
    HttpInterceptorContext(
      path: '/',
      options: const HttpRequestOptions(),
    ),
  );
  registerFallbackValue(Injector(GetIt.asNewInstance()));
}
