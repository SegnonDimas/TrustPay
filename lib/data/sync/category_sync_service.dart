import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/sync_status.dart';
import '../datasources/local/category_local_datasource.dart';
import '../datasources/local/sync_operation_local_datasource.dart';
import '../datasources/remote/category_remote_datasource.dart';
import '../models/category_model.dart';
import '../models/sync_operation_model.dart';

class CategorySyncService {
  final CategoryLocalDataSource localDataSource;
  final SyncOperationLocalDataSource operationLocalDataSource;
  final CategoryRemoteDataSource remoteDataSource;
  final Connectivity connectivity;
  final Uuid uuid;
  bool _isSyncing = false;

  CategorySyncService({
    required this.localDataSource,
    required this.operationLocalDataSource,
    required this.remoteDataSource,
    required this.connectivity,
    Uuid? uuid,
  }) : uuid = uuid ?? const Uuid();

  Future<void> enqueueUpsert(CategoryModel category, {required String operationType}) async {
    await operationLocalDataSource.deleteOperationsForEntity('category', category.id);
    await operationLocalDataSource.putOperation(
      SyncOperationModel(
        id: uuid.v4(),
        entityType: 'category',
        entityLocalId: category.id,
        operationType: operationType,
        payload: category.toJsonForStorage(),
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> enqueueDelete(CategoryModel category) async {
    await operationLocalDataSource.deleteOperationsForEntity('category', category.id);
    await operationLocalDataSource.putOperation(
      SyncOperationModel(
        id: uuid.v4(),
        entityType: 'category',
        entityLocalId: category.id,
        operationType: 'delete',
        payload: category.toJsonForStorage(),
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<bool> hasConnectivity() async {
    final result = await connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<void> syncPendingCategories() async {
    if (_isSyncing) return;
    if (!await hasConnectivity()) return;
    _isSyncing = true;
    try {
      final operations = await operationLocalDataSource.getOperations(entityType: 'category');
      final upserts = <String, CategoryModel>{};
      final deletes = <SyncOperationModel>[];

      for (final operation in operations) {
        final category = await localDataSource.getCategoryByLocalId(operation.entityLocalId);
        if (operation.operationType == 'delete') {
          deletes.add(operation);
          continue;
        }
        if (category == null) {
          await operationLocalDataSource.deleteOperation(operation.id);
          continue;
        }
        upserts[category.id] = category.copyWith(syncStatus: SyncStatus.syncing, syncError: null);
      }

      if (upserts.isNotEmpty) {
        await localDataSource.saveCategories(upserts.values.toList());
        final results = await remoteDataSource.bulkSyncCategories(upserts.values.toList());
        for (final result in results) {
          final localId = result['local_id']?.toString() ?? result['client_id']?.toString();
          if (localId == null || localId.isEmpty) continue;
          final localCategory = await localDataSource.getCategoryByLocalId(localId);
          if (localCategory == null) continue;
          final status = result['status']?.toString() ?? 'error';
          if (status == 'created' || status == 'updated') {
            final payload = result['category'];
            final remoteCategory = payload is Map<String, dynamic>
                ? CategoryModel.fromRemoteJson(payload)
                : localCategory;
            await localDataSource.saveCategory(
              remoteCategory.copyWith(
                id: localCategory.id,
                serverId: remoteCategory.serverId ?? result['id']?.toString(),
                syncStatus: SyncStatus.synced,
                isDeleted: false,
                lastModifiedAt: localCategory.lastModifiedAt ?? DateTime.now().toUtc(),
                lastSyncedAt: DateTime.now().toUtc(),
                syncError: null,
              ),
            );
            await operationLocalDataSource.deleteOperationsForEntity('category', localId);
          } else {
            await localDataSource.saveCategory(
              localCategory.copyWith(
                syncStatus: status == 'conflict' ? SyncStatus.conflict : SyncStatus.error,
                syncError: _extractError(result),
              ),
            );
          }
        }
      }

      for (final operation in deletes) {
        final category = await localDataSource.getCategoryByLocalId(operation.entityLocalId);
        if (category == null) {
          await operationLocalDataSource.deleteOperation(operation.id);
          continue;
        }
        if (category.serverId == null || category.serverId!.isEmpty) {
          await localDataSource.deleteCategory(category.id);
          await operationLocalDataSource.deleteOperation(operation.id);
          continue;
        }
        try {
          await remoteDataSource.deleteCategory(category.serverId!);
          await localDataSource.deleteCategory(category.id);
          await operationLocalDataSource.deleteOperation(operation.id);
        } catch (error) {
          await localDataSource.saveCategory(
            category.copyWith(syncStatus: SyncStatus.error, syncError: error.toString()),
          );
        }
      }

      await refreshFromRemote();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> refreshFromRemote() async {
    if (!await hasConnectivity()) return;
    final remoteCategories = await remoteDataSource.getCategories();
    final existingCategories = await localDataSource.getCategories(includeDeleted: true);
    final pendingCategories = await localDataSource.getPendingCategories();
    final localIdByServerId = <String, String>{
      for (final category in existingCategories)
        if (category.serverId != null && category.serverId!.isNotEmpty)
          category.serverId!: category.id,
    };
    final merged = <String, CategoryModel>{
      for (final category in remoteCategories)
        (localIdByServerId[category.serverId ?? category.id] ?? category.id):
            category.copyWith(
          id: localIdByServerId[category.serverId ?? category.id] ?? category.id,
        ),
    };
    for (final pending in pendingCategories) {
      merged[pending.id] = pending;
    }
    await localDataSource.clearAndReplace(merged.values.toList());
  }

  String _extractError(Map<String, dynamic> result) {
    final errors = result['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) return value.first.toString();
        if (value != null) return value.toString();
      }
    }
    return 'Synchronization failed.';
  }
}
