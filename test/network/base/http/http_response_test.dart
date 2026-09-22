import 'package:falconet/falconet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HttpResponse', () {
    group('realUri', () {
      test('returns the last redirect location when redirects exist', () {
        final unit = HttpResponse<void>(
          data: null,
          statusCode: 200,
          requestUri: Uri.parse('https://example.com/start'),
          redirects: [
            HttpRedirectRecord(
              statusCode: 302,
              method: 'GET',
              location: Uri.parse('https://example.com/mid'),
            ),
            HttpRedirectRecord(
              statusCode: 301,
              method: 'GET',
              location: Uri.parse('https://example.com/end'),
            ),
          ],
        );

        expect(unit.realUri, Uri.parse('https://example.com/end'));
      });

      test('returns requestUri when there are no redirects', () {
        final unit = HttpResponse<void>(
          data: null,
          statusCode: 200,
          requestUri: Uri.parse('https://example.com/start'),
        );

        expect(unit.realUri, Uri.parse('https://example.com/start'));
      });
    });
  });
}
