import 'package:equatable/equatable.dart';

enum TransactionType { income, expense, transfer }
enum TransactionCategory { 
  food, transport, health, education, business, salary, 
  entertainment, shopping, utilities, other 
}

class Transaction extends Equatable {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final TransactionCategory category;
  final String? accountId;
  final String? description;

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    this.accountId,
    this.description,
  });

  @override
  List<Object?> get props => [id, title, amount, date, type, category, accountId, description];
}
