import 'dart:convert';
import 'dart:html' as html;
import '../models/expense.dart';
import 'storage_interface.dart';

class WebStorageImpl implements StorageInterface {
  int _nextId = 1;
  List<Expense> _list = [];
  List<String> _plates = [];
  List<String> _expenseTypes = ['充电费', '过路费', '停车费', '货物买赔', '借支'];
  Map<String, String> _driverNames = {};

  @override
  Future<void> init() async {
    try {
      final s = html.window.localStorage['cold_chain_expenses'];
      if (s != null && s.isNotEmpty) {
        final l = json.decode(s) as List<dynamic>;
        _list = l.map((e) => Expense.fromMap(e as Map<String, dynamic>)).toList();
        if (_list.isNotEmpty) {
          _nextId = _list.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
        }
      }
    } catch (_) { _list = []; }
    try {
      final p = html.window.localStorage['cold_chain_plates'];
      if (p != null && p.isNotEmpty) {
        _plates = (json.decode(p) as List<dynamic>).cast<String>();
      }
    } catch (_) { _plates = []; }
    try {
      final t = html.window.localStorage['expense_types'];
      if (t != null && t.isNotEmpty) {
        _expenseTypes = (json.decode(t) as List<dynamic>).cast<String>();
      }
    } catch (_) {}
    try {
      final d = html.window.localStorage['driver_names'];
      if (d != null && d.isNotEmpty) {
        _driverNames = Map<String, String>.from(json.decode(d) as Map);
      }
    } catch (_) {}
  }

  void _save() {
    try { html.window.localStorage['cold_chain_expenses'] = json.encode(_list.map((e) => e.toMap()).toList()); } catch (_) {}
  }

  void _savePlates() {
    try { html.window.localStorage['cold_chain_plates'] = json.encode(_plates); } catch (_) {}
  }

  @override
  Future<List<String>> getPlates() async => List.from(_plates);

  @override
  Future<void> addPlate(String plate) async {
    if (!_plates.contains(plate)) { _plates.add(plate); _savePlates(); }
  }

  @override
  Future<void> removePlate(String plate) async {
    _plates.remove(plate); _savePlates();
  }

  void _saveTypes() {
    try { html.window.localStorage['expense_types'] = json.encode(_expenseTypes); } catch (_) {}
  }

  @override
  Future<List<String>> getExpenseTypes() async => List.from(_expenseTypes);

  @override
  Future<void> addExpenseType(String type) async {
    if (!_expenseTypes.contains(type)) { _expenseTypes.add(type); _saveTypes(); }
  }

  @override
  Future<void> removeExpenseType(String type) async {
    _expenseTypes.remove(type); _saveTypes();
  }

  void _saveDriverNames() {
    try { html.window.localStorage['driver_names'] = json.encode(_driverNames); } catch (_) {}
  }

  @override
  Future<Map<String, String>> getDriverNames() async => Map.from(_driverNames);

  @override
  Future<void> setDriverName(String plate, String name) async {
    if (name.isEmpty) {
      _driverNames.remove(plate);
    } else {
      _driverNames[plate] = name;
    }
    _saveDriverNames();
  }

  @override
  Future<int> insertExpense(Expense e) async {
    final ne = Expense(id: _nextId, type: e.type, amount: e.amount, note: e.note, date: e.date, location: e.location, imagePath: e.imagePath, reimbursed: e.reimbursed, plateNumber: e.plateNumber);
    _nextId++; _list.add(ne); _save(); return ne.id!;
  }

  @override
  Future<int> updateExpense(Expense e) async {
    final i = _list.indexWhere((x) => x.id == e.id);
    if (i != -1) { _list[i] = e; _save(); return 1; } return 0;
  }

  @override
  Future<int> deleteExpense(int id) async { _list.removeWhere((x) => x.id == id); _save(); return 1; }

  @override
  Future<void> batchReimburse(List<int> ids) async {
    for (var i = 0; i < _list.length; i++) {
      if (ids.contains(_list[i].id)) {
        _list[i] = _list[i].copyWith(reimbursed: true);
      }
    }
    _save();
  }

  @override
  Future<void> batchCancelReimburse(List<int> ids) async {
    for (var i = 0; i < _list.length; i++) {
      if (ids.contains(_list[i].id)) {
        _list[i] = _list[i].copyWith(reimbursed: false);
      }
    }
    _save();
  }

  @override
  Future<List<Expense>> getExpensesByMonth(DateTime m) async {
    return _list.where((x) => x.date.year == m.year && x.date.month == m.month).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<List<Expense>> getAllExpenses({int? limit, int? offset}) async {
    final s = List<Expense>.from(_list)..sort((a, b) => b.date.compareTo(a.date));
    final st = offset ?? 0; final ed = limit != null ? (st + limit).clamp(0, s.length) : s.length;
    return s.sublist(st, ed);
  }

  @override
  String exportJson() => json.encode(_list.map((e) => e.toMap()).toList());

  @override
  Future<int> importJson(String jsonStr) async {
    final l = json.decode(jsonStr) as List<dynamic>;
    final imported = l.map((e) => Expense.fromMap(e as Map<String, dynamic>)).toList();
    for (var e in imported) {
      final ne = Expense(id: _nextId, type: e.type, amount: e.amount, note: e.note, date: e.date, location: e.location, imagePath: e.imagePath, reimbursed: e.reimbursed, plateNumber: e.plateNumber);
      _nextId++; _list.add(ne);
    }
    _save();
    return imported.length;
  }
}

StorageInterface createStorage() => WebStorageImpl();