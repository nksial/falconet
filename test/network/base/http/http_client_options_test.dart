import 'package:falconet/falconet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HttpClientOptions', () {
    group('copyWith()', () {
      test('replaces only the provided fields when others are omitted', () {
        const original = HttpClientOptions(
          baseUrl: 'https://example.com',
          apiVersion: '1',
          defaultHeaders: {'a': '1'},
        );

        final copied = original.copyWith(
          baseUrl: 'https://api.example.com',
          defaultQueryParameters: {'q': '1'},
        );

        expect(copied.baseUrl, 'https://api.example.com');
        expect(copied.apiVersion, '1');
        expect(copied.defaultHeaders, {'a': '1'});
        expect(copied.defaultQueryParameters, {'q': '1'});
      });

      test('keeps original values when copyWith is empty', () {
        const original = HttpClientOptions(
          baseUrl: 'https://example.com',
          connectTimeout: Duration(seconds: 1),
          receiveTimeout: Duration(seconds: 2),
          sendTimeout: Duration(seconds: 3),
          transformTimeout: Duration(seconds: 4),
          contentType: 'application/json',
          extra: {'trace': '1'},
        );

        final copied = original.copyWith();

        expect(copied.baseUrl, original.baseUrl);
        expect(copied.connectTimeout, original.connectTimeout);
        expect(copied.receiveTimeout, original.receiveTimeout);
        expect(copied.sendTimeout, original.sendTimeout);
        expect(copied.transformTimeout, original.transformTimeout);
        expect(copied.contentType, original.contentType);
        expect(copied.extra, original.extra);
      });
    });
  });
}
