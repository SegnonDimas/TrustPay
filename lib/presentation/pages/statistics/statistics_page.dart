import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/repositories/accounting_repository.dart';
import '../../../domain/repositories/statistics_repository.dart';
import '../../../injection_container.dart';
import '../../bloc/statistics/statistics_bloc.dart';
import '../../bloc/statistics/statistics_event.dart';
import '../../bloc/statistics/statistics_state.dart';
import '../../widgets/statistics/financial_score_widget.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StatisticsBloc>()..add(LoadStatistics()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Statistiques'),
        ),
        body: BlocBuilder<StatisticsBloc, StatisticsState>(
          builder: (context, state) {
            if (state is StatisticsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is StatisticsError) {
              return Center(child: Text(state.message));
            }
            if (state is! StatisticsLoaded) {
              return const SizedBox.shrink();
            }

            final summary = state.summary;
            final score = _computeScore(summary);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FinancialScoreWidget(score: score),
                  const SizedBox(height: 24),
                  _buildChartSection(context, state.trends),
                  const SizedBox(height: 24),
                  _buildSummaryCards(summary),
                  const SizedBox(height: 24),
                  _buildAccountingInsights(
                    state.accountingKpis,
                    state.accountingBilans,
                  ),
                  const SizedBox(height: 24),
                  _buildCategoryBreakdown(state.categories),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  double _computeScore(StatisticsSummary summary) {
    if (summary.totalIncome <= 0) return 400;
    final ratio = (summary.net / summary.totalIncome).clamp(-1, 1);
    return ((ratio + 1) * 250 + 300).clamp(0, 1000).toDouble();
  }

  Widget _buildChartSection(BuildContext context, List<TrendPoint> trends) {
    final displayPoints = trends.take(4).toList();
    final maxValue = displayPoints.fold<double>(
      0,
      (acc, item) => [
        acc,
        item.income.abs(),
        item.expense.abs(),
      ].reduce((a, b) => a > b ? a : b),
    );
    final chartMaxY = maxValue <= 0 ? 1.0 : maxValue * 1.2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenus vs Dépenses',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                minY: 0,
                maxY: chartMaxY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: displayPoints.isEmpty
                    ? [_makeGroupData(0, 0, 0)]
                    : displayPoints
                        .asMap()
                        .entries
                        .map((e) => _makeGroupData(e.key, e.value.income, e.value.expense))
                        .toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('Revenus', AppColors.primary),
              const SizedBox(width: 24),
              _buildLegend('Dépenses', AppColors.error),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(
      barsSpace: 4,
      x: x,
      barRods: [
        BarChartRodData(toY: y1, color: AppColors.primary, width: 12),
        BarChartRodData(toY: y2, color: AppColors.error, width: 12),
      ],
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildSummaryCards(StatisticsSummary summary) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_BJ',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            'Entrées',
            currencyFormat.format(summary.totalIncome),
            AppColors.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            'Sorties',
            currencyFormat.format(summary.totalExpense),
            AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(amount, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(List<CategoryBreakdown> categories) {
    final limitedCategories = categories.take(4).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Répartition par catégorie', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (limitedCategories.isEmpty)
            const Text('Aucune donnée disponible sur la période.')
          else
            ...limitedCategories.map(
              (item) => _buildCategoryRow(
                item.name,
                (item.percentage / 100).clamp(0, 1),
                _categoryColor(item.name),
              ),
            ),
        ],
      ),
    );
  }

  Color _categoryColor(String name) {
    final value = name.toLowerCase();
    if (value.contains('aliment')) return Colors.orange;
    if (value.contains('transport')) return Colors.blue;
    if (value.contains('loisir')) return Colors.purple;
    if (value.contains('sant')) return Colors.red;
    return Colors.grey;
  }

  Widget _buildCategoryRow(String label, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13)),
              Text('${(percentage * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.shade100,
            color: color,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountingInsights(
    AccountingKpis kpis,
    List<AccountingBilanPeriod> bilans,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_BJ',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    final growthText = kpis.revenueGrowthRatePct == null
        ? 'N/A'
        : '${kpis.revenueGrowthRatePct!.toStringAsFixed(1)}%';
    final variabilityText = kpis.revenueVariabilityCoefficient == null
        ? 'N/A'
        : kpis.revenueVariabilityCoefficient!.toStringAsFixed(2);
    final recentBilans = bilans.length > 4
        ? bilans.sublist(bilans.length - 4)
        : bilans;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bilan financier',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAccountingMetric(
                  'CA periode',
                  currencyFormat.format(kpis.totalRevenue),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAccountingMetric(
                  'Croissance',
                  growthText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAccountingMetric(
                  'Ticket moyen',
                  kpis.averageIncomeTicket == null
                      ? 'N/A'
                      : currencyFormat.format(kpis.averageIncomeTicket),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAccountingMetric(
                  'Variabilite',
                  variabilityText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAccountingMetric(
            'Transactions',
            '${kpis.transactionCount}',
          ),
          if (recentBilans.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Bilans mensuels recents',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...recentBilans.map(
              (period) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(period.label),
                    Text(
                      currencyFormat.format(period.netResult),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: period.netResult >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountingMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
