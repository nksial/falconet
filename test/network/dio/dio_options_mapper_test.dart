import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:falconet/falconet.dart';
import 'package:falconet/src/network/dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/http_test_support.dart';

void main() {
  group('toDioBaseOptions()', () {
    test('copies client options onto Dio BaseOptions', () {
      const options = HttpClientOptions(
        baseUrl: 'https://example.com',
        connectTimeout: Duration(seconds: 1),
        receiveTimeout: Duration(seconds: 2),
        sendTimeout: Duration(seconds: 3),
        transformTimeout: Duration(seconds: 4),
        defaultQueryParameters: {'q': 1},
        defaultHeaders: {'X-App': '1'},
        responseType: HttpResponseType.plain,
        contentType: 'text/plain',
        receiveDataWhenStatusError: false,
        followRedirects: false,
        maxRedirects: 2,
        persistentConnection: false,
        listFormat: HttpListFormat.csv,
        preserveHeaderCase: true,
        extra: {'trace': 'abc'},
      );

      final mapped = toDioBaseOptions(options: options);

      expect(mapped.baseUrl, 'https://example.com');
      expect(mapped.connectTimeout, const Duration(seconds: 1));
      expect(mapped.responseType, ResponseType.plain);
      expect(mapped.listFormat, ListFormat.csv);
      expect(mapped.extra['trace'], 'abc');
    });

    test('wraps a request encoder when one is provided', () async {
      final mapped = toDioBaseOptions(
        options: HttpClientOptions(
          requestEncoder: (request, options) => [1, 2, 3],
        ),
      );

      final encoded = await mapped.requestEncoder!(
        'body',
        RequestOptions(path: '/'),
      );

      expect(encoded, [1, 2, 3]);
    });

    test('wraps a response decoder when one is provided', () async {
      final mapped = toDioBaseOptions(
        options: HttpClientOptions(
          responseDecoder: (bytes, options, {responseBody}) => 'decoded',
        ),
      );
      final body = ResponseBody.fromString('raw', 200);

      final decoded = await mapped.responseDecoder!(
        Uint8List.fromList([1]),
        RequestOptions(path: '/'),
        body,
      );

      expect(decoded, 'decoded');
    });
  });

  group('toDioOptions()', () {
    test('maps every HttpResponseType to the Dio equivalent', () {
      expect(
        toDioOptions(resolvedOptions()).responseType,
        ResponseType.json,
      );
      expect(
        toDioOptions(
          resolvedOptions(responseType: HttpResponseType.plain),
        ).responseType,
        ResponseType.plain,
      );
      expect(
        toDioOptions(
          resolvedOptions(responseType: HttpResponseType.bytes),
        ).responseType,
        ResponseType.bytes,
      );
      expect(
        toDioOptions(
          resolvedOptions(responseType: HttpResponseType.stream),
        ).responseType,
        ResponseType.stream,
      );
    });

    test('maps every HttpListFormat to the Dio equivalent', () {
      expect(
        toDioOptions(
          resolvedOptions(listFormat: HttpListFormat.csv),
        ).listFormat,
        ListFormat.csv,
      );
      expect(
        toDioOptions(
          resolvedOptions(listFormat: HttpListFormat.ssv),
        ).listFormat,
        ListFormat.ssv,
      );
      expect(
        toDioOptions(
          resolvedOptions(listFormat: HttpListFormat.tsv),
        ).listFormat,
        ListFormat.tsv,
      );
      expect(
        toDioOptions(
          resolvedOptions(listFormat: HttpListFormat.pipes),
        ).listFormat,
        ListFormat.pipes,
      );
      expect(
        toDioOptions(resolvedOptions()).listFormat,
        ListFormat.multi,
      );
      expect(
        toDioOptions(
          resolvedOptions(listFormat: HttpListFormat.multiCompatible),
        ).listFormat,
        ListFormat.multiCompatible,
      );
    });

    test('uses contentType field and strips Content-Type from headers', () {
      final mapped = toDioOptions(
        resolvedOptions(
          headers: {
            Headers.contentTypeHeader: 'text/plain',
            'X-App': '1',
          },
          contentType: Headers.jsonContentType,
        ),
      );

      expect(mapped.contentType, Headers.jsonContentType);
      expect(mapped.headers, isNot(contains(Headers.contentTypeHeader)));
      expect(mapped.headers?['X-App'], '1');
    });
  });

  group('applyResolvedOptionsToRequest()', () {
    test('applies progress callbacks when they are set', () {
      var receiveCalled = false;
      final request = RequestOptions(path: '/test');
      final resolved =
          const HttpRequestOptions(
                onReceiveProgress: _noopProgress,
              )
              .resolve(const HttpClientOptions())
              .copyWith(
                onReceiveProgress: (_, _) => receiveCalled = true,
              );

      applyResolvedOptionsToRequest(request, resolved);
      request.onReceiveProgress?.call(1, 10);

      expect(receiveCalled, isTrue);
    });

    test('copies headers, query, extra, and cancel token', () {
      final token = DioCancelToken();
      final request = RequestOptions(path: '/test');
      final resolved = resolvedOptions(
        headers: {'X-App': '1'},
        queryParameters: {'page': 2},
        extra: {'trace': 'z'},
        cancelToken: token,
        contentType: 'application/json',
      );

      applyResolvedOptionsToRequest(request, resolved);

      expect(request.headers['X-App'], '1');
      expect(request.queryParameters['page'], 2);
      expect(request.extra['trace'], 'z');
      expect(request.cancelToken, same(token.dioToken));
      expect(request.contentType, 'application/json');
    });

    test('does not clear existing contentType when resolved omits it', () {
      final request = RequestOptions(
        path: '/login',
        contentType: Headers.jsonContentType,
      );
      final resolved = const HttpRequestOptions().resolve(
        const HttpClientOptions(),
      );

      applyResolvedOptionsToRequest(request, resolved);

      expect(request.contentType, Headers.jsonContentType);
    });

    test('replaces headers so removals take effect', () {
      final request = RequestOptions(
        path: '/secure',
        headers: const {
          'Authorization': 'Bearer old',
          'X-App': '1',
        },
      );
      final resolved = resolvedOptions(
        headers: const {'X-App': '1'},
      );

      applyResolvedOptionsToRequest(request, resolved);

      expect(request.headers.containsKey('Authorization'), isFalse);
      expect(request.headers['X-App'], '1');
    });
  });

  group('fromDioRequestOptions()', () {
    test('round-trips Dio request fields onto HttpRequestOptions', () {
      final token = CancelToken();
      final request = RequestOptions(
        path: '/users',
        headers: {'X-App': '1'},
        queryParameters: {'q': 1},
        connectTimeout: const Duration(seconds: 1),
        responseType: ResponseType.bytes,
        listFormat: ListFormat.pipes,
        cancelToken: token,
        extra: {'k': 'v'},
      );

      final mapped = fromDioRequestOptions(request);

      expect(mapped.headers, containsPair('X-App', '1'));
      expect(mapped.queryParameters, {'q': 1});
      expect(mapped.responseType, HttpResponseType.bytes);
      expect(mapped.listFormat, HttpListFormat.pipes);
      expect(mapped.cancelToken, isA<DioCancelToken>());
      expect(mapped.extra, containsPair('k', 'v'));
    });

    test('lifts Content-Type into contentType and drops it from headers', () {
      final request = RequestOptions(
        path: '/login',
        contentType: Headers.jsonContentType,
        headers: const {'X-App': '1'},
      );

      final mapped = fromDioRequestOptions(request);

      expect(mapped.contentType, Headers.jsonContentType);
      expect(mapped.headers, isNot(contains(Headers.contentTypeHeader)));
      expect(mapped.headers, containsPair('X-App', '1'));
    });
  });

  group('resolvedFromDioRequestOptions()', () {
    test('maps remaining Dio response and list types', () {
      expect(
        resolvedFromDioRequestOptions(
          RequestOptions(path: '/', responseType: ResponseType.json),
        ).responseType,
        HttpResponseType.json,
      );
      expect(
        resolvedFromDioRequestOptions(
          RequestOptions(path: '/', responseType: ResponseType.plain),
        ).responseType,
        HttpResponseType.plain,
      );
      expect(
        resolvedFromDioRequestOptions(
          RequestOptions(path: '/', responseType: ResponseType.stream),
        ).responseType,
        HttpResponseType.stream,
      );
      expect(
        resolvedFromDioRequestOptions(
          RequestOptions(path: '/', listFormat: ListFormat.csv),
        ).listFormat,
        HttpListFormat.csv,
      );
      expect(
        resolvedFromDioRequestOptions(
          RequestOptions(path: '/', listFormat: ListFormat.ssv),
        ).listFormat,
        HttpListFormat.ssv,
      );
      expect(
        resolvedFromDioRequestOptions(
          RequestOptions(path: '/', listFormat: ListFormat.tsv),
        ).listFormat,
        HttpListFormat.tsv,
      );
      expect(
        resolvedFromDioRequestOptions(
          RequestOptions(path: '/', listFormat: ListFormat.multi),
        ).listFormat,
        HttpListFormat.multi,
      );
      expect(
        resolvedFromDioRequestOptions(
          RequestOptions(path: '/', listFormat: ListFormat.multiCompatible),
        ).listFormat,
        HttpListFormat.multiCompatible,
      );
    });
  });

  group('toHttpResponse()', () {
    test('maps redirect method and status when redirects exist', () {
      final requestOptions = RequestOptions(path: '/test');
      final response = Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: 200,
        redirects: [
          RedirectRecord(302, 'GET', Uri.parse('https://example.com/next')),
        ],
      );

      final mapped = toHttpResponse<Map<String, dynamic>>(response);

      expect(mapped.redirects.single.method, 'GET');
      expect(mapped.redirects.single.statusCode, 302);
    });

    test('uses statusCode 0 when Dio omits a status', () {
      final mapped = toHttpResponse<void>(
        Response<dynamic>(
          requestOptions: RequestOptions(path: '/test'),
        ),
      );

      expect(mapped.statusCode, 0);
    });
  });

  group('mapResponseData()', () {
    test('wraps a Dio ResponseBody when the payload is a stream', () {
      final body = ResponseBody.fromBytes(
        [1, 2, 3],
        200,
        headers: {
          Headers.contentTypeHeader: ['application/octet-stream'],
          Headers.contentLengthHeader: ['3'],
        },
      );
      final response = Response<ResponseBody>(
        requestOptions: RequestOptions(path: '/stream'),
        data: body,
        statusCode: 200,
      );

      final mapped = mapResponseData<HttpResponseBody>(response);

      expect(mapped, isA<HttpResponseBody>());
      expect(mapped!.statusCode, 200);
      expect(mapped.contentLength, 3);
    });

    test('omits contentLength when Dio reports a negative length', () {
      final body = ResponseBody(
        const Stream<Uint8List>.empty(),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/octet-stream'],
        },
      );
      final response = Response<ResponseBody>(
        requestOptions: RequestOptions(path: '/stream'),
        data: body,
        statusCode: 200,
      );

      final mapped = mapResponseData<HttpResponseBody>(response);

      expect(mapped!.contentLength, isNull);
    });

    test('returns the raw payload when it is not a ResponseBody', () {
      final response = Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/json'),
        data: const {'ok': true},
        statusCode: 200,
      );

      expect(mapResponseData<Map<String, dynamic>>(response), {'ok': true});
    });
  });

  group('applyHttpResponseToDio()', () {
    test('writes all response fields back onto the Dio response', () {
      final dioResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 200,
        data: const {'old': true},
      );

      applyHttpResponseToDio(
        dioResponse,
        HttpResponse<Map<String, dynamic>>(
          data: const {'new': true},
          statusCode: 201,
          statusMessage: 'Created',
          headers: const {
            'x-custom': ['1'],
          },
          isRedirect: true,
          redirects: [
            HttpRedirectRecord(
              statusCode: 302,
              method: 'GET',
              location: Uri.parse('https://example.com/next'),
            ),
          ],
          extra: const {'trace': 'abc'},
          requestUri: Uri.parse('https://example.com/test'),
        ),
      );

      expect(dioResponse.statusCode, 201);
      expect(dioResponse.statusMessage, 'Created');
      expect(dioResponse.data, const {'new': true});
      expect(dioResponse.isRedirect, isTrue);
      expect(dioResponse.redirects.single.method, 'GET');
      expect(dioResponse.extra['trace'], 'abc');
      expect(dioResponse.headers.value('x-custom'), '1');
    });
  });
}

void _noopProgress(int count, int total) {}
