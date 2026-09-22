import 'package:falconet/falconet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HttpInterceptor', () {
    late HttpInterceptorContext context;

    setUp(() {
      context = HttpInterceptorContext(
        path: '/users',
        options: const HttpRequestOptions(),
      );
    });

    HttpInterceptor buildUnit() => _NoOpInterceptor();

    group('onRequest()', () {
      test('completes without changing context when not overridden', () async {
        final unit = buildUnit();

        await unit.onRequest(context);

        expect(context.path, '/users');
      });
    });

    group('onResponse()', () {
      test('completes without changing context when not overridden', () async {
        final unit = buildUnit();

        await unit.onResponse(context);

        expect(context.response, isNull);
      });
    });

    group('onError()', () {
      test('completes without changing context when not overridden', () async {
        final unit = buildUnit();
        context.error = StateError('boom');

        await unit.onError(context);

        expect(context.error, isA<StateError>());
      });
    });
  });
}

class _NoOpInterceptor extends HttpInterceptor {}
