abstract class ExportRepository {
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
