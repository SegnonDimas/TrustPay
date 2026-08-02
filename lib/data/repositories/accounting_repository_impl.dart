import '../../domain/repositories/accounting_repository.dart';
import '../datasources/local/transaction_local_datasource.dart';
import '../local/local_finance_analytics.dart';
import '../datasources/remote/accounting_remote_datasource.dart';

class AccountingRepositoryImpl implements AccountingRepository {
  final AccountingRemoteDataSource remoteDataSource;
  final TransactionLocalDataSource transactionLocalDataSource;
  final LocalFinanceAnalytics analytics;

  AccountingRepositoryImpl({
    required this.remoteDataSource,
    required this.transactionLocalDataSource,
    required this.analytics,
  });

  @override
  Future<AccountingKpis> getKpis({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final transactions = await transactionLocalDataSource.getTransactions();
    final localKpis = analytics.buildKpis(
      transactions,
      startDate: startDate,
      endDate: endDate,
    );
    try {
      return await remoteDataSource.getKpis(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (_) {
      return localKpis;
    }
  }

  @override
  Future<List<AccountingBilanPeriod>> getBilans({
    required String granularity,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final transactions = await transactionLocalDataSource.getTransactions();
    final localBilans = analytics.buildMonthlyBilans(
      transactions,
      startDate: startDate,
      endDate: endDate,
    );
    try {
      return await remoteDataSource.getBilans(
        granularity: granularity,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (_) {
      return localBilans;
    }
  }
}
