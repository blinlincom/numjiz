import '../models/expense.dart';

abstract class StorageInterface {
  Future<void> init();
  Future<int> insertExpense(Expense e);
  Future<int> updateExpense(Expense e);
  Future<int> deleteExpense(int id);
  Future<void> batchReimburse(List<int> ids);
  Future<void> batchCancelReimburse(List<int> ids);
  Future<List<Expense>> getExpensesByMonth(DateTime m);
  Future<List<Expense>> getAllExpenses({int? limit, int? offset});
  Future<List<String>> getPlates();
  Future<void> addPlate(String plate);
  Future<void> removePlate(String plate);
  Future<Map<String, String>> getDriverNames();
  Future<void> setDriverName(String plate, String name);
  Future<List<String>> getExpenseTypes();
  Future<void> addExpenseType(String type);
  Future<void> removeExpenseType(String type);
  String exportJson();
  Future<int> importJson(String jsonStr);
}