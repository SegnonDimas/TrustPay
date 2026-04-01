import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../../../domain/entities/account.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final TransactionRepository transactionRepository;

  HomeBloc({required this.transactionRepository}) : super(HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
  }

  Future<void> _onLoadHomeData(LoadHomeData event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      final transactions = await transactionRepository.getTransactions();
      
      // Mock accounts for now
      final accounts = [
        const Account(
          id: '1',
          name: 'Cash',
          balance: 25000,
          type: AccountType.cash,
        ),
        const Account(
          id: '2',
          name: 'MTN MoMo',
          balance: 125000,
          type: AccountType.mobileMoney,
        ),
        const Account(
          id: '3',
          name: 'Ecobank',
          balance: 850000,
          type: AccountType.bank,
        ),
      ];

      double totalBalance = accounts.fold(0, (sum, item) => sum + item.balance);

      emit(HomeLoaded(
        transactions: transactions,
        accounts: accounts,
        totalBalance: totalBalance,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
