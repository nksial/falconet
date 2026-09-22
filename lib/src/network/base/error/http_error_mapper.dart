import 'package:falconet/src/network/base/error/http_exception.dart';

/// Maps transport and API errors to [HttpException].
///
/// Swap in bootstrap for backend-specific mappers (Laravel, Frappe, etc.).
abstract class HttpErrorMapper {
  const HttpErrorMapper();

  HttpException map(Object error, {StackTrace? stackTrace});
}
