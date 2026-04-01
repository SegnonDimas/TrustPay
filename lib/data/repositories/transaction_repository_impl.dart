import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/local/transaction_local_datasource.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource localDataSource;

  TransactionRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Transaction>> getTransactions() async {
    final localTransactions = await localDataSource.getTransactions();
    if (localTransactions.isNotEmpty) {
      return localTransactions;
    }
    
    // Fake initial data if empty
    final fakeTransactions = [
      TransactionModel(
        id: '1',
        title: 'Supermarché Champion',
        amount: 15000,
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: TransactionType.expense,
        category: TransactionCategory.food,
      ),
      TransactionModel(
        id: '2',
        title: 'Salaire Mensuel',
        amount: 450000,
        date: DateTime.now().subtract(const Duration(days: 5)),
        type: TransactionType.income,
        category: TransactionCategory.salary,
      ),
      TransactionModel(
        id: '3',
        title: 'Transfert MoMo',
        amount: 5000,
        date: DateTime.now(),
        type: TransactionType.expense,
        category: TransactionCategory.other,
      ),
    ];
    
    await localDataSource.cacheTransactions(fakeTransactions);
    return fakeTransactions;
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    final model = TransactionModel(
      id: transaction.id,
      title: transaction.title,
      amount: transaction.amount,
      date: transaction.date,
      type: transaction.type,
      category: transaction.category,
      accountId: transaction.accountId,
      description: transaction.description,
    );
    await localDataSource.addTransaction(model);
  }
}
