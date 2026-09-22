import 'package:dio/dio.dart';
import 'package:falconet/src/network/base/error/http_error_mapper.dart';
import 'package:falconet/src/network/base/error/http_exception.dart';

/// Generic fallback mapper that extracts messages from common API shapes.
///
/// Does not assign project-specific [HttpException.type] / [HttpException.code]
/// from status — apps should wrap or replace this with a project mapper.
class DefaultHttpErrorMapper extends HttpErrorMapper {
  const DefaultHttpErrorMapper();

  @override
  HttpException map(Object error, {StackTrace? stackTrace}) {
    if (error is HttpException) {
      return error;
    }

    if (error is HttpResponseException) {
      final message = _extractMessage(error.rawBody) ?? 'Request failed';
      return HttpException(
        message,
        statusCode: error.statusCode,
        code: _extractCode(error.rawBody),
        rawBody: error.rawBody,
      );
    }

    if (error is DioException) {
      return _mapDioException(error);
    }

    return HttpException(error.toString());
  }

  HttpException _mapDioException(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final rawBody = response?.data;
    final message = _extractMessage(rawBody) ?? _dioMessage(error);

    return HttpException(
      message,
      statusCode: statusCode,
      code: _extractCode(rawBody),
      rawBody: rawBody,
    );
  }

  String? _extractCode(Object? body) {
    if (body is! Map) {
      return null;
    }

    final map = Map<String, dynamic>.from(body);
    for (final key in ['code', 'error_code', 'errorCode']) {
      final value = map[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String? _extractMessage(Object? body) {
    if (body == null) {
      return null;
    }

    if (body is String && body.isNotEmpty) {
      return body;
    }

    if (body is Map) {
      final map = Map<String, dynamic>.from(body);

      final message = map['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }

      final error = map['error'];
      if (error is String && error.isNotEmpty) {
        return error;
      }

      final exception = map['exception'];
      if (exception is String && exception.isNotEmpty) {
        return exception;
      }

      final serverMessages = map['_server_messages'];
      if (serverMessages is String && serverMessages.isNotEmpty) {
        return serverMessages;
      }

      final errors = map['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            final first = value.first;
            if (first is String && first.isNotEmpty) {
              return first;
            }
          }
          if (value is String && value.isNotEmpty) {
            return value;
          }
        }
      }

      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is Map) {
          final nestedMessage = first['message'];
          if (nestedMessage is String && nestedMessage.isNotEmpty) {
            return nestedMessage;
          }
        }
        if (first is String && first.isNotEmpty) {
          return first;
        }
      }
    }

    return null;
  }

  String _dioMessage(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout => 'Connection timed out',
      DioExceptionType.sendTimeout => 'Request timed out while sending',
      DioExceptionType.receiveTimeout => 'Request timed out while receiving',
      DioExceptionType.connectionError => 'Connection failed',
      DioExceptionType.cancel => 'Request was cancelled',
      DioExceptionType.badCertificate => 'Invalid security certificate',
      DioExceptionType.badResponse => 'Request failed',
      DioExceptionType.unknown ||
      DioExceptionType.transformTimeout => error.message ?? 'Request failed',
    };
  }
}
