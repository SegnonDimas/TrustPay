import 'package:uuid/uuid.dart';

import '../../domain/entities/sync_status.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/local/transaction_local_datasource.dart';
import '../datasources/remote/transaction_remote_datasource.dart';
import '../models/transaction_model.dart';
import '../sync/transaction_sync_service.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource localDataSource;
  final TransactionRemoteDataSource remoteDataSource;
  final TransactionSyncService syncService;
  final Uuid _uuid = const Uuid();

  TransactionRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.syncService,
  });

  @override
  Future<List<Transaction>> getTransactions() async {
    final localTransactions = await localDataSource.getTransactions();
    if (localTransactions.isNotEmpty) {
      syncService.syncPendingTransactions();
      return localTransactions;
    }

    try {
      await syncService.refreshFromRemote();
      return await localDataSource.getTransactions();
    } catch (_) {
      if (localTransactions.isNotEmpty) return localTransactions;
      rethrow;
    }
  }

  @override
  Future<Transaction> addTransaction(Transaction transaction) async {
    final model = TransactionModel(
      id: transaction.id.isEmpty ? _uuid.v4() : transaction.id,
      title: transaction.title,
      amount: transaction.amount,
      date: transaction.date,
      type: transaction.type,
      category: transaction.category,
      categoryId: transaction.categoryId,
      accountId: transaction.accountId,
      toAccountId: transaction.toAccountId,
      description: transaction.description,
      serverId: transaction.serverId,
      syncStatus: SyncStatus.pendingCreate,
      isDeleted: false,
      lastModifiedAt: DateTime.now().toUtc(),
      lastSyncedAt: null,
      syncError: null,
    );

    await localDataSource.saveTransaction(model);
    await syncService.enqueueUpsert(model, operationType: 'create');
    await syncService.syncPendingTransactions();
    return (await localDataSource.getTransactionByLocalId(model.id)) ?? model;
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    final existing =
        await localDataSource.getTransactionByLocalId(transaction.id);
    final model = TransactionModel(
      id: transaction.id.isEmpty ? _uuid.v4() : transaction.id,
      title: transaction.title,
      amount: transaction.amount,
      date: transaction.date,
      type: transaction.type,
      category: transaction.category,
      categoryId: transaction.categoryId,
      accountId: transaction.accountId,
      toAccountId: transaction.toAccountId,
      description: transaction.description,
      serverId: transaction.serverId ?? existing?.serverId,
      syncStatus: existing?.serverId == null
          ? SyncStatus.pendingCreate
          : SyncStatus.pendingUpdate,
      isDeleted: false,
      lastModifiedAt: DateTime.now().toUtc(),
      lastSyncedAt: existing?.lastSyncedAt,
      syncError: null,
    );
    await localDataSource.saveTransaction(model);
    await syncService.enqueueUpsert(
      model,
      operationType: existing?.serverId == null ? 'create' : 'update',
    );
    await syncService.syncPendingTransactions();
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    final existing =
        await localDataSource.getTransactionByLocalId(transactionId);
    if (existing == null) return;

    if (existing.serverId == null || existing.serverId!.isEmpty) {
      await localDataSource.deleteTransaction(transactionId);
      return;
    }

    final pendingDelete = existing.copyWith(
      isDeleted: true,
      syncStatus: SyncStatus.pendingDelete,
      lastModifiedAt: DateTime.now().toUtc(),
      syncError: null,
    );
    await localDataSource.saveTransaction(pendingDelete);
    await syncService.enqueueDelete(pendingDelete);
    await syncService.syncPendingTransactions();
  }
}
