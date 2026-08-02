import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../../data/datasources/local/auth_local_datasource.dart';

class DioClient {
  final Dio _dio;
  final AuthLocalDataSource _authLocalDataSource;

  /// Rafraîchissement en cours : les autres 401 attendent cette future puis rejouent la requête.
  Future<void>? _refreshFuture;

  DioClient(this._dio, this._authLocalDataSource) {
    _dio
      ..options.baseUrl = ApiConfig.baseUrl
      ..options.connectTimeout = const Duration(seconds: 15)
      ..options.receiveTimeout = const Duration(seconds: 15)
      ..options.responseType = ResponseType.json
      ..interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ))
      ..interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await _authLocalDataSource.getAccessToken();
          if (accessToken != null && accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          handler.next(options);
        },
        onError: (DioException e, handler) async {
          final isRetriable401 =
              e.response?.statusCode == 401 &&
              e.requestOptions.path != ApiConfig.login &&
              e.requestOptions.path != ApiConfig.register &&
              e.requestOptions.path != ApiConfig.refresh &&
              e.requestOptions.extra['retried'] != true;

          if (!isRetriable401) {
            handler.next(e);
            return;
          }

          try {
            if (_refreshFuture == null) {
              _refreshFuture = _refreshAccessToken().whenComplete(() {
                _refreshFuture = null;
              });
            }
            await _refreshFuture;
          } catch (_) {
            await _authLocalDataSource.clearTokens();
            handler.next(e);
            return;
          }

          final accessToken = await _authLocalDataSource.getAccessToken();
          if (accessToken == null || accessToken.isEmpty) {
            handler.next(e);
            return;
          }

          final options = e.requestOptions;
          options.headers['Authorization'] = 'Bearer $accessToken';
          options.extra['retried'] = true;
          try {
            final response = await _dio.fetch<dynamic>(options);
            handler.resolve(response);
          } on DioException catch (retryErr) {
            handler.next(retryErr);
          }
        },
      ));
  }

  Future<void> _refreshAccessToken() async {
    final refreshToken = await _authLocalDataSource.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('missing refresh token');
    }

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,
      ),
    );

    final refreshResponse = await refreshDio.post<Map<String, dynamic>>(
      ApiConfig.refresh,
      data: {'refresh': refreshToken},
    );

    final newAccess = refreshResponse.data?['access'] as String?;
    final newRefresh =
        (refreshResponse.data?['refresh'] as String?) ?? refreshToken;
    if (newAccess == null || newAccess.isEmpty) {
      throw StateError('empty access from refresh');
    }

    await _authLocalDataSource.saveTokens(
      accessToken: newAccess,
      refreshToken: newRefresh,
    );
  }

  Dio get dio => _dio;
}
