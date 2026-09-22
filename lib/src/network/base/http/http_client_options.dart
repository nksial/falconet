import 'package:falconet/src/network/base/http/http_types.dart';

class HttpClientOptions {
  const HttpClientOptions({
    this.baseUrl = '',
    this.connectTimeout,
    this.receiveTimeout,
    this.sendTimeout,
    this.transformTimeout,
    this.apiVersion,
    this.defaultHeaders = const {},
    this.defaultQueryParameters = const {},
    this.responseType = HttpResponseType.json,
    this.contentType,
    this.validateStatus = httpDefaultValidateStatus,
    this.receiveDataWhenStatusError = true,
    this.followRedirects = true,
    this.maxRedirects = 5,
    this.persistentConnection = true,
    this.listFormat = HttpListFormat.multi,
    this.preserveHeaderCase = false,
    this.requestEncoder,
    this.responseDecoder,
    this.extra = const {},
  });

  /// API root URL prepended to relative request paths.
  final String baseUrl;

  /// Null means no timeout limit.
  final Duration? connectTimeout;
  final Duration? receiveTimeout;
  final Duration? sendTimeout;
  final Duration? transformTimeout;

  /// When null or empty, version strategies should no-op.
  final String? apiVersion;
  final Map<String, String> defaultHeaders;
  final Map<String, dynamic> defaultQueryParameters;
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
  final Map<String, dynamic> extra;

  HttpClientOptions copyWith({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    Duration? transformTimeout,
    String? apiVersion,
    Map<String, String>? defaultHeaders,
    Map<String, dynamic>? defaultQueryParameters,
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
    Map<String, dynamic>? extra,
  }) {
    return HttpClientOptions(
      baseUrl: baseUrl ?? this.baseUrl,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      transformTimeout: transformTimeout ?? this.transformTimeout,
      apiVersion: apiVersion ?? this.apiVersion,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
      defaultQueryParameters:
          defaultQueryParameters ?? this.defaultQueryParameters,
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
      extra: extra ?? this.extra,
    );
  }
}
