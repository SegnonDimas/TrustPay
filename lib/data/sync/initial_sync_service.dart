import '../datasources/local/account_local_datasource.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/local/category_local_datasource.dart';
import '../datasources/local/sync_snapshot_local_datasource.dart';
import '../datasources/local/transaction_local_datasource.dart';
import '../datasources/remote/initial_sync_remote_datasource.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';

class InitialSyncService {
  final InitialSyncRemoteDataSource remoteDataSource;
  final AuthLocalDataSource authLocalDataSource;
  final AccountLocalDataSource accountLocalDataSource;
  final CategoryLocalDataSource categoryLocalDataSource;
  final TransactionLocalDataSource transactionLocalDataSource;
  final SyncSnapshotLocalDataSource syncSnapshotLocalDataSource;

  InitialSyncService({
    required this.remoteDataSource,
    required this.authLocalDataSource,
    required this.accountLocalDataSource,
    required this.categoryLocalDataSource,
    required this.transactionLocalDataSource,
    required this.syncSnapshotLocalDataSource,
  });

  Future<void> hydrateInitialData() async {
    final snapshot = await remoteDataSource.fetchInitialSnapshot();

    final user = snapshot['user'] as Map<String, dynamic>? ?? const {};
    final accounts = (snapshot['accounts'] as List<dynamic>? ?? const [])
        .map((item) => AccountModel.fromRemoteJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    final categories = (snapshot['categories'] as List<dynamic>? ?? const [])
        .map((item) => CategoryModel.fromRemoteJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    final transactions = (snapshot['transactions'] as List<dynamic>? ?? const [])
        .map((item) => TransactionModel.fromRemoteJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    final budgets = (snapshot['budgets'] as List<dynamic>? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final wallets = (snapshot['mobile_money_wallets'] as List<dynamic>? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    await authLocalDataSource.saveUserProfile(UserModel.fromJson(user));
    await accountLocalDataSource.clearAndReplace(accounts);
    await categoryLocalDataSource.clearAndReplace(categories);
    await transactionLocalDataSource.clearAndReplace(transactions);
    await syncSnapshotLocalDataSource.saveBudgets(budgets);
    await syncSnapshotLocalDataSource.saveWallets(wallets);
    final generatedAt = snapshot['generated_at']?.toString();
    if (generatedAt != null && generatedAt.isNotEmpty) {
      await syncSnapshotLocalDataSource.saveGeneratedAt(generatedAt);
    }
  }
}
