import 'package:dio/dio.dart';

class DioClient {
  final Dio _dio;

  DioClient(this._dio) {
    _dio
      ..options.baseUrl = 'https://api.trustpay.bj/api/v1' // Example URL
      ..options.connectTimeout = const Duration(seconds: 15)
      ..options.receiveTimeout = const Duration(seconds: 15)
      ..options.responseType = ResponseType.json
      ..interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ))
      ..interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add JWT Token here from local storage
          // final token = ...
          // options.headers['Authorization'] = 'Bearer $token';
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            // Handle Token Refresh or Logout
          }
          return handler.next(e);
        },
      ));
  }

  Dio get dio => _dio;
}
