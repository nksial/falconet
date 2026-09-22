import 'package:dio/dio.dart';
import 'package:falconet/src/network/dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/falconet_mocks.dart';

void main() {
  group('DioCancelToken', () {
    group('isCancelled', () {
      test('returns false when the token has not been cancelled', () {
        final unit = DioCancelToken();

        expect(unit.isCancelled, isFalse);
      });

      test('returns true when cancel was called', () {
        final unit = DioCancelToken()..cancel('stop');

        expect(unit.isCancelled, isTrue);
      });
    });

    group('cancel()', () {
      test('completes whenCancelled when cancel is invoked', () async {
        final unit = DioCancelToken();

        final future = unit.whenCancelled;
        unit.cancel();

        await expectLater(future, completes);
      });
    });

    group('dioToken', () {
      test('reuses the provided Dio CancelToken when constructed', () {
        final dioToken = CancelToken();

        final unit = DioCancelToken(token: dioToken);

        expect(unit.dioToken, same(dioToken));
      });
    });
  });

  group('toDioCancelToken()', () {
    test('returns null when token is null', () {
      expect(toDioCancelToken(null), isNull);
    });

    test('returns the underlying Dio token when given DioCancelToken', () {
      final unit = DioCancelToken();

      expect(toDioCancelToken(unit), same(unit.dioToken));
    });

    test('throws ArgumentError when token type is unsupported', () {
      expect(
        () => toDioCancelToken(MockHttpCancelToken()),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('fromDioCancelToken()', () {
    test('returns null when token is null', () {
      expect(fromDioCancelToken(null), isNull);
    });

    test('wraps a Dio CancelToken when one is provided', () {
      final dioToken = CancelToken();

      final wrapped = fromDioCancelToken(dioToken);

      expect(wrapped, isA<DioCancelToken>());
      expect((wrapped! as DioCancelToken).dioToken, same(dioToken));
    });
  });
}
