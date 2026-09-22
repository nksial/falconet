import 'package:falconet/falconet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HttpMultipartFile', () {
    test('creates a file when bytes are provided', () {
      const unit = HttpMultipartFile(
        field: 'avatar',
        filename: 'a.png',
        bytes: [1, 2, 3],
        contentType: 'image/png',
      );

      expect(unit.field, 'avatar');
      expect(unit.filename, 'a.png');
      expect(unit.bytes, [1, 2, 3]);
      expect(unit.contentType, 'image/png');
    });

    test('creates a file when a stream is provided', () {
      final unit = HttpMultipartFile(
        field: 'doc',
        stream: Stream.value([4, 5]),
      );

      expect(unit.stream, isNotNull);
      expect(unit.bytes, isNull);
    });

    test('throws AssertionError when neither bytes nor stream is set', () {
      expect(
        () => HttpMultipartFile(field: 'empty'),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
