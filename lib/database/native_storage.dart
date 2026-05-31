import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/expense.dart';
import 'storage_interface.dart';

class NativeStorageImpl implements StorageInterface {
  int _nextId = 1;
  List<Expense> _list = [];
  List<String> _plates = [];
  File? _dataFile;
  File? _platesFile;

  @override
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final dirPath = dir.path;

    _dataFile = File('$dirPath/cold_chain_expenses.json');
    _platesFile = File('$dirPath/cold_chain_plates.json');

    // Load expenses
    try {
      if (await _dataFile!.exists()) {
        final s = await _dataFile!.readAsString();
        if (s.isNotEmpty) {
          final l = json.decode(s) as List<dynamic>;
          _list = l.map((e) => Expense.fromMap(e as Map<String, dynamic>)).toList();
          if (_list.isNotEmpty) {
            _nextId = _list.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
          }
        }
      }
    } catch (_) {
      _list = [];
    }

    // Load plates
    try {
      if (await _platesFile!.exists()) {
        final p = await _platesFile!.readAsString();
        if (p.isNotEmpty) {
          _plates = (json.decode(p) as List<dynamic>).cast<String>();
        }
      }
    } catch (_) {
      _plates = [];
    }
  }

  Future<void> _save() async {
    if (_dataFile != null) {
      await _dataFile!.writeAsString(json.encode(_list.map((e) => e.toMap()).toList()));
    }
  }

  Future<void> _savePlates() async {
    if (_platesFile != null) {
      await _platesFile!.writeAsString(json.encode(_plates));
    }
  }

  @override
  Future<List<String>> getPlates() async => List.from(_plates);

  @override
  Future<void> addPlate(String p) async {
    if (!_plates.contains(p)) {
      _plates.add(p);
      await _savePlates();
    }
  }

  @override
  Future<void> removePlate(String p) async {
    _plates.remove(p);
    await _savePlates();
  }

  @override
  Future<int> insertExpense(Expense e) async {
    final ne = Expense(
      id: _nextId,
      type: e.type,
      amount: e.amount,
      note: e.note,
      date: e.date,
      location: e.location,
      imagePath: e.imagePath,
      reimbursed: e.reimbursed,
      plateNumber: e.plateNumber,
    );
    _nextId++;
    _list.add(ne);
    await _save();
    return ne.id!;
  }

  @override
  Future<int> updateExpense(Expense e) async {
    final i = _list.indexWhere((x) => x.id == e.id);
    if (i != -1) {
      _list[i] = e;
      await _save();
      return 1;
    }
    return 0;
  }

  @override
  Future<int> deleteExpense(int id) async {
    _list.removeWhere((x) => x.id == id);
    await _save();
    return 1;
  }

  @override
  Future<void> batchReimburse(List<int> ids) async {
    for (var i = 0; i < _list.length; i++) {
      if (ids.contains(_list[i].id)) {
        _list[i] = _list[i].copyWith(reimbursed: true);
      }
    }
    await _save();
  }

  @override
  Future<List<Expense>> getExpensesByMonth(DateTime m) async {
    return _list
        .where((x) => x.date.year == m.year && x.date.month == m.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<List<Expense>> getAllExpenses({int? limit, int? offset}) async {
    final s = List<Expense>.from(_list)..sort((a, b) => b.date.compareTo(a.date));
    final st = offset ?? 0;
    final ed = limit != null ? (st + limit).clamp(0, s.length) : s.length;
    return s.sublist(st, ed);
  }

  @override
  String exportJson() => json.encode(_list.map((e) => e.toMap()).toList());

  @override
  Future<int> importJson(String jsonStr) async {
    final l = json.decode(jsonStr) as List<dynamic>;
    for (var item in l) {
      final e = Expense.fromMap(item as Map<String, dynamic>);
      final ne = Expense(
        id: _nextId,
        type: e.type,
        amount: e.amount,
        note: e.note,
        date: e.date,
        location: e.location,
        imagePath: e.imagePath,
        reimbursed: e.reimbursed,
        plateNumber: e.plateNumber,
      );
      _nextId++;
      _list.add(ne);
    }
    await _save();
    return l.length;
  }
}

StorageInterface createStorage() => NativeStorageImpl();