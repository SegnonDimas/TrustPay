import '../../domain/repositories/accounting_repository.dart';
import '../datasources/remote/accounting_remote_datasource.dart';

class AccountingRepositoryImpl implements AccountingRepository {
  final AccountingRemoteDataSource remoteDataSource;

  AccountingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AccountingKpis> getKpis({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return remoteDataSource.getKpis(startDate: startDate, endDate: endDate);
  }

  @override
  Future<List<AccountingBilanPeriod>> getBilans({
    required String granularity,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return remoteDataSource.getBilans(
      granularity: granularity,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
