import '../../domain/entities/category.dart';
import '../../domain/entities/sync_status.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.type,
    required super.color,
    required super.icon,
    required super.isDefault,
    super.serverId,
    super.syncStatus,
    super.isDeleted,
    super.lastModifiedAt,
    super.lastSyncedAt,
    super.syncError,
  });

  static CategoryType _mapType(String? value) {
    return (value ?? '').toLowerCase().contains('income')
        ? CategoryType.income
        : CategoryType.expense;
  }

  static String _toApiType(CategoryType type) {
    return type == CategoryType.income ? 'income' : 'expense';
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString() ?? '';
    return CategoryModel(
      id: (json['local_id'] ?? rawId).toString(),
      name: (json['name'] as String?) ?? '',
      type: _mapType(json['category_type'] as String?),
      color: (json['color'] as String?) ?? '#2E7DFF',
      icon: (json['icon'] as String?) ?? 'category',
      isDefault: (json['is_default'] as bool?) ?? false,
      serverId: json['server_id']?.toString() ?? (rawId.isEmpty ? null : rawId),
      syncStatus: SyncStatusX.fromStorageValue(json['sync_status']?.toString()),
      isDeleted: (json['is_deleted'] as bool?) ?? false,
      lastModifiedAt: DateTime.tryParse(
        json['last_modified_at']?.toString() ?? '',
      ),
      lastSyncedAt: DateTime.tryParse(
        json['last_synced_at']?.toString() ?? '',
      ),
      syncError: json['sync_error']?.toString(),
    );
  }

  factory CategoryModel.fromRemoteJson(Map<String, dynamic> json) {
    final withSync = Map<String, dynamic>.from(json)
      ..['local_id'] = json['id']?.toString()
      ..['server_id'] = json['id']?.toString()
      ..['sync_status'] = SyncStatus.synced.storageValue
      ..['is_deleted'] = false
      ..['last_modified_at'] =
          (json['updated_at'] ?? json['created_at'])?.toString()
      ..['last_synced_at'] = DateTime.now().toIso8601String()
      ..['sync_error'] = null;
    return CategoryModel.fromJson(withSync);
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    CategoryType? type,
    String? color,
    String? icon,
    bool? isDefault,
    String? serverId,
    SyncStatus? syncStatus,
    bool? isDeleted,
    DateTime? lastModifiedAt,
    DateTime? lastSyncedAt,
    String? syncError,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      serverId: serverId ?? this.serverId,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncError: syncError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category_type': _toApiType(type),
      'color': color,
      'icon': icon,
      'is_default': isDefault,
      'server_id': serverId,
      'sync_status': syncStatus.storageValue,
      'is_deleted': isDeleted,
      'last_modified_at': lastModifiedAt?.toIso8601String(),
      'last_synced_at': lastSyncedAt?.toIso8601String(),
      'sync_error': syncError,
    };
  }

  Map<String, dynamic> toBulkSyncJson() {
    final payload = <String, dynamic>{
      'client_id': id,
      'local_id': id,
      'name': name,
      'category_type': _toApiType(type),
      'color': color,
      'icon': icon,
      'is_default': isDefault,
    };
    if (serverId != null && serverId!.isNotEmpty) {
      payload['id'] = int.tryParse(serverId!);
    }
    if (lastSyncedAt != null) {
      payload['client_updated_at'] = lastSyncedAt!.toIso8601String();
    }
    return payload;
  }

  Map<String, dynamic> toJsonForStorage() {
    return {
      'id': id,
      'name': name,
      'category_type': _toApiType(type),
      'color': color,
      'icon': icon,
      'is_default': isDefault,
    };
  }
}
