class AccountingKpis {
  final int transactionCount;
  final double? averageIncomeTicket;
  final double? revenueGrowthRatePct;
  final double? revenueVariabilityCoefficient;
  final double totalRevenue;
  final double previousPeriodRevenue;

  const AccountingKpis({
    required this.transactionCount,
    required this.averageIncomeTicket,
    required this.revenueGrowthRatePct,
    required this.revenueVariabilityCoefficient,
    required this.totalRevenue,
    required this.previousPeriodRevenue,
  });
}

class AccountingBilanPeriod {
  final String label;
  final String startDate;
  final String endDate;
  final double revenue;
  final double expense;
  final double netResult;
  final int transactionCount;

  const AccountingBilanPeriod({
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.revenue,
    required this.expense,
    required this.netResult,
    required this.transactionCount,
  });
}

abstract class AccountingRepository {
  Future<AccountingKpis> getKpis({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<AccountingBilanPeriod>> getBilans({
    required String granularity,
    required DateTime startDate,
    required DateTime endDate,
  });
}
