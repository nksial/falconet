import 'package:dio/dio.dart';
import 'package:falconet/src/network/base/base.dart';
import 'package:falconet/src/network/dio/dio_cancel_token.dart';

BaseOptions toDioBaseOptions({
  required HttpClientOptions options,
}) {
  final headers = _headersForDio(
    options.defaultHeaders,
    contentType: options.contentType,
  );
  return BaseOptions(
    baseUrl: options.baseUrl,
    connectTimeout: options.connectTimeout,
    receiveTimeout: options.receiveTimeout,
    sendTimeout: options.sendTimeout,
    transformTimeout: options.transformTimeout,
    queryParameters: Map<String, dynamic>.from(options.defaultQueryParameters),
    headers: headers,
    responseType: _toDioResponseType(options.responseType),
    contentType: options.contentType,
    validateStatus: options.validateStatus,
    receiveDataWhenStatusError: options.receiveDataWhenStatusError,
    followRedirects: options.followRedirects,
    maxRedirects: options.maxRedirects,
    persistentConnection: options.persistentConnection,
    listFormat: _toDioListFormat(options.listFormat),
    preserveHeaderCase: options.preserveHeaderCase,
    requestEncoder: _toDioRequestEncoder(options.requestEncoder),
    responseDecoder: _toDioResponseDecoder(options.responseDecoder),
    extra: Map<String, dynamic>.from(options.extra),
  );
}

Options toDioOptions(ResolvedHttpRequestOptions options) {
  final headers = _headersForDio(
    options.headers,
    contentType: options.contentType,
  );
  return Options(
    headers: headers,
    connectTimeout: options.connectTimeout,
    responseType: _toDioResponseType(options.responseType),
    contentType: options.contentType,
    validateStatus: options.validateStatus,
    receiveDataWhenStatusError: options.receiveDataWhenStatusError,
    followRedirects: options.followRedirects,
    maxRedirects: options.maxRedirects,
    persistentConnection: options.persistentConnection,
    sendTimeout: options.sendTimeout,
    receiveTimeout: options.receiveTimeout,
    transformTimeout: options.transformTimeout,
    listFormat: _toDioListFormat(options.listFormat),
    preserveHeaderCase: options.preserveHeaderCase,
    requestEncoder: _toDioRequestEncoder(options.requestEncoder),
    responseDecoder: _toDioResponseDecoder(options.responseDecoder),
    extra: Map<String, dynamic>.from(options.extra),
  );
}

void applyResolvedOptionsToRequest(
  RequestOptions request,
  ResolvedHttpRequestOptions options,
) {
  // Replace (don't merge) so interceptors can remove headers such as
  // Authorization. Keep any Dio/Imply content type when resolved options
  // omit it — assigning null would clear Content-Type and force
  // application/x-www-form-urlencoded for Map bodies.
  final previousContentType = request.contentType;

  request.headers
    ..clear()
    ..addAll(options.headers);
  request.queryParameters
    ..clear()
    ..addAll(options.queryParameters);
  request
    ..connectTimeout = options.connectTimeout
    ..receiveTimeout = options.receiveTimeout
    ..sendTimeout = options.sendTimeout
    ..transformTimeout = options.transformTimeout
    ..responseType = _toDioResponseType(options.responseType)
    ..validateStatus = options.validateStatus
    ..receiveDataWhenStatusError = options.receiveDataWhenStatusError
    ..followRedirects = options.followRedirects
    ..maxRedirects = options.maxRedirects
    ..persistentConnection = options.persistentConnection
    ..listFormat = _toDioListFormat(options.listFormat)
    ..preserveHeaderCase = options.preserveHeaderCase
    ..requestEncoder = _toDioRequestEncoder(options.requestEncoder)
    ..responseDecoder = _toDioResponseDecoder(options.responseDecoder)
    ..cancelToken = toDioCancelToken(options.cancelToken)
    ..onSendProgress = options.onSendProgress
    ..onReceiveProgress = options.onReceiveProgress;
  request.extra
    ..clear()
    ..addAll(options.extra);

  if (options.contentType != null) {
    request.contentType = options.contentType;
  } else if (previousContentType != null &&
      !_hasContentTypeHeader(request.headers)) {
    request.contentType = previousContentType;
  }
}

HttpRequestOptions fromDioRequestOptions(RequestOptions options) {
  final headers = _headersWithoutContentType(options.headers);
  return HttpRequestOptions(
    headers: headers,
    queryParameters: Map<String, dynamic>.from(options.queryParameters),
    connectTimeout: options.connectTimeout,
    receiveTimeout: options.receiveTimeout,
    sendTimeout: options.sendTimeout,
    transformTimeout: options.transformTimeout,
    responseType: _fromDioResponseType(options.responseType),
    contentType: options.contentType,
    validateStatus: options.validateStatus,
    receiveDataWhenStatusError: options.receiveDataWhenStatusError,
    followRedirects: options.followRedirects,
    maxRedirects: options.maxRedirects,
    persistentConnection: options.persistentConnection,
    listFormat: _fromDioListFormat(options.listFormat),
    preserveHeaderCase: options.preserveHeaderCase,
    cancelToken: fromDioCancelToken(options.cancelToken),
    extra: Map<String, dynamic>.from(options.extra),
    onSendProgress: options.onSendProgress,
    onReceiveProgress: options.onReceiveProgress,
  );
}

ResolvedHttpRequestOptions resolvedFromDioRequestOptions(
  RequestOptions options,
) {
  final headers = _headersWithoutContentType(options.headers);
  return ResolvedHttpRequestOptions(
    headers: headers,
    queryParameters: Map<String, dynamic>.from(options.queryParameters),
    connectTimeout: options.connectTimeout,
    receiveTimeout: options.receiveTimeout,
    sendTimeout: options.sendTimeout,
    transformTimeout: options.transformTimeout,
    responseType: _fromDioResponseType(options.responseType),
    contentType: options.contentType,
    validateStatus: options.validateStatus,
    receiveDataWhenStatusError: options.receiveDataWhenStatusError,
    followRedirects: options.followRedirects,
    maxRedirects: options.maxRedirects,
    persistentConnection: options.persistentConnection,
    listFormat: _fromDioListFormat(options.listFormat),
    preserveHeaderCase: options.preserveHeaderCase,
    requestEncoder: null,
    responseDecoder: null,
    cancelToken: fromDioCancelToken(options.cancelToken),
    extra: Map<String, dynamic>.from(options.extra),
    onSendProgress: options.onSendProgress,
    onReceiveProgress: options.onReceiveProgress,
  );
}

/// Prefer [contentType] as the single source of truth for Dio Options.
Map<String, dynamic> _headersForDio(
  Map<String, dynamic> headers, {
  required String? contentType,
}) {
  final mapped = Map<String, dynamic>.from(headers);
  if (contentType != null) {
    _removeContentTypeHeader(mapped);
  }
  return mapped;
}

Map<String, dynamic> _headersWithoutContentType(Map<String, dynamic> headers) {
  final mapped = Map<String, dynamic>.from(headers);
  _removeContentTypeHeader(mapped);
  return mapped;
}

void _removeContentTypeHeader(Map<String, dynamic> headers) {
  headers.removeWhere(
    (key, _) => key.toLowerCase() == Headers.contentTypeHeader,
  );
}

bool _hasContentTypeHeader(Map<String, dynamic> headers) {
  return headers.keys.any(
    (key) => key.toLowerCase() == Headers.contentTypeHeader,
  );
}

HttpResponse<T> toHttpResponse<T>(Response<dynamic> response) {
  final statusCode = response.statusCode ?? 0;
  return HttpResponse<T>(
    data: mapResponseData<T>(response),
    statusCode: statusCode,
    statusMessage: response.statusMessage,
    headers: response.headers.map.map(
      (key, value) => MapEntry(key, List<String>.from(value)),
    ),
    isRedirect: response.isRedirect,
    redirects: response.redirects
        .map(
          (record) => HttpRedirectRecord(
            statusCode: record.statusCode,
            method: record.method,
            location: record.location,
          ),
        )
        .toList(),
    extra: Map<String, dynamic>.from(response.extra),
    requestUri: response.requestOptions.uri,
  );
}

T? mapResponseData<T>(Response<dynamic> response) {
  final raw = response.data;
  if (raw is ResponseBody) {
    return HttpResponseBody(
          stream: raw.stream,
          statusCode: raw.statusCode,
          headers: Map<String, List<String>>.from(raw.headers),
          contentLength: raw.contentLength >= 0 ? raw.contentLength : null,
        )
        as T?;
  }
  return raw as T?;
}

void applyHttpResponseToDio(
  Response<dynamic> response,
  HttpResponse<dynamic> httpResponse,
) {
  response
    ..data = httpResponse.data
    ..statusCode = httpResponse.statusCode
    ..statusMessage = httpResponse.statusMessage
    ..isRedirect = httpResponse.isRedirect
    ..redirects = httpResponse.redirects
        .map(
          (record) => RedirectRecord(
            record.statusCode,
            record.method,
            record.location,
          ),
        )
        .toList();

  response.extra
    ..clear()
    ..addAll(httpResponse.extra);

  response.headers.clear();
  for (final entry in httpResponse.headers.entries) {
    response.headers.set(entry.key, entry.value);
  }
}

RequestEncoder? _toDioRequestEncoder(HttpRequestEncoder? encoder) {
  if (encoder == null) {
    return null;
  }
  return (request, options) {
    return encoder(request, resolvedFromDioRequestOptions(options));
  };
}

ResponseDecoder? _toDioResponseDecoder(HttpResponseDecoder? decoder) {
  if (decoder == null) {
    return null;
  }
  return (responseBytes, options, body) {
    return decoder(
      responseBytes,
      resolvedFromDioRequestOptions(options),
      responseBody: HttpResponseBody(
        stream: body.stream,
        statusCode: body.statusCode,
        headers: Map<String, List<String>>.from(body.headers),
        contentLength: body.contentLength >= 0 ? body.contentLength : null,
      ),
    );
  };
}

ResponseType _toDioResponseType(HttpResponseType type) {
  return switch (type) {
    HttpResponseType.json => ResponseType.json,
    HttpResponseType.plain => ResponseType.plain,
    HttpResponseType.bytes => ResponseType.bytes,
    HttpResponseType.stream => ResponseType.stream,
  };
}

HttpResponseType _fromDioResponseType(ResponseType type) {
  return switch (type) {
    ResponseType.json => HttpResponseType.json,
    ResponseType.plain => HttpResponseType.plain,
    ResponseType.bytes => HttpResponseType.bytes,
    ResponseType.stream => HttpResponseType.stream,
  };
}

ListFormat _toDioListFormat(HttpListFormat format) {
  return switch (format) {
    HttpListFormat.csv => ListFormat.csv,
    HttpListFormat.ssv => ListFormat.ssv,
    HttpListFormat.tsv => ListFormat.tsv,
    HttpListFormat.pipes => ListFormat.pipes,
    HttpListFormat.multi => ListFormat.multi,
    HttpListFormat.multiCompatible => ListFormat.multiCompatible,
  };
}

HttpListFormat _fromDioListFormat(ListFormat format) {
  return switch (format) {
    ListFormat.csv => HttpListFormat.csv,
    ListFormat.ssv => HttpListFormat.ssv,
    ListFormat.tsv => HttpListFormat.tsv,
    ListFormat.pipes => HttpListFormat.pipes,
    ListFormat.multi => HttpListFormat.multi,
    ListFormat.multiCompatible => HttpListFormat.multiCompatible,
  };
}
