import 'package:dio/dio.dart';
import 'package:falconet/src/network/base/base.dart';
import 'package:falconet/src/network/dio/dio_cancel_token.dart';
import 'package:falconet/src/network/dio/dio_interceptor_adapter.dart';
import 'package:falconet/src/network/dio/dio_options_mapper.dart';

class DioClient implements HttpClient {
  DioClient({
    required this.dio,
    required this.clientOptions,
    required this.errorMapper,
    this.apiVersion,
    this.versionStrategy,
  });

  final Dio dio;
  final HttpClientOptions clientOptions;
  final HttpErrorMapper errorMapper;
  final ApiVersionStrategy? versionStrategy;
  final String? apiVersion;
  final Map<HttpInterceptor, DioInterceptorAdapter> _adapters = {};

  @override
  Future<HttpResponse<T>> delete<T>(
    String path, {
    Object? body,
    HttpRequestOptions? options,
  }) {
    return _request<T>(
      path,
      options: options,
      request: (resolvedPath, resolvedOptions) {
        return dio.delete<T>(
          resolvedPath,
          data: body,
          queryParameters: resolvedOptions.queryParameters,
          options: toDioOptions(resolvedOptions),
          cancelToken: toDioCancelToken(resolvedOptions.cancelToken),
        );
      },
    );
  }

  @override
  Future<HttpResponse<List<int>>> download(
    String path, {
    String? savePath,
    HttpRequestOptions? options,
  }) {
    return _request<List<int>>(
      path,
      options: options,
      responseTypeOverride: HttpResponseType.bytes,
      request: (resolvedPath, resolvedOptions) async {
        final dioOptions = toDioOptions(resolvedOptions);
        final cancelToken = toDioCancelToken(resolvedOptions.cancelToken);

        if (savePath != null) {
          await dio.download(
            resolvedPath,
            savePath,
            queryParameters: resolvedOptions.queryParameters,
            options: dioOptions,
            cancelToken: cancelToken,
            onReceiveProgress: resolvedOptions.onReceiveProgress,
          );
          return Response<List<int>>(
            requestOptions: RequestOptions(path: resolvedPath),
            statusCode: 200,
            data: const [],
          );
        }

        return dio.get<List<int>>(
          resolvedPath,
          queryParameters: resolvedOptions.queryParameters,
          options: dioOptions,
          cancelToken: cancelToken,
          onReceiveProgress: resolvedOptions.onReceiveProgress,
        );
      },
    );
  }

  @override
  Future<HttpResponse<T>> get<T>(
    String path, {
    HttpRequestOptions? options,
  }) {
    return _request<T>(
      path,
      options: options,
      request: (resolvedPath, resolvedOptions) {
        return dio.get<T>(
          resolvedPath,
          queryParameters: resolvedOptions.queryParameters,
          options: toDioOptions(resolvedOptions),
          cancelToken: toDioCancelToken(resolvedOptions.cancelToken),
          onReceiveProgress: resolvedOptions.onReceiveProgress,
        );
      },
    );
  }

  @override
  Future<HttpResponse<String>> getPlain(
    String path, {
    HttpRequestOptions? options,
  }) {
    return _request<String>(
      path,
      options: options,
      responseTypeOverride: HttpResponseType.plain,
      request: (resolvedPath, resolvedOptions) {
        return dio.get<String>(
          resolvedPath,
          queryParameters: resolvedOptions.queryParameters,
          options: toDioOptions(resolvedOptions),
          cancelToken: toDioCancelToken(resolvedOptions.cancelToken),
          onReceiveProgress: resolvedOptions.onReceiveProgress,
        );
      },
    );
  }

  @override
  Future<HttpResponse<HttpResponseBody>> getStream(
    String path, {
    HttpRequestOptions? options,
  }) {
    return _request<HttpResponseBody>(
      path,
      options: options,
      responseTypeOverride: HttpResponseType.stream,
      request: (resolvedPath, resolvedOptions) {
        return dio.get<ResponseBody>(
          resolvedPath,
          queryParameters: resolvedOptions.queryParameters,
          options: toDioOptions(resolvedOptions),
          cancelToken: toDioCancelToken(resolvedOptions.cancelToken),
          onReceiveProgress: resolvedOptions.onReceiveProgress,
        );
      },
    );
  }

  @override
  Future<HttpResponse<T>> patch<T>(
    String path, {
    Object? body,
    HttpRequestOptions? options,
  }) {
    return _request<T>(
      path,
      options: options,
      request: (resolvedPath, resolvedOptions) {
        return dio.patch<T>(
          resolvedPath,
          data: body ?? const {},
          queryParameters: resolvedOptions.queryParameters,
          options: toDioOptions(resolvedOptions),
          cancelToken: toDioCancelToken(resolvedOptions.cancelToken),
          onSendProgress: resolvedOptions.onSendProgress,
          onReceiveProgress: resolvedOptions.onReceiveProgress,
        );
      },
    );
  }

  @override
  Future<HttpResponse<T>> post<T>(
    String path, {
    Object? body,
    HttpRequestOptions? options,
  }) {
    return _request<T>(
      path,
      options: options,
      request: (resolvedPath, resolvedOptions) {
        return dio.post<T>(
          resolvedPath,
          data: body ?? const {},
          queryParameters: resolvedOptions.queryParameters,
          options: toDioOptions(resolvedOptions),
          cancelToken: toDioCancelToken(resolvedOptions.cancelToken),
          onSendProgress: resolvedOptions.onSendProgress,
          onReceiveProgress: resolvedOptions.onReceiveProgress,
        );
      },
    );
  }

  @override
  Future<HttpResponse<T>> put<T>(
    String path, {
    Object? body,
    HttpRequestOptions? options,
  }) {
    return _request<T>(
      path,
      options: options,
      request: (resolvedPath, resolvedOptions) {
        return dio.put<T>(
          resolvedPath,
          data: body ?? const {},
          queryParameters: resolvedOptions.queryParameters,
          options: toDioOptions(resolvedOptions),
          cancelToken: toDioCancelToken(resolvedOptions.cancelToken),
          onSendProgress: resolvedOptions.onSendProgress,
          onReceiveProgress: resolvedOptions.onReceiveProgress,
        );
      },
    );
  }

  @override
  Future<HttpResponse<T>> upload<T>(
    String path, {
    Map<String, dynamic>? fields,
    List<HttpMultipartFile>? files,
    HttpRequestOptions? options,
  }) {
    return _request<T>(
      path,
      options: options,
      request: (resolvedPath, resolvedOptions) async {
        final formData = FormData.fromMap({
          ...?fields,
          if (files != null)
            for (final file in files) file.field: _toMultipartFile(file),
        });

        return dio.post<T>(
          resolvedPath,
          data: formData,
          queryParameters: resolvedOptions.queryParameters,
          options: toDioOptions(resolvedOptions),
          cancelToken: toDioCancelToken(resolvedOptions.cancelToken),
          onSendProgress: resolvedOptions.onSendProgress,
          onReceiveProgress: resolvedOptions.onReceiveProgress,
        );
      },
    );
  }

  @override
  void addInterceptor(HttpInterceptor interceptor) {
    final adapter = DioInterceptorAdapter(
      interceptor,
      clientOptions: clientOptions,
    );
    _adapters[interceptor] = adapter;
    dio.interceptors.add(adapter);
  }

  @override
  void removeInterceptor(HttpInterceptor interceptor) {
    final adapter = _adapters.remove(interceptor);
    if (adapter == null) {
      throw StateError('Interceptor not registered.');
    }
    dio.interceptors.remove(adapter);
  }

  Future<HttpResponse<T>> _request<T>(
    String path, {
    required Future<Response<dynamic>> Function(
      String path,
      ResolvedHttpRequestOptions options,
    )
    request,
    HttpRequestOptions? options,
    HttpResponseType? responseTypeOverride,
  }) async {
    try {
      final requestOptions = options ?? const HttpRequestOptions();

      final String requestPath;
      final HttpRequestOptions mergedRequestOptions;
      if (versionStrategy == null) {
        requestPath = path;
        mergedRequestOptions = requestOptions;
      } else {
        final versioned = versionStrategy!.apply(
          path: path,
          options: requestOptions,
          apiVersion: apiVersion,
        );
        requestPath = versioned.path;
        mergedRequestOptions = versioned.options;
      }

      var resolved = mergedRequestOptions.resolve(clientOptions);
      if (responseTypeOverride != null) {
        resolved = resolved.copyWith(responseType: responseTypeOverride);
      }

      final response = await request(requestPath, resolved);
      return _decode(response);
    } on Object catch (error, stackTrace) {
      throw errorMapper.map(error, stackTrace: stackTrace);
    }
  }

  HttpResponse<T> _decode<T>(Response<dynamic> response) {
    final mapped = toHttpResponse<T>(response);
    final statusCode = mapped.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      return mapped;
    }

    throw errorMapper.map(
      HttpResponseException(
        statusCode: statusCode,
        rawBody: response.data,
      ),
    );
  }

  MultipartFile _toMultipartFile(HttpMultipartFile file) {
    if (file.bytes != null) {
      return MultipartFile.fromBytes(
        file.bytes!,
        filename: file.filename,
        contentType: file.contentType == null
            ? null
            : DioMediaType.parse(file.contentType!),
      );
    }

    return MultipartFile.fromStream(
      () => file.stream!,
      file.bytes?.length ?? 0,
      filename: file.filename,
      contentType: file.contentType == null
          ? null
          : DioMediaType.parse(file.contentType!),
    );
  }
}
