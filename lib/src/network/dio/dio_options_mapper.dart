import 'package:dio/dio.dart';
import 'package:falconet/src/network/base/base.dart';
import 'package:falconet/src/network/dio/dio_cancel_token.dart';

BaseOptions toDioBaseOptions({
  required HttpClientOptions options,
}) {
  return BaseOptions(
    baseUrl: options.baseUrl,
    connectTimeout: options.connectTimeout,
    receiveTimeout: options.receiveTimeout,
    sendTimeout: options.sendTimeout,
    transformTimeout: options.transformTimeout,
    queryParameters: Map<String, dynamic>.from(options.defaultQueryParameters),
    headers: Map<String, dynamic>.from(options.defaultHeaders),
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
  return Options(
    headers: Map<String, dynamic>.from(options.headers),
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
  request.headers.addAll(options.headers);
  request.queryParameters.addAll(options.queryParameters);
  request
    ..connectTimeout = options.connectTimeout
    ..receiveTimeout = options.receiveTimeout
    ..sendTimeout = options.sendTimeout
    ..transformTimeout = options.transformTimeout
    ..responseType = _toDioResponseType(options.responseType)
    ..contentType = options.contentType
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
    ..onReceiveProgress = options.onReceiveProgress
    ..extra.addAll(options.extra);
}

HttpRequestOptions fromDioRequestOptions(RequestOptions options) {
  return HttpRequestOptions(
    headers: Map<String, dynamic>.from(options.headers),
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
  return ResolvedHttpRequestOptions(
    headers: Map<String, dynamic>.from(options.headers),
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
