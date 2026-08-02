import 'package:hive_flutter/hive_flutter.dart';

import '../../models/transaction_model.dart';
import '../../../domain/entities/sync_status.dart';

abstract class TransactionLocalDataSource {
  Future<List<TransactionModel>> getTransactions({bool includeDeleted = false});
  Future<void> saveTransaction(TransactionModel transaction);
  Future<void> saveTransactions(List<TransactionModel> transactions);
  Future<TransactionModel?> getTransactionByLocalId(String localId);
  Future<List<TransactionModel>> getPendingTransactions();
  Future<void> deleteTransaction(String localId);
  Future<void> clearAndReplace(List<TransactionModel> transactions);
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  static const String boxName = 'transactions_box';

  Future<Box<dynamic>> _openBox() {
    return Hive.openBox<dynamic>(boxName);
  }

  TransactionModel _fromStoredValue(dynamic value) {
    return TransactionModel.fromJson(Map<String, dynamic>.from(value as Map));
  }

  List<TransactionModel> _sortTransactions(List<TransactionModel> transactions) {
    transactions.sort((a, b) {
      final dateComparison = b.date.compareTo(a.date);
      if (dateComparison != 0) return dateComparison;
      return (b.lastModifiedAt ?? b.date).compareTo(a.lastModifiedAt ?? a.date);
    });
    return transactions;
  }

  @override
  Future<List<TransactionModel>> getTransactions({
    bool includeDeleted = false,
  }) async {
    final box = await _openBox();
    final items = box.values.map(_fromStoredValue).where((transaction) {
      if (includeDeleted) return true;
      return !transaction.isDeleted &&
          transaction.syncStatus != SyncStatus.pendingDelete;
    }).toList();
    return _sortTransactions(items);
  }

  @override
  Future<void> saveTransaction(TransactionModel transaction) async {
    final box = await _openBox();
    await box.put(transaction.id, transaction.toJson());
  }

  @override
  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    final box = await _openBox();
    await box.putAll({
      for (final transaction in transactions) transaction.id: transaction.toJson(),
    });
  }

  @override
  Future<TransactionModel?> getTransactionByLocalId(String localId) async {
    final box = await _openBox();
    final raw = box.get(localId);
    if (raw == null) return null;
    return _fromStoredValue(raw);
  }

  @override
  Future<List<TransactionModel>> getPendingTransactions() async {
    final transactions = await getTransactions(includeDeleted: true);
    return transactions.where((transaction) {
      switch (transaction.syncStatus) {
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
    }).toList()
      ..sort((a, b) {
        final aTime = a.lastModifiedAt ?? a.date;
        final bTime = b.lastModifiedAt ?? b.date;
        return aTime.compareTo(bTime);
      });
  }

  @override
  Future<void> deleteTransaction(String localId) async {
    final box = await _openBox();
    await box.delete(localId);
  }

  @override
  Future<void> clearAndReplace(List<TransactionModel> transactions) async {
    final box = await _openBox();
    await box.clear();
    await saveTransactions(transactions);
  }
}
