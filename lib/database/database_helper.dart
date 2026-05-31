import 'dart:convert';
import '../models/expense.dart';
import 'storage_interface.dart';
import 'storage_stub.dart'
    if (dart.library.html) 'web_storage.dart'
    if (dart.library.io) 'native_storage.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._ctor();
  static StorageInterface? _storage;
  static bool _ready = false;

  DatabaseHelper._ctor();

  static Future<void> ensureInit() async {
    if (_ready) return;
    _storage = createStorage();
    await _storage!.init();
    _ready = true;
  }

  Future<StorageInterface> get _s async {
    await ensureInit();
    return _storage!;
  }

  // ===== 车牌管理 =====
  Future<List<String>> getPlates() async => (await _s).getPlates();
  Future<void> addPlate(String plate) async => (await _s).addPlate(plate);
  Future<void> removePlate(String plate) async => (await _s).removePlate(plate);

  // ===== 记账 CRUD =====
  Future<int> insertExpense(Expense e) async => (await _s).insertExpense(e);
  Future<int> updateExpense(Expense e) async => (await _s).updateExpense(e);
  Future<int> deleteExpense(int id) async => (await _s).deleteExpense(id);

  Future<void> batchReimburse(List<int> ids) async => (await _s).batchReimburse(ids);

  Future<List<Expense>> getExpensesByMonth(DateTime m) async => (await _s).getExpensesByMonth(m);
  Future<List<Expense>> getAllExpenses({int? limit, int? offset}) async => (await _s).getAllExpenses(limit: limit, offset: offset);

  Future<Map<String, double>> getMonthlyStats(DateTime m) async {
    final ex = await getExpensesByMonth(m);
    final s = <String, double>{'充电费': 0, '过路费': 0, '停车费': 0, '货物买赔': 0};
    for (var e in ex) { s[e.type] = (s[e.type] ?? 0) + e.amount; }
    return s;
  }

  Future<double> getTotalByMonth(DateTime m) async {
    final s = await getMonthlyStats(m);
    return s.values.fold<double>(0, (a, b) => a + b);
  }

  // 备份导出
  Future<String> exportBackup() async {
    final all = await getAllExpenses();
    return json.encode(all.map((e) => e.toMap()).toList());
  }

  // 备份导入
  Future<int> importBackup(String jsonStr) async => (await _s).importJson(jsonStr);
}