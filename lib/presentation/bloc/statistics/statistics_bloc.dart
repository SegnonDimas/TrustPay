import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/statistics_repository.dart';
import 'statistics_event.dart';
import 'statistics_state.dart';

class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  final StatisticsRepository statisticsRepository;

  StatisticsBloc({required this.statisticsRepository})
      : super(StatisticsInitial()) {
    on<LoadStatistics>(_onLoadStatistics);
  }

  Future<void> _onLoadStatistics(
    LoadStatistics event,
    Emitter<StatisticsState> emit,
  ) async {
    emit(StatisticsLoading());
    try {
      final summary = await statisticsRepository.getSummary();
      final categories = await statisticsRepository.getCategoryBreakdown();
      final trends = await statisticsRepository.getTrends();
      emit(
        StatisticsLoaded(
          summary: summary,
          categories: categories,
          trends: trends,
        ),
      );
    } catch (e) {
      emit(StatisticsError(e.toString()));
    }
  }
}
