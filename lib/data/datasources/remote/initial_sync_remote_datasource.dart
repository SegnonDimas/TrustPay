import 'package:dio/dio.dart';

import '../../../config/api_config.dart';
import '../../../core/network/api_exception.dart';

abstract class InitialSyncRemoteDataSource {
  Future<Map<String, dynamic>> fetchInitialSnapshot();
}

class InitialSyncRemoteDataSourceImpl implements InitialSyncRemoteDataSource {
  final Dio _dio;

  InitialSyncRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> fetchInitialSnapshot() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConfig.syncInitial,
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
