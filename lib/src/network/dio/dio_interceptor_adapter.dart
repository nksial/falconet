import 'package:dio/dio.dart';
import 'package:falconet/src/network/base/base.dart';
import 'package:falconet/src/network/dio/dio_options_mapper.dart';

class DioInterceptorAdapter extends Interceptor {
  DioInterceptorAdapter(
    this.interceptor, {
    required this.dio,
    required this.clientOptions,
  });

  final HttpInterceptor interceptor;
  final Dio dio;
  final HttpClientOptions clientOptions;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final context = HttpInterceptorContext(
      path: options.path,
      options: fromDioRequestOptions(options),
    );

    try {
      await interceptor.onRequest(context);
      _applyRequestContext(options, context);
      handler.next(options);
    } on Object catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final context = HttpInterceptorContext(
      path: response.requestOptions.path,
      options: fromDioRequestOptions(response.requestOptions),
      response: _toHttpResponse(response),
    );

    try {
      await interceptor.onResponse(context);
      if (context.response != null) {
        applyHttpResponseToDio(response, context.response!);
      }
      handler.next(response);
    } on Object catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final context = HttpInterceptorContext(
      path: err.requestOptions.path,
      options: fromDioRequestOptions(err.requestOptions),
      response: err.response == null ? null : _toHttpResponse(err.response!),
      error: err.error ?? err,
    );

    try {
      await interceptor.onError(context);

      if (context.retryRequest) {
        final requestOptions = err.requestOptions;
        _applyRequestContext(requestOptions, context);
        try {
          final response = await dio.fetch<dynamic>(requestOptions);
          handler.resolve(response);
        } on DioException catch (retryError) {
          handler.next(retryError);
        } on Object catch (error, stackTrace) {
          handler.reject(
            DioException(
              requestOptions: requestOptions,
              error: error,
              stackTrace: stackTrace,
            ),
          );
        }
        return;
      }

      if (context.error is DioException) {
        handler.next(context.error! as DioException);
        return;
      }
      if (context.error != null) {
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            response: err.response,
            error: context.error,
          ),
        );
        return;
      }
      handler.next(err);
    } on Object catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  HttpResponse<dynamic> _toHttpResponse(Response<dynamic> response) {
    return toHttpResponse<dynamic>(response);
  }

  void _applyRequestContext(
    RequestOptions options,
    HttpInterceptorContext context,
  ) {
    options.path = context.path;
    final resolved = context.options.resolveInterceptorMutation(clientOptions);
    applyResolvedOptionsToRequest(options, resolved);
  }
}
