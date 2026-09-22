import 'package:dio/dio.dart';
import 'package:falconet/falconet.dart';
import 'package:falconet/src/network/dio/dio.dart';

typedef OnRequestStub =
    void Function(
      RequestOptions options,
      RequestInterceptorHandler handler,
    );

Dio buildStubbedDio({
  String baseUrl = 'https://example.com',
  OnRequestStub? onRequest,
  Object? data = const {'ok': true},
  int statusCode = 200,
  String? statusMessage,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      validateStatus: (_) => true,
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest:
          onRequest ??
          (options, handler) {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: statusCode,
                statusMessage: statusMessage,
                data: data,
              ),
            );
          },
    ),
  );
  return dio;
}

DioClient buildDioClient({
  required Dio dio,
  HttpClientOptions clientOptions = const HttpClientOptions(),
  HttpErrorMapper errorMapper = const DefaultHttpErrorMapper(),
  ApiVersionStrategy? versionStrategy,
  String? apiVersion,
}) {
  return DioClient(
    dio: dio,
    clientOptions: clientOptions,
    errorMapper: errorMapper,
    versionStrategy: versionStrategy,
    apiVersion: apiVersion,
  );
}

ResolvedHttpRequestOptions resolvedOptions({
  Map<String, dynamic> headers = const {},
  Map<String, dynamic> queryParameters = const {},
  Duration? connectTimeout,
  Duration? receiveTimeout,
  Duration? sendTimeout,
  Duration? transformTimeout,
  HttpResponseType responseType = HttpResponseType.json,
  String? contentType,
  HttpStatusValidator validateStatus = httpDefaultValidateStatus,
  bool receiveDataWhenStatusError = true,
  bool followRedirects = true,
  int maxRedirects = 5,
  bool persistentConnection = true,
  HttpListFormat listFormat = HttpListFormat.multi,
  bool preserveHeaderCase = false,
  HttpRequestEncoder? requestEncoder,
  HttpResponseDecoder? responseDecoder,
  HttpCancelToken? cancelToken,
  Map<String, dynamic> extra = const {},
  HttpProgressCallback? onSendProgress,
  HttpProgressCallback? onReceiveProgress,
}) {
  return ResolvedHttpRequestOptions(
    headers: headers,
    queryParameters: queryParameters,
    connectTimeout: connectTimeout,
    receiveTimeout: receiveTimeout,
    sendTimeout: sendTimeout,
    transformTimeout: transformTimeout,
    responseType: responseType,
    contentType: contentType,
    validateStatus: validateStatus,
    receiveDataWhenStatusError: receiveDataWhenStatusError,
    followRedirects: followRedirects,
    maxRedirects: maxRedirects,
    persistentConnection: persistentConnection,
    listFormat: listFormat,
    preserveHeaderCase: preserveHeaderCase,
    requestEncoder: requestEncoder,
    responseDecoder: responseDecoder,
    cancelToken: cancelToken,
    extra: extra,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
  );
}
