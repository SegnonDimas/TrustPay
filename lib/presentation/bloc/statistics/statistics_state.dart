import 'package:equatable/equatable.dart';

import '../../../domain/repositories/statistics_repository.dart';

abstract class StatisticsState extends Equatable {
  const StatisticsState();

  @override
  List<Object?> get props => [];
}

class StatisticsInitial extends StatisticsState {}

class StatisticsLoading extends StatisticsState {}

class StatisticsLoaded extends StatisticsState {
  final StatisticsSummary summary;
  final List<CategoryBreakdown> categories;
  final List<TrendPoint> trends;

  const StatisticsLoaded({
    required this.summary,
    required this.categories,
    required this.trends,
  });

  @override
  List<Object?> get props => [summary, categories, trends];
}

class StatisticsError extends StatisticsState {
  final String message;

  const StatisticsError(this.message);

  @override
  List<Object?> get props => [message];
}
