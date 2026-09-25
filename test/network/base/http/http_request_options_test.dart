import 'package:falconet/falconet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HttpRequestOptions', () {
    group('copyWith()', () {
      test('replaces provided fields when others are omitted', () {
        const original = HttpRequestOptions(
          headers: {'a': '1'},
          queryParameters: {'q': 1},
        );

        final copied = original.copyWith(
          headers: {'b': '2'},
          contentType: 'text/plain',
        );

        expect(copied.headers, {'b': '2'});
        expect(copied.queryParameters, {'q': 1});
        expect(copied.contentType, 'text/plain');
      });

      test('keeps existing headers and contentType when omitted', () {
        const original = HttpRequestOptions(
          headers: {'a': '1'},
          contentType: 'application/json',
        );

        final copied = original.copyWith(queryParameters: {'q': 2});

        expect(copied.headers, {'a': '1'});
        expect(copied.contentType, 'application/json');
        expect(copied.queryParameters, {'q': 2});
      });
    });

    group('resolve()', () {
      test('merges default query parameters from client options', () {
        const clientOptions = HttpClientOptions(
          defaultQueryParameters: {'lang': 'en'},
        );
        const requestOptions = HttpRequestOptions(
          queryParameters: {'page': 1},
        );

        final resolved = requestOptions.resolve(clientOptions);

        expect(resolved.queryParameters, {'lang': 'en', 'page': 1});
      });

      test('lets request headers override client defaults', () {
        const clientOptions = HttpClientOptions(
          defaultHeaders: {'Authorization': 'client', 'X-App': '1'},
        );
        const requestOptions = HttpRequestOptions(
          headers: {'Authorization': 'request'},
        );

        final resolved = requestOptions.resolve(clientOptions);

        expect(resolved.headers, {
          'Authorization': 'request',
          'X-App': '1',
        });
      });

      test('uses request timeouts when they override client defaults', () {
        const clientOptions = HttpClientOptions(
          connectTimeout: Duration(seconds: 5),
          receiveTimeout: Duration(seconds: 5),
          sendTimeout: Duration(seconds: 5),
          transformTimeout: Duration(seconds: 5),
        );
        const requestOptions = HttpRequestOptions(
          connectTimeout: Duration(seconds: 1),
          receiveTimeout: Duration(seconds: 2),
          sendTimeout: Duration(seconds: 3),
          transformTimeout: Duration(seconds: 4),
        );

        final resolved = requestOptions.resolve(clientOptions);

        expect(resolved.connectTimeout, const Duration(seconds: 1));
        expect(resolved.receiveTimeout, const Duration(seconds: 2));
        expect(resolved.sendTimeout, const Duration(seconds: 3));
        expect(resolved.transformTimeout, const Duration(seconds: 4));
      });

      test('falls back to client defaults when request fields are null', () {
        const clientOptions = HttpClientOptions(
          connectTimeout: Duration(seconds: 9),
          responseType: HttpResponseType.plain,
          contentType: 'text/plain',
          extra: {'from': 'client'},
        );

        final resolved = const HttpRequestOptions().resolve(clientOptions);

        expect(resolved.connectTimeout, const Duration(seconds: 9));
        expect(resolved.responseType, HttpResponseType.plain);
        expect(resolved.contentType, 'text/plain');
        expect(resolved.extra, {'from': 'client'});
      });
    });

    group('resolveInterceptorMutation()', () {
      test('keeps header removals instead of re-merging defaults', () {
        const clientOptions = HttpClientOptions(
          defaultHeaders: {'Authorization': 'Bearer stale', 'X-App': '1'},
          connectTimeout: Duration(seconds: 9),
        );
        const requestOptions = HttpRequestOptions(
          headers: {'X-App': '1'},
        );

        final resolved = requestOptions.resolveInterceptorMutation(
          clientOptions,
        );

        expect(resolved.headers.containsKey('Authorization'), isFalse);
        expect(resolved.headers, {'X-App': '1'});
        expect(resolved.connectTimeout, const Duration(seconds: 9));
      });
    });
  });

  group('ResolvedHttpRequestOptions', () {
    group('copyWith()', () {
      test('replaces responseType when a new value is provided', () {
        const original = ResolvedHttpRequestOptions(
          headers: {},
          queryParameters: {},
          connectTimeout: null,
          receiveTimeout: null,
          sendTimeout: null,
          transformTimeout: null,
          responseType: HttpResponseType.json,
          contentType: null,
          validateStatus: httpDefaultValidateStatus,
          receiveDataWhenStatusError: true,
          followRedirects: true,
          maxRedirects: 5,
          persistentConnection: true,
          listFormat: HttpListFormat.multi,
          preserveHeaderCase: false,
          requestEncoder: null,
          responseDecoder: null,
          cancelToken: null,
          extra: {},
        );

        final copied = original.copyWith(
          responseType: HttpResponseType.bytes,
        );

        expect(copied.responseType, HttpResponseType.bytes);
        expect(copied.maxRedirects, 5);
      });
    });
  });
}
