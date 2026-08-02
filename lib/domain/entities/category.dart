import 'package:equatable/equatable.dart';
import 'sync_status.dart';

enum CategoryType { income, expense }

class Category extends Equatable {
  final String id;
  final String name;
  final CategoryType type;
  final String color;
  final String icon;
  final bool isDefault;
  final String? serverId;
  final SyncStatus syncStatus;
  final bool isDeleted;
  final DateTime? lastModifiedAt;
  final DateTime? lastSyncedAt;
  final String? syncError;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.icon,
    required this.isDefault,
    this.serverId,
    this.syncStatus = SyncStatus.synced,
    this.isDeleted = false,
    this.lastModifiedAt,
    this.lastSyncedAt,
    this.syncError,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        color,
        icon,
        isDefault,
        serverId,
        syncStatus,
        isDeleted,
        lastModifiedAt,
        lastSyncedAt,
        syncError,
      ];
}
