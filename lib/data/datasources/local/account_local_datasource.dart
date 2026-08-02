import 'package:hive_flutter/hive_flutter.dart';

import '../../../domain/entities/sync_status.dart';
import '../../models/account_model.dart';

abstract class AccountLocalDataSource {
  Future<List<AccountModel>> getAccounts({bool includeDeleted = false});
  Future<void> saveAccount(AccountModel account);
  Future<void> saveAccounts(List<AccountModel> accounts);
  Future<AccountModel?> getAccountByLocalId(String localId);
  Future<List<AccountModel>> getPendingAccounts();
  Future<void> deleteAccount(String localId);
  Future<void> clearAndReplace(List<AccountModel> accounts);
}

class AccountLocalDataSourceImpl implements AccountLocalDataSource {
  static const String boxName = 'accounts_box';

  Future<Box<dynamic>> _openBox() {
    return Hive.openBox<dynamic>(boxName);
  }

  AccountModel _fromStoredValue(dynamic value) {
    return AccountModel.fromJson(Map<String, dynamic>.from(value as Map));
  }

  @override
  Future<List<AccountModel>> getAccounts({bool includeDeleted = false}) async {
    final box = await _openBox();
    final items = box.values.map(_fromStoredValue).where((account) {
      if (includeDeleted) return true;
      return !account.isDeleted &&
          account.syncStatus != SyncStatus.pendingDelete;
    }).toList();
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  @override
  Future<void> saveAccount(AccountModel account) async {
    final box = await _openBox();
    await box.put(account.id, account.toJsonForStorage());
  }

  @override
  Future<void> saveAccounts(List<AccountModel> accounts) async {
    final box = await _openBox();
    await box.putAll({
      for (final account in accounts) account.id: account.toJsonForStorage(),
    });
  }

  @override
  Future<AccountModel?> getAccountByLocalId(String localId) async {
    final box = await _openBox();
    final raw = box.get(localId);
    if (raw == null) return null;
    return _fromStoredValue(raw);
  }

  @override
  Future<List<AccountModel>> getPendingAccounts() async {
    final accounts = await getAccounts(includeDeleted: true);
    return accounts.where((account) {
      switch (account.syncStatus) {
        case SyncStatus.pendingCreate:
        case SyncStatus.pendingUpdate:
        case SyncStatus.pendingDelete:
        case SyncStatus.error:
        case SyncStatus.conflict:
          return true;
        case SyncStatus.synced:
        case SyncStatus.syncing:
          return false;
      }
    }).toList();
  }

  @override
  Future<void> deleteAccount(String localId) async {
    final box = await _openBox();
    await box.delete(localId);
  }

  @override
  Future<void> clearAndReplace(List<AccountModel> accounts) async {
    final box = await _openBox();
    await box.clear();
    await saveAccounts(accounts);
  }
}
