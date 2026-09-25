import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:falconet/falconet.dart';
import 'package:falconet/src/network/dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<String?> captureContentType({
    required HttpInterceptor interceptor,
  }) async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    String? seenContentType;
    dio.httpClientAdapter = _Adapter((options) {
      seenContentType = options.contentType;
    });
    dio.interceptors.add(
      DioInterceptorAdapter(
        interceptor,
        dio: dio,
        clientOptions: const HttpClientOptions(),
      ),
    );
    await dio.post<Map<String, dynamic>>(
      '/login',
      data: <String, dynamic>{
        'store_code': 'a',
        'device_code': 'b',
        'pin': 'c',
      },
    );
    return seenContentType;
  }

  test('noop interceptor keeps ImplyContentType JSON content type', () async {
    final contentType = await captureContentType(
      interceptor: _NoopInterceptor(),
    );
    expect(contentType, Headers.jsonContentType);
  });

  test('header-rewriting interceptor keeps JSON content type', () async {
    final contentType = await captureContentType(
      interceptor: _HeaderRewriteInterceptor(),
    );
    expect(contentType, Headers.jsonContentType);
  });

  test('interceptor can remove Authorization via header replace', () async {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://example.com',
        headers: const {'Authorization': 'Bearer stale'},
      ),
    );
    Map<String, dynamic>? seenHeaders;
    dio.httpClientAdapter = _Adapter((options) {
      seenHeaders = Map<String, dynamic>.from(options.headers);
    });
    dio.interceptors.add(
      DioInterceptorAdapter(
        _RemoveAuthInterceptor(),
        dio: dio,
        clientOptions: const HttpClientOptions(
          defaultHeaders: {'Authorization': 'Bearer stale'},
        ),
      ),
    );

    await dio.get<Map<String, dynamic>>('/public');

    expect(seenHeaders?.containsKey('Authorization'), isFalse);
  });
}

class _NoopInterceptor extends HttpInterceptor {
  @override
  Future<void> onRequest(HttpInterceptorContext context) async {}
}

class _HeaderRewriteInterceptor extends HttpInterceptor {
  @override
  Future<void> onRequest(HttpInterceptorContext context) async {
    context.options = context.options.copyWith(
      headers: {
        ...?context.options.headers,
        'Authorization': 'Bearer x',
      },
    );
  }
}

class _RemoveAuthInterceptor extends HttpInterceptor {
  @override
  Future<void> onRequest(HttpInterceptorContext context) async {
    final headers = Map<String, dynamic>.from(context.options.headers ?? {});
    headers.remove('Authorization');
    context.options = context.options.copyWith(headers: headers);
  }
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.onFetch);

  final void Function(RequestOptions options) onFetch;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onFetch(options);
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
