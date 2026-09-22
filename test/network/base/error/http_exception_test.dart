import 'package:falconet/falconet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HttpException', () {
    group('toString()', () {
      test('returns the message when converted to a string', () {
        const unit = HttpException('boom', statusCode: 500);

        expect(unit.toString(), 'boom');
      });
    });
  });

  group('HttpResponseException', () {
    test('exposes statusCode and rawBody when constructed', () {
      final unit = HttpResponseException(
        statusCode: 422,
        rawBody: const {'message': 'invalid'},
      );

      expect(unit.statusCode, 422);
      expect(unit.rawBody, const {'message': 'invalid'});
    });
  });
}
