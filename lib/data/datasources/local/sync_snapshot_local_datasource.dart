import 'package:hive_flutter/hive_flutter.dart';

abstract class SyncSnapshotLocalDataSource {
  Future<void> saveGeneratedAt(String value);
  Future<String?> getGeneratedAt();
  Future<void> saveBudgets(List<Map<String, dynamic>> budgets);
  Future<List<Map<String, dynamic>>> getBudgets();
  Future<void> saveWallets(List<Map<String, dynamic>> wallets);
  Future<List<Map<String, dynamic>>> getWallets();
}

class SyncSnapshotLocalDataSourceImpl implements SyncSnapshotLocalDataSource {
  static const String boxName = 'sync_snapshot_box';
  static const String generatedAtKey = 'generated_at';
  static const String budgetsKey = 'budgets';
  static const String walletsKey = 'wallets';

  Future<Box<dynamic>> _openBox() {
    return Hive.openBox<dynamic>(boxName);
  }

  @override
  Future<void> saveGeneratedAt(String value) async {
    final box = await _openBox();
    await box.put(generatedAtKey, value);
  }

  @override
  Future<String?> getGeneratedAt() async {
    final box = await _openBox();
    return box.get(generatedAtKey) as String?;
  }

  @override
  Future<void> saveBudgets(List<Map<String, dynamic>> budgets) async {
    final box = await _openBox();
    await box.put(budgetsKey, budgets);
  }

  @override
  Future<List<Map<String, dynamic>>> getBudgets() async {
    final box = await _openBox();
    final raw = box.get(budgetsKey) as List<dynamic>? ?? const [];
    return raw
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  @override
  Future<void> saveWallets(List<Map<String, dynamic>> wallets) async {
    final box = await _openBox();
    await box.put(walletsKey, wallets);
  }

  @override
  Future<List<Map<String, dynamic>>> getWallets() async {
    final box = await _openBox();
    final raw = box.get(walletsKey) as List<dynamic>? ?? const [];
    return raw
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}
