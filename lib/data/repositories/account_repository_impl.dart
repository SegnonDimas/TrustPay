import 'package:uuid/uuid.dart';

import '../../domain/entities/sync_status.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/local/account_local_datasource.dart';
import '../datasources/remote/account_remote_datasource.dart';
import '../models/account_model.dart';
import '../sync/account_sync_service.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource remoteDataSource;
  final AccountLocalDataSource localDataSource;
  final AccountSyncService syncService;
  final Uuid _uuid = const Uuid();

  AccountRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.syncService,
  });

  @override
  Future<List<Account>> getAccounts() async {
    final localAccounts = await localDataSource.getAccounts();
    if (localAccounts.isNotEmpty) {
      syncService.syncPendingAccounts();
      return localAccounts;
    }
    try {
      final accounts = await remoteDataSource.getAccounts();
      await localDataSource.clearAndReplace(accounts);
      return accounts;
    } catch (_) {
      if (localAccounts.isNotEmpty) return localAccounts;
      rethrow;
    }
  }

  @override
  Future<Account> getAccountDetails(String id) {
    return remoteDataSource.getAccount(id);
  }

  @override
  Future<Account> createAccount(Account account) async {
    final model = AccountModel(
      id: account.id.isEmpty ? _uuid.v4() : account.id,
      name: account.name,
      balance: account.balance,
      currency: account.currency,
      type: account.type,
      provider: account.provider,
      iconPath: account.iconPath,
      accountNumber: account.accountNumber,
      serverId: account.serverId,
      syncStatus: SyncStatus.pendingCreate,
      isDeleted: false,
      lastModifiedAt: DateTime.now().toUtc(),
      lastSyncedAt: null,
      syncError: null,
    );
    await localDataSource.saveAccount(model);
    await syncService.enqueueUpsert(model, operationType: 'create');
    await syncService.syncPendingAccounts();
    return (await localDataSource.getAccountByLocalId(model.id)) ?? model;
  }

  @override
  Future<Account> createMobileMoneyWallet({
    required String provider,
    required String phoneNumber,
  }) {
    // No bulk-sync endpoint exists yet for wallets; keep this network-bound.
    return remoteDataSource.createMobileMoneyWallet(
      provider: provider,
      phoneNumber: phoneNumber,
    );
  }

  @override
  Future<void> updateAccount(Account account) async {
    final existing = await localDataSource.getAccountByLocalId(account.id);
    final model = AccountModel(
      id: account.id.isEmpty ? _uuid.v4() : account.id,
      name: account.name,
      balance: account.balance,
      currency: account.currency,
      type: account.type,
      provider: account.provider,
      iconPath: account.iconPath,
      accountNumber: account.accountNumber,
      serverId: account.serverId ?? existing?.serverId,
      syncStatus: existing?.serverId == null
          ? SyncStatus.pendingCreate
          : SyncStatus.pendingUpdate,
      isDeleted: false,
      lastModifiedAt: DateTime.now().toUtc(),
      lastSyncedAt: existing?.lastSyncedAt,
      syncError: null,
    );
    await localDataSource.saveAccount(model);
    await syncService.enqueueUpsert(
      model,
      operationType: existing?.serverId == null ? 'create' : 'update',
    );
    await syncService.syncPendingAccounts();
  }

  @override
  Future<void> deleteAccount(String id) async {
    final existing = await localDataSource.getAccountByLocalId(id);
    if (existing == null) return;
    if (existing.serverId == null || existing.serverId!.isEmpty) {
      await localDataSource.deleteAccount(id);
      return;
    }
    final pendingDelete = existing.copyWith(
      isDeleted: true,
      syncStatus: SyncStatus.pendingDelete,
      lastModifiedAt: DateTime.now().toUtc(),
      syncError: null,
    );
    await localDataSource.saveAccount(pendingDelete);
    await syncService.enqueueDelete(pendingDelete);
    await syncService.syncPendingAccounts();
  }
}
