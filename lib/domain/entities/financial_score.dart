import 'package:equatable/equatable.dart';

class FinancialScore extends Equatable {
  final double score; // 0 to 100
  final String level; // e.g., "Excellent", "Good", "Average"
  final String description;
  final List<String> recommendations;

  const FinancialScore({
    required this.score,
    required this.level,
    required this.description,
    required this.recommendations,
  });

  @override
  List<Object?> get props => [score, level, description, recommendations];
}
