import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/transaction.dart';
import '../../../core/theme/app_colors.dart';

class TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final currencyFormat = NumberFormat.currency(locale: 'fr_BJ', symbol: 'FCFA', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getCategoryColor(transaction.category).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCategoryIcon(transaction.category),
              color: _getCategoryColor(transaction.category),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(transaction.date),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${isExpense ? "-" : "+"}${currencyFormat.format(transaction.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isExpense ? AppColors.error : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.food: return Icons.restaurant;
      case TransactionCategory.transport: return Icons.directions_car;
      case TransactionCategory.health: return Icons.medical_services;
      case TransactionCategory.education: return Icons.school;
      case TransactionCategory.business: return Icons.business_center;
      case TransactionCategory.salary: return Icons.payments;
      case TransactionCategory.entertainment: return Icons.movie;
      case TransactionCategory.shopping: return Icons.shopping_bag;
      case TransactionCategory.utilities: return Icons.lightbulb;
      default: return Icons.more_horiz;
    }
  }

  Color _getCategoryColor(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.food: return Colors.orange;
      case TransactionCategory.transport: return Colors.blue;
      case TransactionCategory.health: return Colors.red;
      case TransactionCategory.salary: return Colors.green;
      case TransactionCategory.business: return Colors.purple;
      default: return Colors.grey;
    }
  }
}
