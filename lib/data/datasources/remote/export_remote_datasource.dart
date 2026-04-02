import 'package:dio/dio.dart';

import '../../../config/api_config.dart';
import '../../../core/network/api_exception.dart';

abstract class ExportRemoteDataSource {
  Future<List<int>> exportTransactionsCsv({
    DateTime? startDate,
    DateTime? endDate,
    String? accountId,
  });

  Future<Map<String, dynamic>> exportBackupJson();

  Future<List<int>> exportAccountingBilansCsv({
    required String granularity,
    required DateTime startDate,
    required DateTime endDate,
  });
}

class ExportRemoteDataSourceImpl implements ExportRemoteDataSource {
  final Dio _dio;

  ExportRemoteDataSourceImpl(this._dio);

  @override
  Future<List<int>> exportTransactionsCsv({
    DateTime? startDate,
    DateTime? endDate,
    String? accountId,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (startDate != null) query['start_date'] = _formatDate(startDate);
      if (endDate != null) query['end_date'] = _formatDate(endDate);
      if (accountId != null && accountId.isNotEmpty) query['account_id'] = accountId;

      final response = await _dio.get<List<int>>(
        ApiConfig.exportCsv,
        queryParameters: query.isEmpty ? null : query,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? <int>[];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> exportBackupJson() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConfig.exportJson,
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<int>> exportAccountingBilansCsv({
    required String granularity,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.get<List<int>>(
        ApiConfig.accountingExportCsv,
        queryParameters: {
          'granularity': granularity,
          'start_date': _formatDate(startDate),
          'end_date': _formatDate(endDate),
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? <int>[];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
