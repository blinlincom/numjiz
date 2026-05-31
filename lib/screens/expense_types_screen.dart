import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class ExpenseTypesScreen extends StatefulWidget {
  const ExpenseTypesScreen({super.key});

  @override
  State<ExpenseTypesScreen> createState() => _ExpenseTypesScreenState();
}

class _ExpenseTypesScreenState extends State<ExpenseTypesScreen> {
  List<String> _types = [];
  bool _loading = true;

  // 默认类型不可删除
  static const _defaultTypes = ['充电费', '过路费', '停车费', '货物买赔', '借支'];

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    await DatabaseHelper.ensureInit();
    final types = await DatabaseHelper.instance.getExpenseTypes();
    setState(() { _types = types; _loading = false; });
  }

  Future<void> _addType() async {
    final controller = TextEditingController();
    String? errorText;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('添加费用类型', style: TextStyle(fontWeight: FontWeight.w700)),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '例如：加油费',
              prefixIcon: const Icon(Icons.category_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              errorText: errorText,
            ),
            onChanged: (_) {
              if (errorText != null) setDialogState(() => errorText = null);
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  setDialogState(() => errorText = '请输入类型名称');
                  return;
                }
                if (text.length > 6) {
                  setDialogState(() => errorText = '名称不超过6个字');
                  return;
                }
                if (_types.contains(text)) {
                  setDialogState(() => errorText = '该类型已存在');
                  return;
                }
                Navigator.pop(ctx, text);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
    if (result != null && result.isNotEmpty) {
      await DatabaseHelper.instance.addExpenseType(result);
      _loadTypes();
    }
  }

  Future<void> _removeType(String type) async {
    if (_defaultTypes.contains(type)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('「$type」为默认类型，不可删除'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.warningColor,
      ));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('删除类型'),
        content: Text('确定要删除费用类型「$type」吗？\n已有的该类型记录不会被删除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.removeExpenseType(type);
      _loadTypes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = Responsive.contentMaxWidth(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('费用类型管理', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
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
                    // 说明卡片
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppTheme.headerGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.category_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('费用类型管理', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                SizedBox(height: 4),
                                Text('自定义记账分类，默认类型不可删除', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 类型列表
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _types.length,
                        itemBuilder: (context, index) {
                          final type = _types[index];
                          final isDefault = _defaultTypes.contains(type);
                          final color = AppTheme.expenseColors[type] ?? AppTheme.primaryColor;
                          final icon = AppTheme.expenseIcons[type] ?? Icons.label_rounded;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: AppTheme.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(icon, color: color),
                              ),
                              title: Text(type, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              trailing: isDefault
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.textSecondary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('默认', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
                                      onPressed: () => _removeType(type),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addType,
        icon: const Icon(Icons.add_rounded),
        label: const Text('添加类型'),
      ),
    );
  }
}