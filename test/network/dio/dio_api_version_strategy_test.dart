import 'package:falconet/falconet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const strategy = DioApiVersionStrategy();

  DioApiVersionStrategy buildUnit() => strategy;

  group('DioApiVersionStrategy', () {
    group('apply()', () {
      test('prepends /v1 to request path when version is 1', () {
        final result = buildUnit().apply(
          path: '/auth/login',
          options: const HttpRequestOptions(),
          apiVersion: '1',
        );

        expect(result.path, '/v1/auth/login');
      });

      test('leaves path unchanged when version is null', () {
        final result = buildUnit().apply(
          path: '/auth/login',
          options: const HttpRequestOptions(),
          apiVersion: null,
        );

        expect(result.path, '/auth/login');
      });

      test('leaves path unchanged when version is empty', () {
        final result = buildUnit().apply(
          path: '/auth/login',
          options: const HttpRequestOptions(),
          apiVersion: '',
        );

        expect(result.path, '/auth/login');
      });

      test('does not double-prefix an already versioned path', () {
        final result = buildUnit().apply(
          path: '/v1/auth/login',
          options: const HttpRequestOptions(),
          apiVersion: '1',
        );

        expect(result.path, '/v1/auth/login');
      });

      test('adds a leading slash when the path has none', () {
        final result = buildUnit().apply(
          path: 'auth/login',
          options: const HttpRequestOptions(),
          apiVersion: '2',
        );

        expect(result.path, '/v2/auth/login');
      });
    });
  });
}
