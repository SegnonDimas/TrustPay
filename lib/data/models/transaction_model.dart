import '../../domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.title,
    required super.amount,
    required super.date,
    required super.type,
    required super.category,
    super.categoryId,
    super.accountId,
    super.toAccountId,
    super.description,
  });

  static TransactionType _mapTransactionType(String? value) {
    switch (value) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      case 'transfer':
        return TransactionType.transfer;
      default:
        return TransactionType.expense;
    }
  }

  static TransactionCategory _mapCategory(String? value, TransactionType type) {
    if (value == null || value.isEmpty) {
      return type == TransactionType.income
          ? TransactionCategory.salary
          : TransactionCategory.other;
    }
    final normalized = value.toLowerCase();
    if (normalized.contains('food') || normalized.contains('alimentation')) {
      return TransactionCategory.food;
    }
    if (normalized.contains('transport')) return TransactionCategory.transport;
    if (normalized.contains('health')) return TransactionCategory.health;
    if (normalized.contains('education')) return TransactionCategory.education;
    if (normalized.contains('business')) return TransactionCategory.business;
    if (normalized.contains('salary') || normalized.contains('revenu')) {
      return TransactionCategory.salary;
    }
    if (normalized.contains('entertain')) {
      return TransactionCategory.entertainment;
    }
    if (normalized.contains('shopping')) return TransactionCategory.shopping;
    if (normalized.contains('utilit')) return TransactionCategory.utilities;
    return type == TransactionType.income
        ? TransactionCategory.salary
        : TransactionCategory.other;
  }

  static String _typeToApi(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return 'income';
      case TransactionType.expense:
        return 'expense';
      case TransactionType.transfer:
        return 'transfer';
    }
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final apiType = (json['transaction_type'] ?? json['type']) as String?;
    final type = _mapTransactionType(apiType);
    final note = (json['note'] ?? json['title']) as String?;

    return TransactionModel(
      id: json['id'].toString(),
      title: (note == null || note.isEmpty)
          ? (type == TransactionType.income ? 'Revenu' : 'Transaction')
          : note,
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      date: DateTime.parse(json['date']),
      type: type,
      category: _mapCategory(
        json['category_name']?.toString(),
        type,
      ),
      categoryId: json['category']?.toString(),
      accountId: (json['account'] ?? json['accountId'])?.toString(),
      toAccountId: json['to_account']?.toString(),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final note = description != null && description!.isNotEmpty
        ? '$title - $description'
        : title;

    return {
      if (id.isNotEmpty) 'id': int.tryParse(id),
      'transaction_type': _typeToApi(type),
      'amount': amount,
      'date': date.toIso8601String(),
      'account': accountId == null ? null : int.tryParse(accountId!),
      'to_account': toAccountId == null ? null : int.tryParse(toAccountId!),
      'category': categoryId == null ? null : int.tryParse(categoryId!),
      'note': note,
    };
  }
}
