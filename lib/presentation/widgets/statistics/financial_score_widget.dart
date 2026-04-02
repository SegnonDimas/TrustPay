import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class FinancialScoreWidget extends StatelessWidget {
  final double score; // 0 to 1000

  const FinancialScoreWidget({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final String level = _getLevel(score);
    final Color color = _getColor(score);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Score Financier',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: score / 1000,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                children: [
                  Text(
                    score.toInt().toString(),
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color),
                  ),
                  Text(
                    level,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Basé sur vos 30 derniers jours',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _getLevel(double score) {
    if (score >= 800) return 'Excellent';
    if (score >= 600) return 'Bon';
    if (score >= 400) return 'Moyen';
    return 'Risqué';
  }

  Color _getColor(double score) {
    if (score >= 800) return AppColors.success;
    if (score >= 600) return AppColors.primary;
    if (score >= 400) return AppColors.warning;
    return AppColors.error;
  }
}
