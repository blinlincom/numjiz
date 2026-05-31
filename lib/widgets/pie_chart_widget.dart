import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class PieChartWidget extends StatelessWidget {
  final Map<String, double> stats;

  const PieChartWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.values.fold(0.0, (a, b) => a + b);
    if (total == 0) {
      return const Center(child: Text('暂无数据', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)));
    }

    final sections = stats.entries.where((e) => e.value > 0).map((entry) {
      final color = AppTheme.expenseColors[entry.key] ?? Colors.grey;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${(entry.value / total * 100).toStringAsFixed(0)}%',
        radius: 55,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 35,
                sectionsSpace: 3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: stats.entries.where((e) => e.value > 0).map((entry) {
                final color = AppTheme.expenseColors[entry.key] ?? Colors.grey;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(entry.key, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                      ),
                      Text(
                        '¥${entry.value.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}