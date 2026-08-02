import '../datasources/local/account_local_datasource.dart';
import '../datasources/local/category_local_datasource.dart';
import '../datasources/local/transaction_local_datasource.dart';
import '../local/local_finance_analytics.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../datasources/remote/statistics_remote_datasource.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  final StatisticsRemoteDataSource remoteDataSource;
  final TransactionLocalDataSource transactionLocalDataSource;
  final AccountLocalDataSource accountLocalDataSource;
  final CategoryLocalDataSource categoryLocalDataSource;
  final LocalFinanceAnalytics analytics;

  StatisticsRepositoryImpl({
    required this.remoteDataSource,
    required this.transactionLocalDataSource,
    required this.accountLocalDataSource,
    required this.categoryLocalDataSource,
    required this.analytics,
  });

  @override
  Future<StatisticsSummary> getSummary() async {
    final transactions = await transactionLocalDataSource.getTransactions();
    final accounts = await accountLocalDataSource.getAccounts();
    final localSummary = analytics.buildSummary(transactions, accounts);
    try {
      return await remoteDataSource.getSummary();
    } catch (_) {
      return localSummary;
    }
  }

  @override
  Future<List<CategoryBreakdown>> getCategoryBreakdown() async {
    final transactions = await transactionLocalDataSource.getTransactions();
    final categories = await categoryLocalDataSource.getCategories();
    final localBreakdown =
        analytics.buildCategoryBreakdown(transactions, categories);
    try {
      return await remoteDataSource.getCategoryBreakdown();
    } catch (_) {
      return localBreakdown;
    }
  }

  @override
  Future<List<TrendPoint>> getTrends({String granularity = 'month'}) async {
    final transactions = await transactionLocalDataSource.getTransactions();
    final localTrends = analytics.buildMonthlyTrends(transactions);
    try {
      return await remoteDataSource.getTrends(granularity: granularity);
    } catch (_) {
      return localTrends;
    }
  }
}
