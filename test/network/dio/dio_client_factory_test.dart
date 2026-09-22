import 'package:falconet/falconet.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/falconet_mocks.dart';

void main() {
  group('createHttpClient()', () {
    test('returns a Dio-backed client when options are provided', () {
      final client = createHttpClient(
        options: const HttpClientOptions(
          baseUrl: 'https://example.com',
        ),
        errorMapper: const DefaultHttpErrorMapper(),
      );

      expect(client, isA<HttpClient>());
    });

    test('attaches interceptors when a list is provided', () {
      final interceptor = FakeHttpInterceptor();

      final client = createHttpClient(
        options: const HttpClientOptions(
          baseUrl: 'https://example.com',
        ),
        errorMapper: const DefaultHttpErrorMapper(),
        versionStrategy: const DioApiVersionStrategy(),
        interceptors: [interceptor],
      );

      expect(client, isA<HttpClient>());
    });
  });
}
