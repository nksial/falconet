import 'package:falconet/falconet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('httpAcceptAllStatuses()', () {
    test('returns true when status is a success code', () {
      expect(httpAcceptAllStatuses(200), isTrue);
    });

    test('returns true when status is an error code', () {
      expect(httpAcceptAllStatuses(500), isTrue);
    });

    test('returns true when status is null', () {
      expect(httpAcceptAllStatuses(null), isTrue);
    });
  });

  group('httpDefaultValidateStatus()', () {
    test('returns true when status is in the 2xx range', () {
      expect(httpDefaultValidateStatus(200), isTrue);
      expect(httpDefaultValidateStatus(299), isTrue);
    });

    test('returns false when status is below 200', () {
      expect(httpDefaultValidateStatus(199), isFalse);
    });

    test('returns false when status is 300 or above', () {
      expect(httpDefaultValidateStatus(300), isFalse);
    });

    test('returns false when status is null', () {
      expect(httpDefaultValidateStatus(null), isFalse);
    });
  });
}
