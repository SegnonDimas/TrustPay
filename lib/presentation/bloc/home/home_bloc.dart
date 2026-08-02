import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/repositories/account_repository.dart';
import '../../../domain/repositories/statistics_repository.dart';
import '../../../domain/repositories/transaction_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final TransactionRepository transactionRepository;
  final AccountRepository accountRepository;
  final StatisticsRepository statisticsRepository;

  HomeBloc({
    required this.transactionRepository,
    required this.accountRepository,
    required this.statisticsRepository,
  }) : super(HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
  }

  Future<void> _onLoadHomeData(LoadHomeData event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      final transactions = await transactionRepository.getTransactions();
      final accounts = await accountRepository.getAccounts();
      try {
        final summary = await statisticsRepository.getSummary();

        emit(HomeLoaded(
          transactions: transactions,
          accounts: accounts,
          totalBalance: summary.totalAccountsBalance,
          totalIncome: summary.totalIncome,
          totalExpense: summary.totalExpense,
        ));
      } catch (_) {
        var totalIncome = 0.0;
        var totalExpense = 0.0;
        for (final transaction in transactions) {
          if (transaction.type == TransactionType.income) {
            totalIncome += transaction.amount;
          } else if (transaction.type == TransactionType.expense) {
            totalExpense += transaction.amount;
          }
        }
        final totalBalance = accounts.fold<double>(
          0,
          (sum, account) => sum + account.balance,
        );

        emit(HomeLoaded(
          transactions: transactions,
          accounts: accounts,
          totalBalance: totalBalance,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
        ));
      }
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
