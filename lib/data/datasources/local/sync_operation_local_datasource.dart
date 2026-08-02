import 'package:hive_flutter/hive_flutter.dart';

import '../../models/sync_operation_model.dart';

abstract class SyncOperationLocalDataSource {
  Future<List<SyncOperationModel>> getOperations({
    String? entityType,
    String? entityLocalId,
  });
  Future<void> putOperation(SyncOperationModel operation);
  Future<void> deleteOperation(String operationId);
  Future<void> deleteOperationsForEntity(String entityType, String entityLocalId);
}

class SyncOperationLocalDataSourceImpl implements SyncOperationLocalDataSource {
  static const String boxName = 'sync_operations_box';

  Future<Box<dynamic>> _openBox() {
    return Hive.openBox<dynamic>(boxName);
  }

  SyncOperationModel _fromStoredValue(dynamic value) {
    return SyncOperationModel.fromJson(Map<String, dynamic>.from(value as Map));
  }

  @override
  Future<List<SyncOperationModel>> getOperations({
    String? entityType,
    String? entityLocalId,
  }) async {
    final box = await _openBox();
    final operations = box.values.map(_fromStoredValue).where((operation) {
      if (entityType != null && operation.entityType != entityType) {
        return false;
      }
      if (entityLocalId != null && operation.entityLocalId != entityLocalId) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return operations;
  }

  @override
  Future<void> putOperation(SyncOperationModel operation) async {
    final box = await _openBox();
    await box.put(operation.id, operation.toJson());
  }

  @override
  Future<void> deleteOperation(String operationId) async {
    final box = await _openBox();
    await box.delete(operationId);
  }

  @override
  Future<void> deleteOperationsForEntity(
    String entityType,
    String entityLocalId,
  ) async {
    final box = await _openBox();
    final keysToDelete = box.keys.where((key) {
      final raw = box.get(key);
      if (raw == null) return false;
      final operation = _fromStoredValue(raw);
      return operation.entityType == entityType &&
          operation.entityLocalId == entityLocalId;
    }).toList();
    await box.deleteAll(keysToDelete);
  }
}
