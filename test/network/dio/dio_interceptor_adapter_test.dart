import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:falconet/falconet.dart';
import 'package:falconet/src/network/dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/falconet_mocks.dart';

void main() {
  late Dio dio;

  setUp(() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://example.com',
        validateStatus: (_) => true,
      ),
    );
  });

  group('DioInterceptorAdapter', () {
    group('onRequest()', () {
      test('forwards a mutated path when the interceptor updates it', () async {
        late String seenPath;
        dio.httpClientAdapter = _RecordingAdapter(
          onFetch: (options) => seenPath = options.path,
        );
        dio.interceptors.add(
          DioInterceptorAdapter(
            FakeHttpInterceptor(
              onRequestCallback: (context) async {
                context.path = '/rewritten';
              },
            ),
            clientOptions: const HttpClientOptions(),
          ),
        );

        await dio.get<Map<String, dynamic>>('/original');

        expect(seenPath, '/rewritten');
      });

      test('rejects the request when the interceptor throws', () async {
        dio.httpClientAdapter = const _OkAdapter();
        dio.interceptors.add(
          DioInterceptorAdapter(
            FakeHttpInterceptor(
              onRequestCallback: (_) async {
                throw StateError('blocked');
              },
            ),
            clientOptions: const HttpClientOptions(),
          ),
        );

        await expectLater(
          dio.get<Map<String, dynamic>>('/users'),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('onResponse()', () {
      test('writes interceptor response changes back to Dio', () async {
        dio.httpClientAdapter = const _OkAdapter();
        dio.interceptors.add(
          DioInterceptorAdapter(
            FakeHttpInterceptor(
              onResponseCallback: (context) async {
                context.response = const HttpResponse<Map<String, dynamic>>(
                  data: {'rewritten': true},
                  statusCode: 201,
                );
              },
            ),
            clientOptions: const HttpClientOptions(),
          ),
        );

        final response = await dio.get<Map<String, dynamic>>('/users');

        expect(response.statusCode, 201);
        expect(response.data, const {'rewritten': true});
      });

      test('rejects the response when the interceptor throws', () async {
        dio.httpClientAdapter = const _OkAdapter();
        dio.interceptors.add(
          DioInterceptorAdapter(
            FakeHttpInterceptor(
              onResponseCallback: (_) async {
                throw StateError('bad response');
              },
            ),
            clientOptions: const HttpClientOptions(),
          ),
        );

        await expectLater(
          dio.get<Map<String, dynamic>>('/users'),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('onError()', () {
      test(
        'forwards a DioException when context.error is a DioException',
        () async {
          final replacement = DioException(
            requestOptions: RequestOptions(path: '/users'),
            message: 'replaced',
          );
          dio.httpClientAdapter = const _ThrowingAdapter(
            message: 'original',
          );
          dio.interceptors.add(
            DioInterceptorAdapter(
              FakeHttpInterceptor(
                onErrorCallback: (context) async {
                  context.error = replacement;
                },
              ),
              clientOptions: const HttpClientOptions(),
            ),
          );

          await expectLater(
            dio.get<Map<String, dynamic>>('/users'),
            throwsA(
              isA<DioException>().having(
                (e) => e.message,
                'message',
                'replaced',
              ),
            ),
          );
        },
      );

      test(
        'rejects with a wrapped error when context.error is other',
        () async {
          dio.httpClientAdapter = const _ThrowingAdapter();
          dio.interceptors.add(
            DioInterceptorAdapter(
              FakeHttpInterceptor(
                onErrorCallback: (context) async {
                  context.error = StateError('mapped');
                },
              ),
              clientOptions: const HttpClientOptions(),
            ),
          );

          await expectLater(
            dio.get<Map<String, dynamic>>('/users'),
            throwsA(
              isA<DioException>().having(
                (e) => e.error,
                'error',
                isA<StateError>(),
              ),
            ),
          );
        },
      );

      test(
        'forwards the original error when context.error is cleared',
        () async {
          dio.httpClientAdapter = const _ThrowingAdapter(message: 'original');
          dio.interceptors.add(
            DioInterceptorAdapter(
              FakeHttpInterceptor(
                onErrorCallback: (context) async {
                  context.error = null;
                },
              ),
              clientOptions: const HttpClientOptions(),
            ),
          );

          await expectLater(
            dio.get<Map<String, dynamic>>('/users'),
            throwsA(
              isA<DioException>().having(
                (e) => e.message,
                'message',
                'original',
              ),
            ),
          );
        },
      );

      test('rejects when the interceptor onError throws', () async {
        dio.httpClientAdapter = const _ThrowingAdapter();
        dio.interceptors.add(
          DioInterceptorAdapter(
            FakeHttpInterceptor(
              onErrorCallback: (_) async {
                throw StateError('onError failed');
              },
            ),
            clientOptions: const HttpClientOptions(),
          ),
        );

        await expectLater(
          dio.get<Map<String, dynamic>>('/users'),
          throwsA(
            isA<DioException>().having(
              (e) => e.error,
              'error',
              isA<StateError>(),
            ),
          ),
        );
      });
    });
  });
}

class _OkAdapter implements HttpClientAdapter {
  const _OkAdapter();

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({required this.onFetch});

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

class _ThrowingAdapter implements HttpClientAdapter {
  const _ThrowingAdapter({this.message});

  final String? message;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      message: message,
    );
  }
}
