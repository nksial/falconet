import 'package:falconet/src/network/base/http/http_cancel_token.dart';
import 'package:falconet/src/network/base/http/http_client_options.dart';
import 'package:falconet/src/network/base/http/http_types.dart';

class HttpRequestOptions {
  const HttpRequestOptions({
    this.headers,
    this.queryParameters,
    this.connectTimeout,
    this.receiveTimeout,
    this.sendTimeout,
    this.transformTimeout,
    this.responseType,
    this.contentType,
    this.validateStatus,
    this.receiveDataWhenStatusError,
    this.followRedirects,
    this.maxRedirects,
    this.persistentConnection,
    this.listFormat,
    this.preserveHeaderCase,
    this.requestEncoder,
    this.responseDecoder,
    this.cancelToken,
    this.extra,
    this.onSendProgress,
    this.onReceiveProgress,
  });

  final Map<String, dynamic>? headers;
  final Map<String, dynamic>? queryParameters;
  final Duration? connectTimeout;
  final Duration? receiveTimeout;
  final Duration? sendTimeout;
  final Duration? transformTimeout;
  final HttpResponseType? responseType;
  final String? contentType;
  final HttpStatusValidator? validateStatus;
  final bool? receiveDataWhenStatusError;
  final bool? followRedirects;
  final int? maxRedirects;
  final bool? persistentConnection;
  final HttpListFormat? listFormat;
  final bool? preserveHeaderCase;
  final HttpRequestEncoder? requestEncoder;
  final HttpResponseDecoder? responseDecoder;
  final HttpCancelToken? cancelToken;
  final Map<String, dynamic>? extra;
  final HttpProgressCallback? onSendProgress;
  final HttpProgressCallback? onReceiveProgress;

  HttpRequestOptions copyWith({
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    Duration? transformTimeout,
    HttpResponseType? responseType,
    String? contentType,
    HttpStatusValidator? validateStatus,
    bool? receiveDataWhenStatusError,
    bool? followRedirects,
    int? maxRedirects,
    bool? persistentConnection,
    HttpListFormat? listFormat,
    bool? preserveHeaderCase,
    HttpRequestEncoder? requestEncoder,
    HttpResponseDecoder? responseDecoder,
    HttpCancelToken? cancelToken,
    Map<String, dynamic>? extra,
    HttpProgressCallback? onSendProgress,
    HttpProgressCallback? onReceiveProgress,
  }) {
    return HttpRequestOptions(
      headers: headers ?? this.headers,
      queryParameters: queryParameters ?? this.queryParameters,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      transformTimeout: transformTimeout ?? this.transformTimeout,
      responseType: responseType ?? this.responseType,
      contentType: contentType ?? this.contentType,
      validateStatus: validateStatus ?? this.validateStatus,
      receiveDataWhenStatusError:
          receiveDataWhenStatusError ?? this.receiveDataWhenStatusError,
      followRedirects: followRedirects ?? this.followRedirects,
      maxRedirects: maxRedirects ?? this.maxRedirects,
      persistentConnection: persistentConnection ?? this.persistentConnection,
      listFormat: listFormat ?? this.listFormat,
      preserveHeaderCase: preserveHeaderCase ?? this.preserveHeaderCase,
      requestEncoder: requestEncoder ?? this.requestEncoder,
      responseDecoder: responseDecoder ?? this.responseDecoder,
      cancelToken: cancelToken ?? this.cancelToken,
      extra: extra ?? this.extra,
      onSendProgress: onSendProgress ?? this.onSendProgress,
      onReceiveProgress: onReceiveProgress ?? this.onReceiveProgress,
    );
  }

  /// Merges per-request overrides with client-level defaults.
  ResolvedHttpRequestOptions resolve(HttpClientOptions clientOptions) {
    return ResolvedHttpRequestOptions(
      headers: {
        ...clientOptions.defaultHeaders,
        ...?headers,
      },
      queryParameters: {
        ...clientOptions.defaultQueryParameters,
        ...?queryParameters,
      },
      connectTimeout: connectTimeout ?? clientOptions.connectTimeout,
      receiveTimeout: receiveTimeout ?? clientOptions.receiveTimeout,
      sendTimeout: sendTimeout ?? clientOptions.sendTimeout,
      transformTimeout: transformTimeout ?? clientOptions.transformTimeout,
      responseType: responseType ?? clientOptions.responseType,
      contentType: contentType ?? clientOptions.contentType,
      validateStatus: validateStatus ?? clientOptions.validateStatus,
      receiveDataWhenStatusError:
          receiveDataWhenStatusError ??
          clientOptions.receiveDataWhenStatusError,
      followRedirects: followRedirects ?? clientOptions.followRedirects,
      maxRedirects: maxRedirects ?? clientOptions.maxRedirects,
      persistentConnection:
          persistentConnection ?? clientOptions.persistentConnection,
      listFormat: listFormat ?? clientOptions.listFormat,
      preserveHeaderCase:
          preserveHeaderCase ?? clientOptions.preserveHeaderCase,
      requestEncoder: requestEncoder ?? clientOptions.requestEncoder,
      responseDecoder: responseDecoder ?? clientOptions.responseDecoder,
      cancelToken: cancelToken,
      extra: {
        ...clientOptions.extra,
        ...?extra,
      },
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }
}

/// Fully resolved request options after merging client defaults.
class ResolvedHttpRequestOptions {
  const ResolvedHttpRequestOptions({
    required this.headers,
    required this.queryParameters,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.sendTimeout,
    required this.transformTimeout,
    required this.responseType,
    required this.contentType,
    required this.validateStatus,
    required this.receiveDataWhenStatusError,
    required this.followRedirects,
    required this.maxRedirects,
    required this.persistentConnection,
    required this.listFormat,
    required this.preserveHeaderCase,
    required this.requestEncoder,
    required this.responseDecoder,
    required this.cancelToken,
    required this.extra,
    this.onSendProgress,
    this.onReceiveProgress,
  });

  final Map<String, dynamic> headers;
  final Map<String, dynamic> queryParameters;
  final Duration? connectTimeout;
  final Duration? receiveTimeout;
  final Duration? sendTimeout;
  final Duration? transformTimeout;
  final HttpResponseType responseType;
  final String? contentType;
  final HttpStatusValidator validateStatus;
  final bool receiveDataWhenStatusError;
  final bool followRedirects;
  final int maxRedirects;
  final bool persistentConnection;
  final HttpListFormat listFormat;
  final bool preserveHeaderCase;
  final HttpRequestEncoder? requestEncoder;
  final HttpResponseDecoder? responseDecoder;
  final HttpCancelToken? cancelToken;
  final Map<String, dynamic> extra;
  final HttpProgressCallback? onSendProgress;
  final HttpProgressCallback? onReceiveProgress;

  ResolvedHttpRequestOptions copyWith({
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    Duration? transformTimeout,
    HttpResponseType? responseType,
    String? contentType,
    HttpStatusValidator? validateStatus,
    bool? receiveDataWhenStatusError,
    bool? followRedirects,
    int? maxRedirects,
    bool? persistentConnection,
    HttpListFormat? listFormat,
    bool? preserveHeaderCase,
    HttpRequestEncoder? requestEncoder,
    HttpResponseDecoder? responseDecoder,
    HttpCancelToken? cancelToken,
    Map<String, dynamic>? extra,
    HttpProgressCallback? onSendProgress,
    HttpProgressCallback? onReceiveProgress,
  }) {
    return ResolvedHttpRequestOptions(
      headers: headers ?? this.headers,
      queryParameters: queryParameters ?? this.queryParameters,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      transformTimeout: transformTimeout ?? this.transformTimeout,
      responseType: responseType ?? this.responseType,
      contentType: contentType ?? this.contentType,
      validateStatus: validateStatus ?? this.validateStatus,
      receiveDataWhenStatusError:
          receiveDataWhenStatusError ?? this.receiveDataWhenStatusError,
      followRedirects: followRedirects ?? this.followRedirects,
      maxRedirects: maxRedirects ?? this.maxRedirects,
      persistentConnection: persistentConnection ?? this.persistentConnection,
      listFormat: listFormat ?? this.listFormat,
      preserveHeaderCase: preserveHeaderCase ?? this.preserveHeaderCase,
      requestEncoder: requestEncoder ?? this.requestEncoder,
      responseDecoder: responseDecoder ?? this.responseDecoder,
      cancelToken: cancelToken ?? this.cancelToken,
      extra: extra ?? this.extra,
      onSendProgress: onSendProgress ?? this.onSendProgress,
      onReceiveProgress: onReceiveProgress ?? this.onReceiveProgress,
    );
  }
}
