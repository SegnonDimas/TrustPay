import '../../domain/repositories/statistics_repository.dart';
import '../datasources/remote/statistics_remote_datasource.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  final StatisticsRemoteDataSource remoteDataSource;

  StatisticsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<StatisticsSummary> getSummary() {
    return remoteDataSource.getSummary();
  }

  @override
  Future<List<CategoryBreakdown>> getCategoryBreakdown() {
    return remoteDataSource.getCategoryBreakdown();
  }

  @override
  Future<List<TrendPoint>> getTrends({String granularity = 'month'}) {
    return remoteDataSource.getTrends(granularity: granularity);
  }
}
