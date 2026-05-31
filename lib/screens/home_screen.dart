import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/expense.dart';
import '../database/database_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/expense_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/pie_chart_widget.dart';
import '../utils/responsive.dart';
import 'add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Expense> _expenses = [];
  Map<String, double> _monthStats = {};
  double _totalMonth = 0;
  bool _loading = true;
  bool _selectMode = false;
  final Set<int> _selectedIds = {};
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _filterTab = 0; // 0=全部, 1=未报账, 2=已报账

  List<Expense> get _filteredExpenses {
    if (_filterTab == 1) return _expenses.where((e) => !e.reimbursed).toList();
    if (_filterTab == 2) return _expenses.where((e) => e.reimbursed).toList();
    return _expenses;
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() { _fadeController.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    _expenses = await DatabaseHelper.instance.getExpensesByMonth(now);
    _monthStats = await DatabaseHelper.instance.getMonthlyStats(now);
    _totalMonth = _monthStats.values.fold<double>(0, (a, b) => a + b);
    setState(() => _loading = false);
    _fadeController.forward(from: 0);
  }

  Future<void> _deleteExpense(int id) async {
    await DatabaseHelper.instance.deleteExpense(id);
    _loadData();
  }

  Future<void> _navigateToAdd({Expense? expense}) async {
    final result = await Navigator.push<bool>(context, PageRouteBuilder(
      pageBuilder: (_, anim, __) => AddExpenseScreen(expense: expense),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: anim, child: child),
      ),
      transitionDuration: const Duration(milliseconds: 350),
    ));
    if (result == true) _loadData();
  }

  void _toggleSelectMode() {
    setState(() { _selectMode = !_selectMode; _selectedIds.clear(); });
  }

  Future<void> _batchReimburse() async {
    if (_selectedIds.isEmpty) return;

    // 排除借支（借支不参与报账）
    final borrowIds = _expenses.where((e) => e.type == '借支' && _selectedIds.contains(e.id)).toList();
    final validIds = _selectedIds.where((id) => !borrowIds.any((e) => e.id == id)).toList();

    if (borrowIds.isNotEmpty) {
      final borrowed = borrowIds.map((e) => '「借支 ¥${e.amount.toStringAsFixed(2)}」').join(', ');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$borrowed 为借支，不参与报账'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.warningColor,
      ));
      // 从选中列表中移除借支
      setState(() => _selectedIds.removeAll(borrowIds.map((e) => e.id!)));
    }

    if (validIds.isEmpty) return;

    // 确认对话框
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('确认报账', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('确定将选中的 ${validIds.length} 笔记录标记为已报账？\n（借支类型不参与报账）'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认报账'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await DatabaseHelper.instance.batchReimburse(validIds);
    setState(() { _selectMode = false; _selectedIds.clear(); });
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('已标记为报账完成'), behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppTheme.successColor,
      ));
    }
  }

  Future<void> _batchCancelReimburse() async {
    if (_selectedIds.isEmpty) return;

    // 借支独立标记，不参与取消报账
    final borrowIds = _expenses.where((e) => e.type == '借支' && _selectedIds.contains(e.id)).toList();
    final validIds = _selectedIds.where((id) => !borrowIds.any((e) => e.id == id)).toList();

    if (borrowIds.isNotEmpty) {
      final borrowed = borrowIds.map((e) => '「借支 ¥${e.amount.toStringAsFixed(2)}」').join(', ');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$borrowed 为借支，不参与取消报账'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.warningColor,
      ));
      setState(() => _selectedIds.removeAll(borrowIds.map((e) => e.id!)));
    }

    if (validIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('取消报账', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('确定将选中的 ${validIds.length} 笔记录取消报账状态？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('返回')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认取消'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await DatabaseHelper.instance.batchCancelReimburse(validIds);
    setState(() { _selectMode = false; _selectedIds.clear(); });
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('已取消报账状态'), behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppTheme.warningColor,
      ));
    }
  }

  Future<void> _exportBackup() async {
    final jsonStr = await DatabaseHelper.instance.exportBackup();
    final filename = 'niu_ma_backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json';

    if (kIsWeb) {
      // Web 端暂不支持文件分享
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('已导出 ${_expenses.length} 条记录（Web端请手动复制）'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.primaryColor,
        ));
      }
      return;
    }

    // 保存到临时目录
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(jsonStr);

    if (!mounted) return;

    // 弹出分享/查看对话框
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 24),
            SizedBox(width: 10),
            Text('导出成功', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('已导出 ${_expenses.length} 条记录'),
            const SizedBox(height: 8),
            Text('文件: $filename', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _shareFile(file.path);
            },
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('分享文件'),
          ),
        ],
      ),
    );
  }
  Future<void> _shareFile(String filePath) async {
    try {
      // 复制到外部可访问目录
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final shareDir = Directory('${extDir.path}/share');
        if (!await shareDir.exists()) await shareDir.create(recursive: true);
        final src = File(filePath);
        final dest = File('${shareDir.path}/${DateTime.now().millisecondsSinceEpoch}_backup.json');
        await src.copy(dest.path);

        const channel = MethodChannel('com.coldchain.driver/share');
        await channel.invokeMethod('shareFile', {'path': dest.path});
        return;
      }
    } catch (_) {}

    // Fallback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('文件已生成，请使用"每日账单"功能复制文本分享'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryColor,
      ));
    }
  }
  Future<void> _importBackup() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('导入备份'),
      content: SizedBox(
        width: 400,
        child: TextField(
          controller: controller, maxLines: 8,
          decoration: const InputDecoration(hintText: '粘贴备份 JSON 数据...', border: OutlineInputBorder()),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('导入')),
      ],
    ));
    if (result != null && result.isNotEmpty) {
      try {
        final count = await DatabaseHelper.instance.importBackup(result);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('成功导入 $count 条记录'), behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: AppTheme.successColor,
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('导入失败，请检查数据格式'), behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.errorColor,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('M月').format(DateTime.now());
    final padding = Responsive.horizontalPadding(context);
    final maxWidth = Responsive.contentMaxWidth(context);
    final columns = Responsive.gridColumns(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: _selectMode
            ? Text('已选 ${_selectedIds.length} 项', style: const TextStyle(fontWeight: FontWeight.w700))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                const AppLogo(size: 32, rounded: true),
                const SizedBox(width: 10),
                const Text('牛马记账', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
              ]),
        centerTitle: !isDesktop,
        leading: _selectMode ? IconButton(icon: const Icon(Icons.close), onPressed: _toggleSelectMode) : null,
        actions: _selectMode
            ? [
                TextButton.icon(
                  onPressed: _batchCancelReimburse,
                  icon: const Icon(Icons.undo_rounded, color: AppTheme.warningColor, size: 20),
                  label: const Text('取消报账', style: TextStyle(color: AppTheme.warningColor, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
                TextButton.icon(
                  onPressed: _batchReimburse,
                  icon: const Icon(Icons.check_circle_outline, color: AppTheme.successColor),
                  label: const Text('报账', style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.w700)),
                ),
              ]
            : [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) {
                    if (v == 'select') _toggleSelectMode();
                    if (v == 'export') _exportBackup();
                    if (v == 'import') _importBackup();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'select', child: Row(children: [Icon(Icons.checklist_rounded, size: 20), SizedBox(width: 10), Text('批量报账')])),
                    const PopupMenuItem(value: 'export', child: Row(children: [Icon(Icons.upload_rounded, size: 20), SizedBox(width: 10), Text('导出备份')])),
                    const PopupMenuItem(value: 'import', child: Row(children: [Icon(Icons.download_rounded, size: 20), SizedBox(width: 10), Text('导入备份')])),
                  ],
                ),
                const SizedBox(width: 4),
              ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 3))
            : FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      slivers: [
                        SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(padding), child: _buildHeaderCard(monthName))),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: padding),
                            child: GridView.count(
                              crossAxisCount: columns, shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 12, crossAxisSpacing: 12,
                              childAspectRatio: isDesktop ? 2.5 : 1.6,
                              children: _monthStats.entries.toList().asMap().entries.map((entry) {
                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: Duration(milliseconds: 400 + entry.key * 100),
                                  curve: Curves.easeOutBack,
                                  builder: (_, v, child) => Transform.scale(scale: v.clamp(0.0, 1.0), child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
                                  child: StatCard(title: entry.value.key, amount: entry.value.value, type: entry.value.key),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(padding, 28, padding, 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('最近记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                                  child: Text('${_filteredExpenses.length} 笔', style: const TextStyle(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: padding),
                            child: Container(
                              height: 38,
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  _buildFilterTab(0, '全部'),
                                  _buildFilterTab(1, '未报账'),
                                  _buildFilterTab(2, '已报账'),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_expenses.isEmpty)
                          SliverToBoxAdapter(child: _buildEmptyState(padding))
                        else
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: isDesktop ? padding - 16 : 0),
                            sliver: SliverList(delegate: SliverChildBuilderDelegate((context, index) {
                              final expense = _filteredExpenses[index];
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: Duration(milliseconds: 300 + index * 50),
                                curve: Curves.easeOut,
                                builder: (_, v, child) => Transform.translate(offset: Offset(0, 20 * (1 - v.clamp(0.0, 1.0))), child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
                                child: _selectMode
                                    ? _buildSelectableCard(expense)
                                    : ExpenseCard(expense: expense, onTap: () => _navigateToAdd(expense: expense), onDelete: () => _deleteExpense(expense.id!)),
                              );
                            }, childCount: _filteredExpenses.length)),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      floatingActionButton: _selectMode ? null : FloatingActionButton.extended(
        onPressed: () => _navigateToAdd(),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text('记一笔'),
      ),
    );
  }

  Widget _buildSelectableCard(Expense expense) {
    final selected = _selectedIds.contains(expense.id);
    final color = AppTheme.expenseColors[expense.type] ?? AppTheme.primaryColor;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) { _selectedIds.remove(expense.id); }
          else { _selectedIds.add(expense.id!); }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppTheme.primaryColor : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: AppTheme.cardShadow, blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: selected ? AppTheme.primaryColor : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
            ),
            const SizedBox(width: 12),
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(AppTheme.expenseIcons[expense.type] ?? Icons.receipt, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(expense.type, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  if (expense.reimbursed) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.successColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: const Text('已报账', style: TextStyle(fontSize: 10, color: AppTheme.successColor, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ]),
                if (expense.note != null && expense.note!.isNotEmpty)
                  Text(expense.note!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            Text('¥${expense.amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(String monthName) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$monthName 总支出', style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.local_shipping_rounded, color: Colors.white70, size: 14), SizedBox(width: 4),
              Text('牛马司机', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _totalMonth),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Text('¥${v.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: -1.5)),
        ),
        const SizedBox(height: 20),
        PieChartWidget(stats: _monthStats),
      ]),
    );
  }

  Widget _buildFilterTab(int index, String label) {
    final selected = _filterTab == index;
    final unrepCount = _expenses.where((e) => !e.reimbursed).length;
    final repCount = _expenses.where((e) => e.reimbursed).length;
    String displayLabel = label;
    if (index == 1 && unrepCount > 0) displayLabel = '未报账 $unrepCount';
    if (index == 2 && repCount > 0) displayLabel = '已报账 $repCount';

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            displayLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(double padding) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: padding, vertical: 20),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppTheme.cardShadow, blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.receipt_long_rounded, size: 36, color: AppTheme.primaryColor),
        ),
        const SizedBox(height: 16),
        const Text('暂无记账记录', style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text('点击下方按钮开始记账', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
      ]),
    );
  }
}