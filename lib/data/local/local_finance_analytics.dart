import '../../domain/entities/account.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/accounting_repository.dart';
import '../../domain/repositories/statistics_repository.dart';

class LocalFinanceAnalytics {
  const LocalFinanceAnalytics();

  StatisticsSummary buildSummary(
    List<Transaction> transactions,
    List<Account> accounts,
  ) {
    var totalExpense = 0.0;
    var totalIncome = 0.0;
    for (final transaction in transactions) {
      if (transaction.isDeleted) continue;
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
      } else if (transaction.type == TransactionType.expense) {
        totalExpense += transaction.amount;
      }
    }
    final totalBalance = accounts
        .where((account) => !account.isDeleted)
        .fold<double>(0, (sum, account) => sum + account.balance);
    return StatisticsSummary(
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      net: totalIncome - totalExpense,
      totalAccountsBalance: totalBalance,
    );
  }

  List<CategoryBreakdown> buildCategoryBreakdown(
    List<Transaction> transactions,
    List<Category> categories,
  ) {
    final categoryNamesById = {
      for (final category in categories) category.id: category.name,
    };
    final totals = <String, double>{};
    var overall = 0.0;
    for (final transaction in transactions) {
      if (transaction.isDeleted || transaction.type != TransactionType.expense) {
        continue;
      }
      final key = categoryNamesById[transaction.categoryId] ??
          _fallbackCategoryLabel(transaction.category);
      totals[key] = (totals[key] ?? 0) + transaction.amount;
      overall += transaction.amount;
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .map(
          (entry) => CategoryBreakdown(
            name: entry.key,
            total: entry.value,
            percentage: overall <= 0 ? 0 : (entry.value / overall) * 100,
          ),
        )
        .toList();
  }

  List<TrendPoint> buildMonthlyTrends(List<Transaction> transactions) {
    final buckets = <String, ({double income, double expense})>{};
    for (final transaction in transactions) {
      if (transaction.isDeleted) continue;
      final bucket =
          '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
      final current = buckets[bucket] ?? (income: 0.0, expense: 0.0);
      if (transaction.type == TransactionType.income) {
        buckets[bucket] = (
          income: current.income + transaction.amount,
          expense: current.expense,
        );
      } else if (transaction.type == TransactionType.expense) {
        buckets[bucket] = (
          income: current.income,
          expense: current.expense + transaction.amount,
        );
      }
    }

    final sortedKeys = buckets.keys.toList()..sort();
    return sortedKeys
        .map(
          (key) => TrendPoint(
            period: key,
            income: buckets[key]!.income,
            expense: buckets[key]!.expense,
          ),
        )
        .toList();
  }

  AccountingKpis buildKpis(
    List<Transaction> transactions, {
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final current = _inRange(transactions, startDate, endDate);
    final periodLength = endDate.difference(startDate).inDays + 1;
    final prevEnd = startDate.subtract(const Duration(days: 1));
    final prevStart = prevEnd.subtract(Duration(days: periodLength - 1));
    final previous = _inRange(transactions, prevStart, prevEnd);

    final revenue = current
        .where((tx) => tx.type == TransactionType.income && !tx.isDeleted)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    final previousRevenue = previous
        .where((tx) => tx.type == TransactionType.income && !tx.isDeleted)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    final incomeTransactions = current
        .where((tx) => tx.type == TransactionType.income && !tx.isDeleted)
        .toList();
    final nonTransferCount = current
        .where((tx) => tx.type != TransactionType.transfer && !tx.isDeleted)
        .length;
    final averageIncomeTicket = incomeTransactions.isEmpty
        ? null
        : revenue / incomeTransactions.length;
    final growth = previousRevenue == 0
        ? null
        : ((revenue - previousRevenue) / previousRevenue) * 100;

    return AccountingKpis(
      transactionCount: nonTransferCount,
      averageIncomeTicket: averageIncomeTicket,
      revenueGrowthRatePct: growth,
      revenueVariabilityCoefficient:
          _revenueVariabilityCoefficient(incomeTransactions),
      totalRevenue: revenue,
      previousPeriodRevenue: previousRevenue,
    );
  }

  List<AccountingBilanPeriod> buildMonthlyBilans(
    List<Transaction> transactions, {
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final buckets = <String, List<Transaction>>{};
    for (final transaction in _inRange(transactions, startDate, endDate)) {
      if (transaction.isDeleted) continue;
      final key =
          '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
      buckets.putIfAbsent(key, () => []).add(transaction);
    }
    final keys = buckets.keys.toList()..sort();
    return keys.map((key) {
      final monthTransactions = buckets[key]!;
      final revenue = monthTransactions
          .where((tx) => tx.type == TransactionType.income)
          .fold<double>(0, (sum, tx) => sum + tx.amount);
      final expense = monthTransactions
          .where((tx) => tx.type == TransactionType.expense)
          .fold<double>(0, (sum, tx) => sum + tx.amount);
      final first = monthTransactions
          .map((tx) => tx.date)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final last = monthTransactions
          .map((tx) => tx.date)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      return AccountingBilanPeriod(
        label: key,
        startDate: first.toIso8601String(),
        endDate: last.toIso8601String(),
        revenue: revenue,
        expense: expense,
        netResult: revenue - expense,
        transactionCount:
            monthTransactions.where((tx) => tx.type != TransactionType.transfer).length,
      );
    }).toList();
  }

  List<Transaction> _inRange(
    List<Transaction> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    return transactions.where((transaction) {
      final date = transaction.date;
      return !date.isBefore(DateTime(startDate.year, startDate.month, startDate.day)) &&
          !date.isAfter(DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59));
    }).toList();
  }

  double? _revenueVariabilityCoefficient(List<Transaction> incomeTransactions) {
    if (incomeTransactions.length < 2) return null;
    final dailyTotals = <String, double>{};
    for (final transaction in incomeTransactions) {
      final day =
          '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}-${transaction.date.day.toString().padLeft(2, '0')}';
      dailyTotals[day] = (dailyTotals[day] ?? 0) + transaction.amount;
    }
    final values = dailyTotals.values.toList();
    if (values.length < 2) return null;
    final mean = values.reduce((a, b) => a + b) / values.length;
    if (mean == 0) return null;
    final variance = values
            .map((value) => (value - mean) * (value - mean))
            .reduce((a, b) => a + b) /
        values.length;
    return variance <= 0 ? 0 : (variance.sqrt()) / mean;
  }

  String _fallbackCategoryLabel(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.food:
        return 'Alimentation';
      case TransactionCategory.transport:
        return 'Transport';
      case TransactionCategory.health:
        return 'Santé';
      case TransactionCategory.education:
        return 'Éducation';
      case TransactionCategory.business:
        return 'Business';
      case TransactionCategory.salary:
        return 'Salaire';
      case TransactionCategory.entertainment:
        return 'Divertissement';
      case TransactionCategory.shopping:
        return 'Shopping';
      case TransactionCategory.utilities:
        return 'Charges';
      case TransactionCategory.other:
        return 'Autres';
    }
  }
}

extension on double {
  double sqrt() {
    if (this <= 0) return 0;
    var estimate = this;
    for (var i = 0; i < 12; i++) {
      estimate = (estimate + this / estimate) / 2;
    }
    return estimate;
  }
}
