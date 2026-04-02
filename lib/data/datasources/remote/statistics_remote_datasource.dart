import 'package:dio/dio.dart';

import '../../../config/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/repositories/statistics_repository.dart';

abstract class StatisticsRemoteDataSource {
  Future<StatisticsSummary> getSummary();
  Future<List<CategoryBreakdown>> getCategoryBreakdown();
  Future<List<TrendPoint>> getTrends({String granularity = 'month'});
}

class StatisticsRemoteDataSourceImpl implements StatisticsRemoteDataSource {
  final Dio _dio;

  StatisticsRemoteDataSourceImpl(this._dio);

  @override
  Future<StatisticsSummary> getSummary() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConfig.statisticsSummary,
      );
      final json = response.data ?? <String, dynamic>{};
      return StatisticsSummary(
        totalExpense: double.tryParse(json['total_expense'].toString()) ?? 0,
        totalIncome: double.tryParse(json['total_income'].toString()) ?? 0,
        net: double.tryParse(json['net'].toString()) ?? 0,
        totalAccountsBalance:
            double.tryParse(json['total_accounts_balance'].toString()) ?? 0,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<CategoryBreakdown>> getCategoryBreakdown() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConfig.statisticsByCategory,
      );
      final json = response.data ?? <String, dynamic>{};
      final items = (json['by_category'] as List<dynamic>? ?? const []);
      return items
          .map(
            (e) => CategoryBreakdown(
              name: (e['category_name'] as String?) ?? 'Sans catégorie',
              total: double.tryParse(e['total'].toString()) ?? 0,
              percentage: double.tryParse(e['percentage'].toString()) ?? 0,
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<TrendPoint>> getTrends({String granularity = 'month'}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConfig.statisticsTrends,
        queryParameters: {'granularity': granularity},
      );
      final json = response.data ?? <String, dynamic>{};
      final points = (json['points'] as List<dynamic>? ?? const []);
      return points
          .map(
            (e) => TrendPoint(
              period: (e['period'] as String?) ?? '',
              expense: double.tryParse(e['expense'].toString()) ?? 0,
              income: double.tryParse(e['income'].toString()) ?? 0,
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
