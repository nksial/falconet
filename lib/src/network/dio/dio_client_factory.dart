import 'package:dio/dio.dart';
import 'package:falconet/src/network/base/base.dart';
import 'package:falconet/src/network/dio/dio_client.dart';
import 'package:falconet/src/network/dio/dio_interceptor_adapter.dart';
import 'package:falconet/src/network/dio/dio_options_mapper.dart';

HttpClient createHttpClient({
  required HttpClientOptions options,
  required HttpErrorMapper errorMapper,
  ApiVersionStrategy? versionStrategy,
  List<HttpInterceptor> interceptors = const [],
}) {
  final dio = Dio(toDioBaseOptions(options: options));

  for (final interceptor in interceptors) {
    dio.interceptors.add(
      DioInterceptorAdapter(
        interceptor,
        clientOptions: options,
      ),
    );
  }

  return DioClient(
    dio: dio,
    clientOptions: options,
    errorMapper: errorMapper,
    apiVersion: options.apiVersion,
    versionStrategy: versionStrategy,
  );
}
