import '../../domain/repositories/export_repository.dart';
import '../datasources/remote/export_remote_datasource.dart';

class ExportRepositoryImpl implements ExportRepository {
  final ExportRemoteDataSource remoteDataSource;

  ExportRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<int>> exportTransactionsCsv({
    DateTime? startDate,
    DateTime? endDate,
    String? accountId,
  }) {
    return remoteDataSource.exportTransactionsCsv(
      startDate: startDate,
      endDate: endDate,
      accountId: accountId,
    );
  }

  @override
  Future<Map<String, dynamic>> exportBackupJson() {
    return remoteDataSource.exportBackupJson();
  }

  @override
  Future<List<int>> exportAccountingBilansCsv({
    required String granularity,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return remoteDataSource.exportAccountingBilansCsv(
      granularity: granularity,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
