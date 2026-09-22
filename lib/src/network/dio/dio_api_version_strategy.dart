import 'package:falconet/src/network/base/base.dart';

/// Prepends `/v{version}` to request paths (e.g. `/users` → `/v1/users`).
class DioApiVersionStrategy extends ApiVersionStrategy {
  const DioApiVersionStrategy();

  @override
  ApiVersionResult apply({
    required String path,
    required HttpRequestOptions options,
    required String? apiVersion,
  }) {
    if (apiVersion == null || apiVersion.isEmpty) {
      return ApiVersionResult(path: path, options: options);
    }

    final prefix = '/v$apiVersion';
    if (path.startsWith(prefix)) {
      return ApiVersionResult(path: path, options: options);
    }

    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return ApiVersionResult(
      path: '$prefix$normalizedPath',
      options: options,
    );
  }
}
