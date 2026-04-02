import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/local/transaction_local_datasource.dart';
import '../datasources/remote/transaction_remote_datasource.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource localDataSource;
  final TransactionRemoteDataSource remoteDataSource;

  TransactionRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<List<Transaction>> getTransactions() async {
    try {
      final remoteTransactions = await remoteDataSource.getTransactions();
      await localDataSource.cacheTransactions(remoteTransactions);
      return remoteTransactions;
    } catch (_) {
      final localTransactions = await localDataSource.getTransactions();
      if (localTransactions.isNotEmpty) {
        return localTransactions;
      }
      rethrow;
    }
  }

  @override
  Future<Transaction> addTransaction(Transaction transaction) async {
    final model = TransactionModel(
      id: transaction.id,
      title: transaction.title,
      amount: transaction.amount,
      date: transaction.date,
      type: transaction.type,
      category: transaction.category,
      categoryId: transaction.categoryId,
      accountId: transaction.accountId,
      toAccountId: transaction.toAccountId,
      description: transaction.description,
    );

    final created = await remoteDataSource.createTransaction(model);
    await localDataSource.addTransaction(created);
    return created;
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    final model = TransactionModel(
      id: transaction.id,
      title: transaction.title,
      amount: transaction.amount,
      date: transaction.date,
      type: transaction.type,
      category: transaction.category,
      categoryId: transaction.categoryId,
      accountId: transaction.accountId,
      toAccountId: transaction.toAccountId,
      description: transaction.description,
    );
    await remoteDataSource.updateTransaction(model);
    await localDataSource.addTransaction(model);
  }

  @override
  Future<void> deleteTransaction(String transactionId) {
    return remoteDataSource.deleteTransaction(transactionId);
  }
}
