import 'package:dio/dio.dart';
import 'package:falconet/src/network/base/base.dart';

/// Dio-backed [HttpCancelToken].
class DioCancelToken implements HttpCancelToken {
  DioCancelToken({CancelToken? token}) : _token = token ?? CancelToken();

  final CancelToken _token;

  CancelToken get dioToken => _token;

  @override
  bool get isCancelled => _token.isCancelled;

  @override
  void cancel([Object? reason]) => _token.cancel(reason);

  @override
  Future<void> get whenCancelled => _token.whenCancel.then((_) {});
}

CancelToken? toDioCancelToken(HttpCancelToken? token) {
  if (token == null) {
    return null;
  }
  if (token is DioCancelToken) {
    return token.dioToken;
  }
  throw ArgumentError(
    'Unsupported HttpCancelToken implementation: ${token.runtimeType}',
  );
}

HttpCancelToken? fromDioCancelToken(CancelToken? token) {
  if (token == null) {
    return null;
  }
  return DioCancelToken(token: token);
}
