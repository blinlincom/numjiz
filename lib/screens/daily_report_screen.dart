import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Expense> _expenses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await DatabaseHelper.ensureInit();
    _expenses = await DatabaseHelper.instance.getExpensesByMonth(_selectedDate);
    setState(() => _loading = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      _selectedDate = picked;
      _load();
    }
  }

  String _buildReportText() {
    final today = _expenses.where((e) =>
        e.date.year == _selectedDate.year &&
        e.date.month == _selectedDate.month &&
        e.date.day == _selectedDate.day).toList();

    if (today.isEmpty) return '';

    final dateStr = DateFormat('yyyy年M月d日').format(_selectedDate);
    final weekDay = DateFormat('EEEE', 'zh_CN').format(_selectedDate);
    final buf = StringBuffer();
    buf.writeln('📋 $dateStr $weekDay 收支汇总');
    buf.writeln('──────────────────────');

    // 获取车牌列表
    final plates = today.map((e) => e.plateNumber ?? '').where((p) => p.isNotEmpty).toSet();

    double totalExpense = 0;
    double totalBorrow = 0;

    for (final plate in plates) {
      final plateExpenses = today.where((e) => (e.plateNumber ?? '') == plate).toList();
      if (plateExpenses.isEmpty) continue;

      buf.writeln('🚗 车牌: $plate');

      // 按类型合并
      final Map<String, double> merged = {};
      for (final e in plateExpenses) {
        merged[e.type] = (merged[e.type] ?? 0) + e.amount;
      }

      double plateTotal = 0;
      for (final entry in merged.entries) {
        if (entry.key == '借支') {
          totalBorrow += entry.value;
          buf.writeln('  💰 借支: ¥${entry.value.toStringAsFixed(2)}');
        } else {
          plateTotal += entry.value;
          buf.writeln('  ${entry.key}: ¥${entry.value.toStringAsFixed(2)}');
        }
      }
      if (plateTotal > 0) {
        buf.writeln('  ─────────');
        buf.writeln('  小计: ¥${plateTotal.toStringAsFixed(2)}');
        totalExpense += plateTotal;
      }
    }

    buf.writeln('──────────────────────');
    if (totalExpense > 0) {
      buf.writeln('💰 费用合计: ¥${totalExpense.toStringAsFixed(2)}');
    }
    if (totalBorrow > 0) {
      buf.writeln('💳 借支合计: ¥${totalBorrow.toStringAsFixed(2)}');
    }
    buf.writeln('📊 总计: ¥${(totalExpense + totalBorrow).toStringAsFixed(2)}');

    return buf.toString();
  }

  void _copyReport() {
    final text = _buildReportText();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('当天暂无记录'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.warningColor,
      ));
      return;
    }
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('已复制到剪贴板，可直接粘贴到微信'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppTheme.successColor,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = Responsive.contentMaxWidth(context);
    final today = _expenses.where((e) =>
        e.date.year == _selectedDate.year &&
        e.date.month == _selectedDate.month &&
        e.date.day == _selectedDate.day).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('每日账单', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // 日期选择器
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.headerGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: Colors.white),
                            onPressed: () {
                              _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                              _load();
                            },
                          ),
                          GestureDetector(
                            onTap: _pickDate,
                            child: Column(
                              children: [
                                Text(
                                  DateFormat('yyyy年M月d日').format(_selectedDate),
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('EEEE', 'zh_CN').format(_selectedDate),
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: Colors.white),
                            onPressed: () {
                              _selectedDate = _selectedDate.add(const Duration(days: 1));
                              _load();
                            },
                          ),
                        ],
                      ),
                    ),
                    // 报告预览
                    if (today.isNotEmpty) ...[
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.dividerColor),
                          ),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              _buildReportText(),
                              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.6),
                            ),
                          ),
                        ),
                      ),
                    ] else
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_note_rounded, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              const Text('当天暂无记录', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    // 底部按钮
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: today.isEmpty ? null : _copyReport,
                          icon: const Icon(Icons.content_copy_rounded),
                          label: const Text('复制并分享到微信', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}