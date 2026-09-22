import 'package:dio/dio.dart';
import 'package:falconet/src/network/base/base.dart';
import 'package:falconet/src/network/dio/dio_options_mapper.dart';

class DioInterceptorAdapter extends Interceptor {
  DioInterceptorAdapter(
    this.interceptor, {
    required this.clientOptions,
  });

  final HttpInterceptor interceptor;
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
    final resolved = context.options.resolve(clientOptions);
    applyResolvedOptionsToRequest(options, resolved);
  }
}
