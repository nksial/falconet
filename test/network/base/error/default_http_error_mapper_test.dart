import 'package:dio/dio.dart';
import 'package:falconet/falconet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = DefaultHttpErrorMapper();

  DefaultHttpErrorMapper buildUnit() => mapper;

  group('DefaultHttpErrorMapper', () {
    group('map()', () {
      test('returns the same instance when error is HttpException', () {
        const original = HttpException('already mapped', statusCode: 401);

        final result = buildUnit().map(original);

        expect(result, same(original));
      });

      test(
        'maps Laravel-like validation errors when body has message',
        () {
          final result = buildUnit().map(
            HttpResponseException(
              statusCode: 422,
              rawBody: {
                'message': 'The given data was invalid.',
                'errors': {
                  'email': ['The email field is required.'],
                },
              },
            ),
          );

          expect(result.message, 'The given data was invalid.');
          expect(result.statusCode, 422);
        },
      );

      test('maps Frappe-like exception payload when exception is set', () {
        final result = buildUnit().map(
          HttpResponseException(
            statusCode: 500,
            rawBody: {
              'exception': 'ValidationError: Invalid credentials',
              '_server_messages':
                  '[{"message": "Invalid login", "title": "Message"}]',
            },
          ),
        );

        expect(result.message, 'ValidationError: Invalid credentials');
      });

      test('uses error field when message is missing', () {
        final result = buildUnit().map(
          HttpResponseException(
            statusCode: 400,
            rawBody: const {'error': 'Bad credentials'},
          ),
        );

        expect(result.message, 'Bad credentials');
      });

      test('uses first validation list entry when message is missing', () {
        final result = buildUnit().map(
          HttpResponseException(
            statusCode: 422,
            rawBody: {
              'errors': {
                'email': ['The email field is required.'],
              },
            },
          ),
        );

        expect(result.message, 'The email field is required.');
      });

      test('uses first string error when errors map values are strings', () {
        final result = buildUnit().map(
          HttpResponseException(
            statusCode: 422,
            rawBody: const {
              'errors': {'email': 'required'},
            },
          ),
        );

        expect(result.message, 'required');
      });

      test('uses first list message when errors is a list of maps', () {
        final result = buildUnit().map(
          HttpResponseException(
            statusCode: 400,
            rawBody: {
              'errors': [
                {'message': 'nested failure'},
              ],
            },
          ),
        );

        expect(result.message, 'nested failure');
      });

      test('uses first list string when errors is a list of strings', () {
        final result = buildUnit().map(
          HttpResponseException(
            statusCode: 400,
            rawBody: {
              'errors': ['plain failure'],
            },
          ),
        );

        expect(result.message, 'plain failure');
      });

      test('uses raw string body when body is a non-empty string', () {
        final result = buildUnit().map(
          HttpResponseException(
            statusCode: 500,
            rawBody: 'upstream exploded',
          ),
        );

        expect(result.message, 'upstream exploded');
      });

      test('uses _server_messages when other keys are missing', () {
        final result = buildUnit().map(
          HttpResponseException(
            statusCode: 400,
            rawBody: const {'_server_messages': 'frappe dump'},
          ),
        );

        expect(result.message, 'frappe dump');
      });

      test('falls back to Request failed when body has no message', () {
        final result = buildUnit().map(
          HttpResponseException(
            statusCode: 500,
            rawBody: const {'unused': true},
          ),
        );

        expect(result.message, 'Request failed');
        expect(result.statusCode, 500);
      });

      test('extracts code when body contains a non-empty code', () {
        final result = buildUnit().map(
          HttpResponseException(
            statusCode: 403,
            rawBody: const {
              'message': 'denied',
              'code': 'forbidden',
            },
          ),
        );

        expect(result.code, 'forbidden');
      });

      test('extracts error_code when code is missing', () {
        final result = buildUnit().map(
          HttpResponseException(
            statusCode: 403,
            rawBody: const {
              'message': 'denied',
              'error_code': 'legacy',
            },
          ),
        );

        expect(result.code, 'legacy');
      });

      test('extracts errorCode when other code keys are missing', () {
        final result = buildUnit().map(
          HttpResponseException(
            statusCode: 403,
            rawBody: const {
              'message': 'denied',
              'errorCode': 'camel',
            },
          ),
        );

        expect(result.code, 'camel');
      });

      test('maps Dio connection timeout when type is connectionTimeout', () {
        final result = buildUnit().map(
          DioException(
            requestOptions: RequestOptions(path: '/auth/login'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        expect(result.message, 'Connection timed out');
      });

      test('maps Dio send timeout when type is sendTimeout', () {
        final result = buildUnit().map(
          DioException(
            requestOptions: RequestOptions(path: '/auth/login'),
            type: DioExceptionType.sendTimeout,
          ),
        );

        expect(result.message, 'Request timed out while sending');
      });

      test('maps Dio receive timeout when type is receiveTimeout', () {
        final result = buildUnit().map(
          DioException(
            requestOptions: RequestOptions(path: '/auth/login'),
            type: DioExceptionType.receiveTimeout,
          ),
        );

        expect(result.message, 'Request timed out while receiving');
      });

      test('maps Dio connection error when type is connectionError', () {
        final result = buildUnit().map(
          DioException(
            requestOptions: RequestOptions(path: '/auth/login'),
            type: DioExceptionType.connectionError,
          ),
        );

        expect(result.message, 'Connection failed');
      });

      test('maps Dio cancel when type is cancel', () {
        final result = buildUnit().map(
          DioException(
            requestOptions: RequestOptions(path: '/auth/login'),
            type: DioExceptionType.cancel,
          ),
        );

        expect(result.message, 'Request was cancelled');
      });

      test('maps Dio bad certificate when type is badCertificate', () {
        final result = buildUnit().map(
          DioException(
            requestOptions: RequestOptions(path: '/auth/login'),
            type: DioExceptionType.badCertificate,
          ),
        );

        expect(result.message, 'Invalid security certificate');
      });

      test('maps Dio bad response when type is badResponse', () {
        final result = buildUnit().map(
          DioException(
            requestOptions: RequestOptions(path: '/auth/login'),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(result.message, 'Request failed');
      });

      test(
        'uses Dio message when type is unknown and message is set',
        () {
          final result = buildUnit().map(
            DioException(
              requestOptions: RequestOptions(path: '/auth/login'),
              message: 'custom unknown',
            ),
          );

          expect(result.message, 'custom unknown');
        },
      );

      test(
        'falls back to Request failed when unknown Dio message is null',
        () {
          final result = buildUnit().map(
            DioException(
              requestOptions: RequestOptions(path: '/auth/login'),
            ),
          );

          expect(result.message, 'Request failed');
        },
      );

      test('prefers response body message over Dio type message', () {
        final result = buildUnit().map(
          DioException(
            requestOptions: RequestOptions(path: '/auth/login'),
            type: DioExceptionType.badResponse,
            response: Response<Map<String, dynamic>>(
              requestOptions: RequestOptions(path: '/auth/login'),
              statusCode: 400,
              data: const {'message': 'from body'},
            ),
          ),
        );

        expect(result.message, 'from body');
        expect(result.statusCode, 400);
      });

      test(
        'uses Dio message when type is transformTimeout and message is set',
        () {
          final result = buildUnit().map(
            DioException(
              requestOptions: RequestOptions(path: '/auth/login'),
              type: DioExceptionType.transformTimeout,
              message: 'transform slow',
            ),
          );

          expect(result.message, 'transform slow');
        },
      );

      test('falls back to Request failed when raw body is null', () {
        final result = buildUnit().map(
          HttpResponseException(statusCode: 500, rawBody: null),
        );

        expect(result.message, 'Request failed');
      });

      test('falls back to Request failed when raw body is empty string', () {
        final result = buildUnit().map(
          HttpResponseException(statusCode: 500, rawBody: ''),
        );

        expect(result.message, 'Request failed');
      });

      test('returns error.toString when the type is unrecognized', () {
        final result = buildUnit().map(StateError('unexpected'));

        expect(result.message, contains('unexpected'));
      });
    });
  });
}
