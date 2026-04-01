import 'package:hive_flutter/hive_flutter.dart';
import '../../models/transaction_model.dart';

abstract class TransactionLocalDataSource {
  Future<List<TransactionModel>> getTransactions();
  Future<void> cacheTransactions(List<TransactionModel> transactions);
  Future<void> addTransaction(TransactionModel transaction);
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  static const String boxName = 'transactions_box';

  @override
  Future<List<TransactionModel>> getTransactions() async {
    final box = await Hive.openBox(boxName);
    return box.values.map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  @override
  Future<void> cacheTransactions(List<TransactionModel> transactions) async {
    final box = await Hive.openBox(boxName);
    await box.clear();
    for (var transaction in transactions) {
      await box.put(transaction.id, transaction.toJson());
    }
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    final box = await Hive.openBox(boxName);
    await box.put(transaction.id, transaction.toJson());
  }
}
