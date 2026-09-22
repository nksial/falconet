import 'dart:io';

import 'package:dio/dio.dart';
import 'package:falconet/falconet.dart';
import 'package:falconet/src/network/dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/falconet_mocks.dart';
import '../../helpers/http_test_support.dart';

void main() {
  late MockHttpErrorMapper errorMapper;

  setUpAll(registerFalconetFallbackValues);

  setUp(() {
    errorMapper = MockHttpErrorMapper();
    when(
      () => errorMapper.map(any(), stackTrace: any(named: 'stackTrace')),
    ).thenAnswer((invocation) {
      final error = invocation.positionalArguments.first;
      if (error is HttpException) return error;
      if (error is HttpResponseException) {
        return HttpException(
          'mapped ${error.statusCode}',
          statusCode: error.statusCode,
          rawBody: error.rawBody,
        );
      }
      return HttpException(error.toString());
    });
  });

  DioClient buildClient({
    required Dio dio,
    HttpClientOptions clientOptions = const HttpClientOptions(),
    ApiVersionStrategy? versionStrategy,
    String? apiVersion,
  }) {
    return buildDioClient(
      dio: dio,
      clientOptions: clientOptions,
      errorMapper: errorMapper,
      versionStrategy: versionStrategy,
      apiVersion: apiVersion,
    );
  }

  group('DioClient', () {
    group('get()', () {
      test('returns decoded JSON when the response is successful', () async {
        final client = buildClient(dio: buildStubbedDio());

        final response = await client.get<Map<String, dynamic>>('/users/1');

        expect(response.statusCode, 200);
        expect(response.data, const {'ok': true});
      });

      test('leaves path unchanged when version strategy is null', () async {
        late String seenPath;
        final dio = buildStubbedDio(
          onRequest: (options, handler) {
            seenPath = options.path;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: const {'ok': true},
              ),
            );
          },
        );
        final client = buildClient(
          dio: dio,
          clientOptions: const HttpClientOptions(apiVersion: '1'),
          apiVersion: '1',
        );

        await client.get<Map<String, dynamic>>('/users/1');

        expect(seenPath, '/users/1');
      });

      test('applies the versioned path when a strategy is set', () async {
        late String seenPath;
        final strategy = MockApiVersionStrategy();
        when(
          () => strategy.apply(
            path: any(named: 'path'),
            options: any(named: 'options'),
            apiVersion: any(named: 'apiVersion'),
          ),
        ).thenReturn(
          const ApiVersionResult(
            path: '/v1/users/1',
            options: HttpRequestOptions(),
          ),
        );
        final dio = buildStubbedDio(
          onRequest: (options, handler) {
            seenPath = options.path;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: const {'ok': true},
              ),
            );
          },
        );
        final client = buildClient(
          dio: dio,
          versionStrategy: strategy,
          apiVersion: '1',
        );

        await client.get<Map<String, dynamic>>('/users/1');

        expect(seenPath, '/v1/users/1');
        verify(
          () => strategy.apply(
            path: '/users/1',
            options: any(named: 'options'),
            apiVersion: '1',
          ),
        ).called(1);
      });

      test('supports request cancellation when a token is provided', () async {
        late CancelToken? seenToken;
        final token = DioCancelToken();
        final dio = buildStubbedDio(
          onRequest: (options, handler) {
            seenToken = options.cancelToken;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: const {'cancelled': false},
              ),
            );
          },
        );
        final client = buildClient(dio: dio);

        await client.get<Map<String, dynamic>>(
          '/users/1',
          options: HttpRequestOptions(cancelToken: token),
        );

        expect(seenToken, same(token.dioToken));
      });

      test('maps non-2xx responses to HttpException', () async {
        final client = buildClient(
          dio: buildStubbedDio(
            statusCode: 400,
            data: const {'message': 'Bad request'},
          ),
        );

        expect(
          () => client.get<Map<String, dynamic>>('/users/1'),
          throwsA(
            isA<HttpException>()
                .having((e) => e.message, 'message', 'mapped 400')
                .having((e) => e.statusCode, 'statusCode', 400),
          ),
        );
      });

      test('maps transport errors through the error mapper', () async {
        final dio = buildStubbedDio(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionTimeout,
              ),
            );
          },
        );
        final client = buildClient(dio: dio);

        await expectLater(
          client.get<Map<String, dynamic>>('/users/1'),
          throwsA(isA<HttpException>()),
        );
        verify(
          () => errorMapper.map(any(), stackTrace: any(named: 'stackTrace')),
        ).called(1);
      });
    });

    group('getPlain()', () {
      test('returns plain text when the response is a string', () async {
        final client = buildClient(dio: buildStubbedDio(data: 'hello'));

        final response = await client.getPlain('/health');

        expect(response.data, 'hello');
      });
    });

    group('getStream()', () {
      test('returns a stream body when Dio yields a ResponseBody', () async {
        final body = ResponseBody.fromBytes([1, 2], 200);
        final dio = buildStubbedDio(
          onRequest: (options, handler) {
            handler.resolve(
              Response<ResponseBody>(
                requestOptions: options,
                statusCode: 200,
                data: body,
              ),
            );
          },
        );
        final client = buildClient(dio: dio);

        final response = await client.getStream('/events');

        expect(response.data, isA<HttpResponseBody>());
        expect(response.data!.statusCode, 200);
      });
    });

    group('post()', () {
      test('sends an empty map when body is omitted', () async {
        late Object? seenBody;
        final dio = buildStubbedDio(
          onRequest: (options, handler) {
            seenBody = options.data;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 201,
                data: const {'created': true},
              ),
            );
          },
        );
        final client = buildClient(dio: dio);

        final response = await client.post<Map<String, dynamic>>('/users');

        expect(seenBody, const <String, dynamic>{});
        expect(response.statusCode, 201);
      });

      test('sends the provided body when one is passed', () async {
        late Object? seenBody;
        final dio = buildStubbedDio(
          onRequest: (options, handler) {
            seenBody = options.data;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: const {'ok': true},
              ),
            );
          },
        );
        final client = buildClient(dio: dio);

        await client.post<Map<String, dynamic>>(
          '/users',
          body: const {'name': 'Ada'},
        );

        expect(seenBody, const {'name': 'Ada'});
      });
    });

    group('put()', () {
      test('returns the mapped response when the request succeeds', () async {
        final client = buildClient(dio: buildStubbedDio());

        final response = await client.put<Map<String, dynamic>>(
          '/users/1',
          body: const {'name': 'Ada'},
        );

        expect(response.statusCode, 200);
        expect(response.data, const {'ok': true});
      });
    });

    group('patch()', () {
      test('returns the mapped response when the request succeeds', () async {
        final client = buildClient(dio: buildStubbedDio());

        final response = await client.patch<Map<String, dynamic>>(
          '/users/1',
          body: const {'name': 'Ada'},
        );

        expect(response.statusCode, 200);
      });
    });

    group('delete()', () {
      test('returns the mapped response when the request succeeds', () async {
        final client = buildClient(dio: buildStubbedDio(statusCode: 204));

        final response = await client.delete<void>('/users/1');

        expect(response.statusCode, 204);
      });
    });

    group('download()', () {
      test('returns bytes when savePath is omitted', () async {
        final client = buildClient(
          dio: buildStubbedDio(data: <int>[1, 2, 3]),
        );

        final response = await client.download('/file.bin');

        expect(response.data, [1, 2, 3]);
      });

      test(
        'writes an empty successful response when savePath is set',
        () async {
          final directory = await Directory.systemTemp.createTemp(
            'falconet_download_',
          );
          addTearDown(() => directory.delete(recursive: true));
          final savePath = '${directory.path}/out.bin';
          final client = buildClient(
            dio: buildStubbedDio(
              onRequest: (options, handler) {
                handler.resolve(
                  Response<ResponseBody>(
                    requestOptions: options,
                    statusCode: 200,
                    data: ResponseBody.fromBytes([9, 8, 7], 200),
                  ),
                );
              },
            ),
          );

          final response = await client.download(
            '/file.bin',
            savePath: savePath,
          );

          expect(response.statusCode, 200);
          expect(response.data, isEmpty);
        },
      );
    });

    group('upload()', () {
      test('posts multipart bytes when files include byte payloads', () async {
        late Object? seenBody;
        final dio = buildStubbedDio(
          onRequest: (options, handler) {
            seenBody = options.data;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: const {'ok': true},
              ),
            );
          },
        );
        final client = buildClient(dio: dio);

        await client.upload<Map<String, dynamic>>(
          '/upload',
          fields: const {'kind': 'avatar'},
          files: const [
            HttpMultipartFile(
              field: 'file',
              filename: 'a.png',
              bytes: [1, 2, 3],
              contentType: 'image/png',
            ),
          ],
        );

        expect(seenBody, isA<FormData>());
      });

      test('posts a stream file when bytes are omitted', () async {
        final dio = buildStubbedDio();
        final client = buildClient(dio: dio);

        final response = await client.upload<Map<String, dynamic>>(
          '/upload',
          files: [
            HttpMultipartFile(
              field: 'file',
              filename: 'a.bin',
              stream: Stream.value([4, 5]),
              contentType: 'application/octet-stream',
            ),
          ],
        );

        expect(response.statusCode, 200);
      });

      test('posts fields only when files are omitted', () async {
        final client = buildClient(dio: buildStubbedDio());

        final response = await client.upload<Map<String, dynamic>>(
          '/upload',
          fields: const {'kind': 'none'},
        );

        expect(response.statusCode, 200);
      });
    });

    group('addInterceptor()', () {
      test('invokes the interceptor on the next request', () async {
        var requestSeen = false;
        final dio = Dio(
          BaseOptions(
            baseUrl: 'https://example.com',
            validateStatus: (_) => true,
          ),
        );
        final client = buildClient(dio: dio)
          ..addInterceptor(
            FakeHttpInterceptor(
              onRequestCallback: (_) async => requestSeen = true,
            ),
          );
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: const {'ok': true},
                ),
              );
            },
          ),
        );

        await client.get<Map<String, dynamic>>('/users');

        expect(requestSeen, isTrue);
      });
    });

    group('removeInterceptor()', () {
      test('stops invoking the interceptor after it is removed', () async {
        var requestSeen = false;
        final interceptor = FakeHttpInterceptor(
          onRequestCallback: (_) async => requestSeen = true,
        );
        final client = buildClient(dio: buildStubbedDio())
          ..addInterceptor(interceptor)
          ..removeInterceptor(interceptor);
        await client.get<Map<String, dynamic>>('/users');

        expect(requestSeen, isFalse);
      });

      test('throws StateError when the interceptor was never added', () {
        final client = buildClient(dio: buildStubbedDio());

        expect(
          () => client.removeInterceptor(FakeHttpInterceptor()),
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}
