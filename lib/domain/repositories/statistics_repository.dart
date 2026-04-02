class StatisticsSummary {
  final double totalExpense;
  final double totalIncome;
  final double net;
  final double totalAccountsBalance;

  const StatisticsSummary({
    required this.totalExpense,
    required this.totalIncome,
    required this.net,
    required this.totalAccountsBalance,
  });
}

class CategoryBreakdown {
  final String name;
  final double total;
  final double percentage;

  const CategoryBreakdown({
    required this.name,
    required this.total,
    required this.percentage,
  });
}

class TrendPoint {
  final String period;
  final double expense;
  final double income;

  const TrendPoint({
    required this.period,
    required this.expense,
    required this.income,
  });
}

abstract class StatisticsRepository {
  Future<StatisticsSummary> getSummary();
  Future<List<CategoryBreakdown>> getCategoryBreakdown();
  Future<List<TrendPoint>> getTrends({String granularity = 'month'});
}
