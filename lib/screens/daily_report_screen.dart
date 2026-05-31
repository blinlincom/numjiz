import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';

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

  List<Expense> get _today => _expenses.where((e) =>
      e.date.year == _selectedDate.year &&
      e.date.month == _selectedDate.month &&
      e.date.day == _selectedDate.day).toList();

  String _buildReportText() {
    if (_today.isEmpty) return '';
    final dateStr = DateFormat('yyyy年M月d日').format(_selectedDate);
    final weekDay = DateFormat('EEEE').format(_selectedDate);
    final buf = StringBuffer();
    buf.writeln('$dateStr $weekDay 收支汇总');
    buf.writeln('------------------------------');

    final plates = _today.map((e) => e.plateNumber ?? '').where((p) => p.isNotEmpty).toSet();
    double totalExpense = 0;
    double totalBorrow = 0;

    for (final plate in plates) {
      final pes = _today.where((e) => (e.plateNumber ?? '') == plate).toList();
      if (pes.isEmpty) continue;
      buf.writeln('【$plate】');

      final Map<String, double> merged = {};
      for (final e in pes) { merged[e.type] = (merged[e.type] ?? 0) + e.amount; }

      double plateTotal = 0;
      for (final e in merged.entries) {
        if (e.key == '借支') {
          totalBorrow += e.value;
          buf.writeln('  借支: ${e.value.toStringAsFixed(2)}');
        } else {
          plateTotal += e.value;
          buf.writeln('  ${e.key}: ${e.value.toStringAsFixed(2)}');
        }
      }
      if (plateTotal > 0) {
        buf.writeln('  小计: ${plateTotal.toStringAsFixed(2)}');
        totalExpense += plateTotal;
      }
    }

    buf.writeln('------------------------------');
    if (totalExpense > 0) buf.writeln('费用合计: ${totalExpense.toStringAsFixed(2)}');
    if (totalBorrow > 0) buf.writeln('借支合计: ${totalBorrow.toStringAsFixed(2)}');
    buf.writeln('总计: ${(totalExpense + totalBorrow).toStringAsFixed(2)}');

    return buf.toString();
  }

  void _copyReport() {
    final text = _buildReportText();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('当天暂无记录'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.warningColor,
      ));
      return;
    }
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('已复制到剪贴板'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppTheme.successColor,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('每日账单', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 日期选择器
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.headerGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                        onPressed: () { _selectedDate = _selectedDate.subtract(const Duration(days: 1)); _load(); },
                      ),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('yyyy年M月d日').format(_selectedDate),
                              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              DateFormat('EEEE').format(_selectedDate),
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                        onPressed: () { _selectedDate = _selectedDate.add(const Duration(days: 1)); _load(); },
                      ),
                    ],
                  ),
                ),
                // 报告内容
                Expanded(
                  child: _today.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_note_rounded, size: 56, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              const Text('当天暂无记录', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                            ],
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.dividerColor),
                          ),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              _buildReportText(),
                              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.7, fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                ),
                // 底部按钮
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _today.isEmpty ? null : _copyReport,
                      icon: const Icon(Icons.content_copy_rounded, size: 20),
                      label: const Text('复制账单文本', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}