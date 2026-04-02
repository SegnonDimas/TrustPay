import 'package:dio/dio.dart';

import '../../../config/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/repositories/accounting_repository.dart';

abstract class AccountingRemoteDataSource {
  Future<AccountingKpis> getKpis({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<AccountingBilanPeriod>> getBilans({
    required String granularity,
    required DateTime startDate,
    required DateTime endDate,
  });
}

class AccountingRemoteDataSourceImpl implements AccountingRemoteDataSource {
  final Dio _dio;

  AccountingRemoteDataSourceImpl(this._dio);

  @override
  Future<AccountingKpis> getKpis({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConfig.accountingKpis,
        queryParameters: {
          'start_date': _formatDate(startDate),
          'end_date': _formatDate(endDate),
        },
      );
      final json = response.data ?? <String, dynamic>{};
      return AccountingKpis(
        transactionCount: _toInt(json['nombre_transactions']),
        averageIncomeTicket: _toNullableDouble(json['ticket_moyen_revenus']),
        revenueGrowthRatePct: _toNullableDouble(
          json['taux_croissance_chiffre_affaires_pct'],
        ),
        revenueVariabilityCoefficient: _toNullableDouble(
          json['variabilite_revenus_coefficient'],
        ),
        totalRevenue: _toDouble(json['chiffre_affaires_total']),
        previousPeriodRevenue: _toDouble(
          json['chiffre_affaires_periode_precedente'],
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<AccountingBilanPeriod>> getBilans({
    required String granularity,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConfig.accountingBilans,
        queryParameters: {
          'granularity': granularity,
          'start_date': _formatDate(startDate),
          'end_date': _formatDate(endDate),
        },
      );
      final json = response.data ?? <String, dynamic>{};
      final periods = (json['periods'] as List<dynamic>? ?? const []);

      return periods.map((e) {
        final row = e as Map<String, dynamic>? ?? <String, dynamic>{};
        return AccountingBilanPeriod(
          label: (row['label'] as String?) ?? '',
          startDate: (row['start_date'] as String?) ?? '',
          endDate: (row['end_date'] as String?) ?? '',
          revenue: _toDouble(row['chiffre_affaires']),
          expense: _toDouble(row['depenses']),
          netResult: _toDouble(row['resultat_net']),
          transactionCount: _toInt(row['nombre_transactions']),
        );
      }).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  double _toDouble(dynamic value) => double.tryParse(value.toString()) ?? 0;

  double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  int _toInt(dynamic value) => int.tryParse(value.toString()) ?? 0;
}
