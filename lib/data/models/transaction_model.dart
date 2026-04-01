import '../../domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.title,
    required super.amount,
    required super.date,
    required super.type,
    required super.category,
    super.accountId,
    super.description,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      type: TransactionType.values.firstWhere((e) => e.toString() == 'TransactionType.${json['type']}'),
      category: TransactionCategory.values.firstWhere((e) => e.toString() == 'TransactionCategory.${json['category']}'),
      accountId: json['accountId'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.toString().split('.').last,
      'category': category.toString().split('.').last,
      'accountId': accountId,
      'description': description,
    };
  }
}
