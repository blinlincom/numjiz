import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class PlatesScreen extends StatefulWidget {
  const PlatesScreen({super.key});

  @override
  State<PlatesScreen> createState() => _PlatesScreenState();
}

class _PlatesScreenState extends State<PlatesScreen> {
  List<String> _plates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlates();
  }

  Future<void> _loadPlates() async {
    await DatabaseHelper.ensureInit();
    final plates = await DatabaseHelper.instance.getPlates();
    setState(() { _plates = plates; _loading = false; });
  }

  Future<void> _addPlate() async {
    final controller = TextEditingController();
    String? errorText;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('添加车牌', style: TextStyle(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: '例如：京A12345',
                  prefixIcon: const Icon(Icons.directions_car_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  errorText: errorText,
                ),
                onChanged: (_) {
                  if (errorText != null) setDialogState(() => errorText = null);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  setDialogState(() => errorText = '请输入车牌号');
                  return;
                }
                if (text.length < 7 || text.length > 8) {
                  setDialogState(() => errorText = '车牌号长度应为7-8位');
                  return;
                }
                // 简单校验：首字符为汉字，第二位为字母
                final firstChar = text.characters.first;
                final provinces = '京津沪渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤川青藏琼宁';
                if (!provinces.contains(firstChar)) {
                  setDialogState(() => errorText = '首位应为省份简称（如京、沪、粤）');
                  return;
                }
                final secondChar = text.length > 1 ? text[text.characters.first.length] : '';
                if (!RegExp(r'^[A-Z]$').hasMatch(secondChar)) {
                  setDialogState(() => errorText = '第二位应为大写字母');
                  return;
                }
                if (_plates.contains(text)) {
                  setDialogState(() => errorText = '该车牌已存在');
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
      await DatabaseHelper.instance.addPlate(result);
      _loadPlates();
    }
  }

  Future<void> _removePlate(String plate) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('删除车牌'),
        content: Text('确定要删除车牌「$plate」吗？'),
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
      await DatabaseHelper.instance.removePlate(plate);
      _loadPlates();
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = Responsive.contentMaxWidth(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('车牌管理', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
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
                            child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('车牌号管理', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                SizedBox(height: 4),
                                Text('添加常用车牌，记账时快速选择', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 车牌列表
                    Expanded(
                      child: _plates.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 80, height: 80,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: const Icon(Icons.directions_car_outlined, size: 40, color: AppTheme.primaryColor),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('暂无车牌', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                                  const SizedBox(height: 8),
                                  const Text('点击右下角按钮添加车牌', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _plates.length,
                              itemBuilder: (context, index) {
                                final plate = _plates[index];
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
                                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.directions_car_rounded, color: AppTheme.primaryColor),
                                    ),
                                    title: Text(plate, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
                                      onPressed: () => _removePlate(plate),
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
        onPressed: _addPlate,
        icon: const Icon(Icons.add_rounded),
        label: const Text('添加车牌'),
      ),
    );
  }
}