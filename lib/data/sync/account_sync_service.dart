import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/sync_status.dart';
import '../datasources/local/account_local_datasource.dart';
import '../datasources/local/sync_operation_local_datasource.dart';
import '../datasources/remote/account_remote_datasource.dart';
import '../models/account_model.dart';
import '../models/sync_operation_model.dart';

class AccountSyncService {
  final AccountLocalDataSource localDataSource;
  final SyncOperationLocalDataSource operationLocalDataSource;
  final AccountRemoteDataSource remoteDataSource;
  final Connectivity connectivity;
  final Uuid uuid;
  bool _isSyncing = false;

  AccountSyncService({
    required this.localDataSource,
    required this.operationLocalDataSource,
    required this.remoteDataSource,
    required this.connectivity,
    Uuid? uuid,
  }) : uuid = uuid ?? const Uuid();

  Future<void> enqueueUpsert(AccountModel account, {required String operationType}) async {
    await operationLocalDataSource.deleteOperationsForEntity('account', account.id);
    await operationLocalDataSource.putOperation(
      SyncOperationModel(
        id: uuid.v4(),
        entityType: 'account',
        entityLocalId: account.id,
        operationType: operationType,
        payload: account.toJsonForStorage(),
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> enqueueDelete(AccountModel account) async {
    await operationLocalDataSource.deleteOperationsForEntity('account', account.id);
    await operationLocalDataSource.putOperation(
      SyncOperationModel(
        id: uuid.v4(),
        entityType: 'account',
        entityLocalId: account.id,
        operationType: 'delete',
        payload: account.toJsonForStorage(),
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<bool> hasConnectivity() async {
    final result = await connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<void> syncPendingAccounts() async {
    if (_isSyncing) return;
    if (!await hasConnectivity()) return;
    _isSyncing = true;
    try {
      final operations = await operationLocalDataSource.getOperations(entityType: 'account');
      final upserts = <String, AccountModel>{};
      final deletes = <SyncOperationModel>[];

      for (final operation in operations) {
        final account = await localDataSource.getAccountByLocalId(operation.entityLocalId);
        if (operation.operationType == 'delete') {
          deletes.add(operation);
          continue;
        }
        if (account == null) {
          await operationLocalDataSource.deleteOperation(operation.id);
          continue;
        }
        upserts[account.id] = account.copyWith(syncStatus: SyncStatus.syncing, syncError: null);
      }

      if (upserts.isNotEmpty) {
        await localDataSource.saveAccounts(upserts.values.toList());
        final results = await remoteDataSource.bulkSyncAccounts(upserts.values.toList());
        for (final result in results) {
          final localId = result['local_id']?.toString() ?? result['client_id']?.toString();
          if (localId == null || localId.isEmpty) continue;
          final localAccount = await localDataSource.getAccountByLocalId(localId);
          if (localAccount == null) continue;
          final status = result['status']?.toString() ?? 'error';
          if (status == 'created' || status == 'updated') {
            final payload = result['account'];
            final remoteAccount = payload is Map<String, dynamic>
                ? AccountModel.fromRemoteJson(payload)
                : localAccount;
            await localDataSource.saveAccount(
              remoteAccount.copyWith(
                id: localAccount.id,
                serverId: remoteAccount.serverId ?? result['id']?.toString(),
                syncStatus: SyncStatus.synced,
                isDeleted: false,
                lastModifiedAt: localAccount.lastModifiedAt ?? DateTime.now().toUtc(),
                lastSyncedAt: DateTime.now().toUtc(),
                syncError: null,
              ),
            );
            await operationLocalDataSource.deleteOperationsForEntity('account', localId);
          } else {
            await localDataSource.saveAccount(
              localAccount.copyWith(
                syncStatus: status == 'conflict' ? SyncStatus.conflict : SyncStatus.error,
                syncError: _extractError(result),
              ),
            );
          }
        }
      }

      for (final operation in deletes) {
        final account = await localDataSource.getAccountByLocalId(operation.entityLocalId);
        if (account == null) {
          await operationLocalDataSource.deleteOperation(operation.id);
          continue;
        }
        if (account.serverId == null || account.serverId!.isEmpty) {
          await localDataSource.deleteAccount(account.id);
          await operationLocalDataSource.deleteOperation(operation.id);
          continue;
        }
        try {
          await remoteDataSource.deleteAccount(account.serverId!);
          await localDataSource.deleteAccount(account.id);
          await operationLocalDataSource.deleteOperation(operation.id);
        } catch (error) {
          await localDataSource.saveAccount(
            account.copyWith(syncStatus: SyncStatus.error, syncError: error.toString()),
          );
        }
      }

      await refreshFromRemote();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> refreshFromRemote() async {
    if (!await hasConnectivity()) return;
    final remoteAccounts = await remoteDataSource.getAccounts();
    final existingAccounts = await localDataSource.getAccounts(includeDeleted: true);
    final pendingAccounts = await localDataSource.getPendingAccounts();
    final localIdByServerId = <String, String>{
      for (final account in existingAccounts)
        if (account.serverId != null && account.serverId!.isNotEmpty)
          account.serverId!: account.id,
    };
    final merged = <String, AccountModel>{
      for (final account in remoteAccounts)
        (localIdByServerId[account.serverId ?? account.id] ?? account.id):
            account.copyWith(
          id: localIdByServerId[account.serverId ?? account.id] ?? account.id,
        ),
    };
    for (final pending in pendingAccounts) {
      merged[pending.id] = pending;
    }
    await localDataSource.clearAndReplace(merged.values.toList());
  }

  String _extractError(Map<String, dynamic> result) {
    final errors = result['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) return value.first.toString();
        if (value != null) return value.toString();
      }
    }
    return 'Synchronization failed.';
  }
}
