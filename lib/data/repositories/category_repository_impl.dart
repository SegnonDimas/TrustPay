import 'package:uuid/uuid.dart';

import '../../domain/entities/sync_status.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/local/category_local_datasource.dart';
import '../datasources/remote/category_remote_datasource.dart';
import '../models/category_model.dart';
import '../sync/category_sync_service.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;
  final CategoryLocalDataSource localDataSource;
  final CategorySyncService syncService;
  final Uuid _uuid = const Uuid();

  CategoryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.syncService,
  });

  @override
  Future<List<Category>> getCategories() async {
    final localCategories = await localDataSource.getCategories();
    if (localCategories.isNotEmpty) {
      syncService.syncPendingCategories();
      return localCategories;
    }
    try {
      final categories = await remoteDataSource.getCategories();
      await localDataSource.clearAndReplace(categories);
      return categories;
    } catch (_) {
      if (localCategories.isNotEmpty) return localCategories;
      rethrow;
    }
  }

  @override
  Future<Category> createCategory({
    required String name,
    required CategoryType type,
    String color = '#2E7DFF',
    String icon = 'category',
  }) async {
    final model = CategoryModel(
      id: _uuid.v4(),
      name: name,
      type: type,
      color: color,
      icon: icon,
      isDefault: false,
      syncStatus: SyncStatus.pendingCreate,
      isDeleted: false,
      lastModifiedAt: DateTime.now().toUtc(),
    );
    await localDataSource.saveCategory(model);
    await syncService.enqueueUpsert(model, operationType: 'create');
    await syncService.syncPendingCategories();
    return (await localDataSource.getCategoryByLocalId(model.id)) ?? model;
  }

  @override
  Future<void> deleteCategory(String id) async {
    final existing = await localDataSource.getCategoryByLocalId(id);
    if (existing == null) return;
    if (existing.serverId == null || existing.serverId!.isEmpty) {
      await localDataSource.deleteCategory(id);
      return;
    }
    final pendingDelete = existing.copyWith(
      isDeleted: true,
      syncStatus: SyncStatus.pendingDelete,
      lastModifiedAt: DateTime.now().toUtc(),
      syncError: null,
    );
    await localDataSource.saveCategory(pendingDelete);
    await syncService.enqueueDelete(pendingDelete);
    await syncService.syncPendingCategories();
  }
}
