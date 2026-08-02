import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/sync_status.dart';
import '../datasources/local/account_local_datasource.dart';
import '../datasources/local/category_local_datasource.dart';
import '../datasources/local/sync_operation_local_datasource.dart';
import '../datasources/local/transaction_local_datasource.dart';
import '../datasources/remote/transaction_remote_datasource.dart';
import '../models/sync_operation_model.dart';
import '../models/transaction_model.dart';

class TransactionSyncService {
  final TransactionLocalDataSource localDataSource;
  final AccountLocalDataSource accountLocalDataSource;
  final CategoryLocalDataSource categoryLocalDataSource;
  final SyncOperationLocalDataSource operationLocalDataSource;
  final TransactionRemoteDataSource remoteDataSource;
  final Connectivity connectivity;
  final Uuid uuid;
  bool _isSyncing = false;

  TransactionSyncService({
    required this.localDataSource,
    required this.accountLocalDataSource,
    required this.categoryLocalDataSource,
    required this.operationLocalDataSource,
    required this.remoteDataSource,
    required this.connectivity,
    Uuid? uuid,
  }) : uuid = uuid ?? const Uuid();

  Future<void> enqueueUpsert(
    TransactionModel transaction, {
    required String operationType,
  }) async {
    await operationLocalDataSource.deleteOperationsForEntity(
      'transaction',
      transaction.id,
    );
    await operationLocalDataSource.putOperation(
      SyncOperationModel(
        id: uuid.v4(),
        entityType: 'transaction',
        entityLocalId: transaction.id,
        operationType: operationType,
        payload: transaction.toJson(),
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> enqueueDelete(TransactionModel transaction) async {
    await operationLocalDataSource.deleteOperationsForEntity(
      'transaction',
      transaction.id,
    );
    await operationLocalDataSource.putOperation(
      SyncOperationModel(
        id: uuid.v4(),
        entityType: 'transaction',
        entityLocalId: transaction.id,
        operationType: 'delete',
        payload: transaction.toJson(),
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<bool> hasConnectivity() async {
    final result = await connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<void> syncPendingTransactions() async {
    if (_isSyncing) return;
    if (!await hasConnectivity()) return;

    _isSyncing = true;
    try {
      final operations = await operationLocalDataSource.getOperations(
        entityType: 'transaction',
      );
      if (operations.isEmpty) {
        await refreshFromRemote();
        return;
      }

      final upserts = <String, TransactionModel>{};
      final deletes = <SyncOperationModel>[];

      for (final operation in operations) {
        final transaction = await localDataSource.getTransactionByLocalId(
          operation.entityLocalId,
        );

        if (operation.operationType == 'delete') {
          deletes.add(operation);
          continue;
        }
        if (transaction == null) {
          await operationLocalDataSource.deleteOperation(operation.id);
          continue;
        }

        upserts[transaction.id] = transaction.copyWith(
          syncStatus: SyncStatus.syncing,
          syncError: null,
        );
      }

      if (upserts.isNotEmpty) {
        final syncableTransactions = <TransactionModel>[];
        for (final transaction in upserts.values) {
          final resolved = await _resolveReferences(transaction);
          if (resolved == null) {
            await localDataSource.saveTransaction(
              transaction.copyWith(
                syncStatus: SyncStatus.error,
                syncError:
                    'Waiting for synced account/category references before upload.',
              ),
            );
            continue;
          }
          syncableTransactions.add(
            resolved.copyWith(syncStatus: SyncStatus.syncing, syncError: null),
          );
        }

        await localDataSource.saveTransactions(syncableTransactions);
        if (syncableTransactions.isNotEmpty) {
          final results = await remoteDataSource.bulkSyncTransactions(
            syncableTransactions,
          );
          for (final result in results) {
            final localId = result['local_id']?.toString() ??
                result['client_id']?.toString();
            if (localId == null || localId.isEmpty) continue;

            final localTransaction =
                await localDataSource.getTransactionByLocalId(localId);
            if (localTransaction == null) continue;

            final status = result['status']?.toString() ?? 'error';
            if (status == 'created' || status == 'updated') {
              final payload = result['transaction'];
              final remoteTransaction =
                  payload is Map<String, dynamic>
                      ? TransactionModel.fromRemoteJson(payload)
                      : localTransaction;
              await localDataSource.saveTransaction(
                remoteTransaction.copyWith(
                  id: localTransaction.id,
                  serverId:
                      remoteTransaction.serverId ?? result['id']?.toString(),
                  syncStatus: SyncStatus.synced,
                  isDeleted: false,
                  lastModifiedAt:
                      localTransaction.lastModifiedAt ?? DateTime.now().toUtc(),
                  lastSyncedAt: DateTime.now().toUtc(),
                  syncError: null,
                ),
              );
              await operationLocalDataSource.deleteOperationsForEntity(
                'transaction',
                localId,
              );
            } else {
              final syncStatus =
                  status == 'conflict' ? SyncStatus.conflict : SyncStatus.error;
              await localDataSource.saveTransaction(
                localTransaction.copyWith(
                  syncStatus: syncStatus,
                  syncError: _extractErrorMessage(result),
                ),
              );
            }
          }
        }
      }

      for (final operation in deletes) {
        final transaction = await localDataSource.getTransactionByLocalId(
          operation.entityLocalId,
        );
        if (transaction == null) {
          await operationLocalDataSource.deleteOperation(operation.id);
          continue;
        }

        final serverId = transaction.serverId;
        if (serverId == null || serverId.isEmpty) {
          await localDataSource.deleteTransaction(transaction.id);
          await operationLocalDataSource.deleteOperation(operation.id);
          continue;
        }

        try {
          await remoteDataSource.deleteTransaction(serverId);
          await localDataSource.deleteTransaction(transaction.id);
          await operationLocalDataSource.deleteOperation(operation.id);
        } catch (error) {
          await localDataSource.saveTransaction(
            transaction.copyWith(
              syncStatus: SyncStatus.error,
              syncError: error.toString(),
            ),
          );
        }
      }

      await refreshFromRemote();
    } finally {
      _isSyncing = false;
    }
  }

  Future<TransactionModel?> _resolveReferences(TransactionModel transaction) async {
    String? accountId = transaction.accountId;
    String? toAccountId = transaction.toAccountId;
    String? categoryId = transaction.categoryId;

    if (accountId != null && accountId.isNotEmpty) {
      final account = await accountLocalDataSource.getAccountByLocalId(accountId);
      if (account?.serverId == null || account!.serverId!.isEmpty) {
        return null;
      }
      accountId = account.serverId;
    }

    if (toAccountId != null && toAccountId.isNotEmpty) {
      final account =
          await accountLocalDataSource.getAccountByLocalId(toAccountId);
      if (account?.serverId == null || account!.serverId!.isEmpty) {
        return null;
      }
      toAccountId = account.serverId;
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      final category =
          await categoryLocalDataSource.getCategoryByLocalId(categoryId);
      if (category?.serverId == null || category!.serverId!.isEmpty) {
        return null;
      }
      categoryId = category.serverId;
    }

    return transaction.copyWith(
      accountId: accountId,
      toAccountId: toAccountId,
      categoryId: categoryId,
    );
  }

  Future<void> refreshFromRemote() async {
    if (!await hasConnectivity()) return;

    final remoteTransactions = await remoteDataSource.getTransactions();
    final existingTransactions = await localDataSource.getTransactions(
      includeDeleted: true,
    );
    final pendingTransactions = await localDataSource.getPendingTransactions();

    final localIdByServerId = <String, String>{
      for (final transaction in existingTransactions)
        if (transaction.serverId != null && transaction.serverId!.isNotEmpty)
          transaction.serverId!: transaction.id,
    };

    final merged = <String, TransactionModel>{
      for (final transaction in remoteTransactions)
        (localIdByServerId[transaction.serverId ?? transaction.id] ??
            transaction.id): transaction.copyWith(
          id: localIdByServerId[transaction.serverId ?? transaction.id] ??
              transaction.id,
        ),
    };

    for (final pending in pendingTransactions) {
      merged[pending.id] = pending;
    }

    await localDataSource.clearAndReplace(merged.values.toList());
  }

  String _extractErrorMessage(Map<String, dynamic> result) {
    final errors = result['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        if (value != null) {
          return value.toString();
        }
      }
    }
    return 'Synchronization failed.';
  }
}
