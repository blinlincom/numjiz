import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _monthlyData = [];
  double _totalThisMonth = 0;
  Map<String, double> _currentMonthStats = {};
  bool _loading = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    _currentMonthStats = await DatabaseHelper.instance.getMonthlyStats(now);
    _totalThisMonth = _currentMonthStats.values.fold<double>(0, (a, b) => a + b);

    _monthlyData = [];
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final total = await DatabaseHelper.instance.getTotalByMonth(month);
      _monthlyData.add({'month': DateFormat('M月').format(month), 'total': total});
    }

    setState(() => _loading = false);
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPadding(context);
    final maxWidth = Responsive.contentMaxWidth(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('统计分析', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: !isDesktop,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadData, tooltip: '刷新'),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 3))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 总支出卡片
                        _buildTotalCard(),
                        const SizedBox(height: 24),
                        // 柱状图 + 分类占比 — 桌面端横排，手机端竖排
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildBarChartCard()),
                              const SizedBox(width: 20),
                              Expanded(child: _buildCategoryCard()),
                            ],
                          )
                        else ...[
                          _buildBarChartCard(),
                          const SizedBox(height: 20),
                          _buildCategoryCard(),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTotalCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: 0.9 + 0.1 * v, child: Opacity(opacity: v, child: child)),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: AppTheme.headerGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 12))],
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_rounded, color: Colors.white70, size: 18),
                SizedBox(width: 6),
                Text('本月总支出', style: TextStyle(color: Colors.white70, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _totalThisMonth),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Text(
                '¥${v.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard() {
    final maxTotal = _monthlyData.map((e) => e['total'] as double).fold<double>(1, (a, b) => a > b ? a : b);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (_, v, child) => Transform.translate(offset: Offset(0, 30 * (1 - v)), child: Opacity(opacity: v, child: child)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: AppTheme.cardShadow, blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up_rounded, color: AppTheme.primaryColor, size: 20),
                SizedBox(width: 8),
                Text('近6个月趋势', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxTotal * 1.3,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                        '¥${rod.toY.toStringAsFixed(0)}',
                        const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i >= 0 && i < _monthlyData.length) {
                        return Padding(padding: const EdgeInsets.only(top: 8), child: Text(_monthlyData[i]['month'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)));
                      }
                      return const SizedBox();
                    })),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: _monthlyData.asMap().entries.map((entry) {
                    final isLast = entry.key == _monthlyData.length - 1;
                    return BarChartGroupData(x: entry.key, barRods: [
                      BarChartRodData(
                        toY: entry.value['total'] as double,
                        gradient: isLast
                            ? const LinearGradient(colors: [Color(0xFF0D7C85), Color(0xFF0097A7)], begin: Alignment.bottomCenter, end: Alignment.topCenter)
                            : null,
                        color: isLast ? null : AppTheme.primaryColor.withValues(alpha: 0.4),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (_, v, child) => Transform.translate(offset: Offset(0, 30 * (1 - v)), child: Opacity(opacity: v, child: child)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: AppTheme.cardShadow, blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart_rounded, color: AppTheme.primaryColor, size: 20),
                SizedBox(width: 8),
                Text('本月分类占比', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            ..._currentMonthStats.entries.toList().asMap().entries.map((entry) {
              final color = AppTheme.expenseColors[entry.value.key] ?? Colors.grey;
              final icon = AppTheme.expenseIcons[entry.value.key] ?? Icons.circle;
              final pct = _totalThisMonth > 0 ? entry.value.value / _totalThisMonth : 0.0;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct),
                duration: Duration(milliseconds: 600 + entry.key * 150),
                curve: Curves.easeOutCubic,
                builder: (_, animPct, __) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.value.key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                                Text('¥${entry.value.value.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: animPct,
                                backgroundColor: color.withValues(alpha: 0.08),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}