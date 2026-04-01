import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/transaction_repository.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository transactionRepository;

  TransactionBloc({required this.transactionRepository}) : super(TransactionInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<AddTransaction>(_onAddTransaction);
  }

  Future<void> _onLoadTransactions(LoadTransactions event, Emitter<TransactionState> emit) async {
    emit(TransactionLoading());
    try {
      final transactions = await transactionRepository.getTransactions();
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onAddTransaction(AddTransaction event, Emitter<TransactionState> emit) async {
    try {
      await transactionRepository.addTransaction(event.transaction);
      emit(TransactionSuccess());
      add(LoadTransactions());
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }
}
