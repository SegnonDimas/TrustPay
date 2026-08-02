import 'package:hive_flutter/hive_flutter.dart';

import '../../../domain/entities/sync_status.dart';
import '../../models/category_model.dart';

abstract class CategoryLocalDataSource {
  Future<List<CategoryModel>> getCategories({bool includeDeleted = false});
  Future<void> saveCategory(CategoryModel category);
  Future<void> saveCategories(List<CategoryModel> categories);
  Future<CategoryModel?> getCategoryByLocalId(String localId);
  Future<List<CategoryModel>> getPendingCategories();
  Future<void> deleteCategory(String localId);
  Future<void> clearAndReplace(List<CategoryModel> categories);
}

class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  static const String boxName = 'categories_box';

  Future<Box<dynamic>> _openBox() {
    return Hive.openBox<dynamic>(boxName);
  }

  CategoryModel _fromStoredValue(dynamic value) {
    return CategoryModel.fromJson(Map<String, dynamic>.from(value as Map));
  }

  @override
  Future<List<CategoryModel>> getCategories({
    bool includeDeleted = false,
  }) async {
    final box = await _openBox();
    final items = box.values.map(_fromStoredValue).where((category) {
      if (includeDeleted) return true;
      return !category.isDeleted &&
          category.syncStatus != SyncStatus.pendingDelete;
    }).toList();
    items.sort((a, b) {
      final typeCompare = a.type.index.compareTo(b.type.index);
      if (typeCompare != 0) return typeCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return items;
  }

  @override
  Future<void> saveCategory(CategoryModel category) async {
    final box = await _openBox();
    await box.put(category.id, category.toJsonForStorage());
  }

  @override
  Future<void> saveCategories(List<CategoryModel> categories) async {
    final box = await _openBox();
    await box.putAll({
      for (final category in categories)
        category.id: category.toJsonForStorage(),
    });
  }

  @override
  Future<CategoryModel?> getCategoryByLocalId(String localId) async {
    final box = await _openBox();
    final raw = box.get(localId);
    if (raw == null) return null;
    return _fromStoredValue(raw);
  }

  @override
  Future<List<CategoryModel>> getPendingCategories() async {
    final categories = await getCategories(includeDeleted: true);
    return categories.where((category) {
      switch (category.syncStatus) {
        case SyncStatus.pendingCreate:
        case SyncStatus.pendingUpdate:
        case SyncStatus.pendingDelete:
        case SyncStatus.error:
        case SyncStatus.conflict:
          return true;
        case SyncStatus.synced:
        case SyncStatus.syncing:
          return false;
      }
    }).toList();
  }

  @override
  Future<void> deleteCategory(String localId) async {
    final box = await _openBox();
    await box.delete(localId);
  }

  @override
  Future<void> clearAndReplace(List<CategoryModel> categories) async {
    final box = await _openBox();
    await box.clear();
    await saveCategories(categories);
  }
}
