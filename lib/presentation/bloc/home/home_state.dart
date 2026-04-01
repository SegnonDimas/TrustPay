import 'package:equatable/equatable.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/account.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Transaction> transactions;
  final List<Account> accounts;
  final double totalBalance;

  const HomeLoaded({
    required this.transactions,
    required this.accounts,
    required this.totalBalance,
  });

  @override
  List<Object?> get props => [transactions, accounts, totalBalance];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
