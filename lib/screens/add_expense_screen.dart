import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../database/database_helper.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;
  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedType = '充电费';
  DateTime _selectedDate = DateTime.now();
  String? _selectedPlate;
  List<String> _plates = [];
  bool _saving = false;

  final List<String> _types = ['充电费', '过路费', '停车费', '货物买赔'];
  bool get isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    _loadPlates();
    if (widget.expense != null) {
      _selectedType = widget.expense!.type;
      _amountController.text = widget.expense!.amount.toString();
      _noteController.text = widget.expense!.note ?? '';
      _locationController.text = widget.expense!.location ?? '';
      _selectedDate = widget.expense!.date;
      _selectedPlate = widget.expense!.plateNumber;
    }
  }

  Future<void> _loadPlates() async {
    await DatabaseHelper.ensureInit();
    final plates = await DatabaseHelper.instance.getPlates();
    setState(() {
      _plates = plates;
      // 如果编辑模式下车牌不在列表中，也保留
      if (_selectedPlate != null && _selectedPlate!.isNotEmpty && !_plates.contains(_selectedPlate)) {
        _plates.insert(0, _selectedPlate!);
      }
      // 如果只有一个车牌且不是编辑模式，自动选中
      if (!isEditing && _plates.length == 1 && _selectedPlate == null) {
        _selectedPlate = _plates.first;
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _selectedDate,
      firstDate: DateTime(2020), lastDate: DateTime(2030),
    );
    if (picked != null) {
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_selectedDate));
      if (time != null) {
        setState(() => _selectedDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final expense = Expense(
        id: widget.expense?.id, type: _selectedType,
        amount: double.parse(_amountController.text),
        note: _noteController.text, date: _selectedDate,
        location: _locationController.text,
        plateNumber: _selectedPlate,
      );

      if (isEditing) {
        await DatabaseHelper.instance.updateExpense(expense);
      } else {
        await DatabaseHelper.instance.insertExpense(expense);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('保存失败: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.errorColor,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = Responsive.contentMaxWidth(context);
    final padding = Responsive.horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑记账' : '记一笔', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(padding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 车牌选择
                  _buildSectionTitle('车牌号', Icons.directions_car_rounded),
                  const SizedBox(height: 12),
                  _buildPlateSelector(),
                  const SizedBox(height: 28),
                  // 费用类型
                  _buildSectionTitle('费用类型', Icons.category_rounded),
                  const SizedBox(height: 12),
                  _buildTypeSelector(),
                  const SizedBox(height: 28),
                  // 金额
                  _buildSectionTitle('金额', Icons.payments_rounded),
                  const SizedBox(height: 12),
                  _buildAmountField(),
                  const SizedBox(height: 28),
                  // 日期
                  _buildSectionTitle('日期时间', Icons.schedule_rounded),
                  const SizedBox(height: 12),
                  _buildDatePicker(),
                  const SizedBox(height: 28),
                  // 备注
                  _buildSectionTitle('备注', Icons.notes_rounded),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(hintText: '添加备注信息...'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 28),
                  // 地点
                  _buildSectionTitle('地点', Icons.location_on_rounded),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(hintText: '记录发生地点...'),
                  ),
                  const SizedBox(height: 40),
                  // 保存按钮
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Text(isEditing ? '更新记录' : '保存记录', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _buildPlateSelector() {
    if (_plates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
            const SizedBox(width: 10),
            const Expanded(child: Text('请先在设置中添加车牌号', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
            TextButton(
              onPressed: () async {
                await Navigator.pushNamed(context, '/plates');
                _loadPlates();
              },
              child: const Text('去添加'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPlate,
          isExpanded: true,
          hint: const Text('选择车牌号'),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          borderRadius: BorderRadius.circular(14),
          items: _plates.map((plate) => DropdownMenuItem(
            value: plate,
            child: Row(
              children: [
                const Icon(Icons.directions_car_rounded, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 10),
                Text(plate, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1)),
              ],
            ),
          )).toList(),
          onChanged: (v) => setState(() => _selectedPlate = v),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 10, runSpacing: 10,
      children: _types.map((type) {
        final selected = _selectedType == type;
        final color = AppTheme.expenseColors[type] ?? AppTheme.primaryColor;
        final icon = AppTheme.expenseIcons[type] ?? Icons.circle;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: selected ? color : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? color : AppTheme.dividerColor, width: selected ? 2 : 1),
              boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(icon, key: ValueKey(selected), size: 20, color: selected ? Colors.white : color),
                ),
                const SizedBox(width: 8),
                Text(type, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppTheme.textPrimary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmountField() {
    final color = AppTheme.expenseColors[_selectedType] ?? AppTheme.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text('¥', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: color),
              decoration: const InputDecoration(
                hintText: '0.00', border: InputBorder.none,
                enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return '请输入金额';
                if (double.tryParse(v) == null) return '请输入有效金额';
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryColor, size: 18),
            ),
            const SizedBox(width: 14),
            Text(DateFormat('yyyy-MM-dd HH:mm').format(_selectedDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}