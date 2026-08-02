enum SyncStatus {
  synced,
  pendingCreate,
  pendingUpdate,
  pendingDelete,
  syncing,
  conflict,
  error,
}

extension SyncStatusX on SyncStatus {
  String get storageValue {
    switch (this) {
      case SyncStatus.synced:
        return 'synced';
      case SyncStatus.pendingCreate:
        return 'pendingCreate';
      case SyncStatus.pendingUpdate:
        return 'pendingUpdate';
      case SyncStatus.pendingDelete:
        return 'pendingDelete';
      case SyncStatus.syncing:
        return 'syncing';
      case SyncStatus.conflict:
        return 'conflict';
      case SyncStatus.error:
        return 'error';
    }
  }

  static SyncStatus fromStorageValue(String? value) {
    switch (value) {
      case 'pendingCreate':
        return SyncStatus.pendingCreate;
      case 'pendingUpdate':
        return SyncStatus.pendingUpdate;
      case 'pendingDelete':
        return SyncStatus.pendingDelete;
      case 'syncing':
        return SyncStatus.syncing;
      case 'conflict':
        return SyncStatus.conflict;
      case 'error':
        return SyncStatus.error;
      case 'synced':
      default:
        return SyncStatus.synced;
    }
  }
}
