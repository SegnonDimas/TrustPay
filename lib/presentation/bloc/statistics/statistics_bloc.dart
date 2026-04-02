import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/accounting_repository.dart';
import '../../../domain/repositories/statistics_repository.dart';
import 'statistics_event.dart';
import 'statistics_state.dart';

class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  final StatisticsRepository statisticsRepository;
  final AccountingRepository accountingRepository;

  StatisticsBloc({
    required this.statisticsRepository,
    required this.accountingRepository,
  })
      : super(StatisticsInitial()) {
    on<LoadStatistics>(_onLoadStatistics);
  }

  Future<void> _onLoadStatistics(
    LoadStatistics event,
    Emitter<StatisticsState> emit,
  ) async {
    emit(StatisticsLoading());
    try {
      final now = DateTime.now();
      final kpiStart = DateTime(now.year, now.month, 1);
      final kpiEnd = now;
      final bilansStart = DateTime(now.year, now.month - 5, 1);
      final bilansEnd = now;

      final summary = await statisticsRepository.getSummary();
      final categories = await statisticsRepository.getCategoryBreakdown();
      final trends = await statisticsRepository.getTrends();
      final accountingKpis = await accountingRepository.getKpis(
        startDate: kpiStart,
        endDate: kpiEnd,
      );
      final accountingBilans = await accountingRepository.getBilans(
        granularity: 'monthly',
        startDate: bilansStart,
        endDate: bilansEnd,
      );
      emit(
        StatisticsLoaded(
          summary: summary,
          categories: categories,
          trends: trends,
          accountingKpis: accountingKpis,
          accountingBilans: accountingBilans,
        ),
      );
    } catch (e) {
      emit(StatisticsError(e.toString()));
    }
  }
}
