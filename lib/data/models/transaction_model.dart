import '../../domain/entities/transaction.dart';
import '../../domain/entities/sync_status.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.title,
    required super.amount,
    required super.date,
    required super.type,
    required super.category,
    super.categoryId,
    super.accountId,
    super.toAccountId,
    super.description,
    super.serverId,
    super.syncStatus,
    super.isDeleted,
    super.lastModifiedAt,
    super.lastSyncedAt,
    super.syncError,
  });

  static TransactionType _mapTransactionType(String? value) {
    switch (value) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      case 'transfer':
        return TransactionType.transfer;
      default:
        return TransactionType.expense;
    }
  }

  static TransactionCategory _mapCategory(String? value, TransactionType type) {
    if (value == null || value.isEmpty) {
      return type == TransactionType.income
          ? TransactionCategory.salary
          : TransactionCategory.other;
    }
    final normalized = value.toLowerCase();
    if (normalized.contains('food') || normalized.contains('alimentation')) {
      return TransactionCategory.food;
    }
    if (normalized.contains('transport')) return TransactionCategory.transport;
    if (normalized.contains('health')) return TransactionCategory.health;
    if (normalized.contains('education')) return TransactionCategory.education;
    if (normalized.contains('business')) return TransactionCategory.business;
    if (normalized.contains('salary') || normalized.contains('revenu')) {
      return TransactionCategory.salary;
    }
    if (normalized.contains('entertain')) {
      return TransactionCategory.entertainment;
    }
    if (normalized.contains('shopping')) return TransactionCategory.shopping;
    if (normalized.contains('utilit')) return TransactionCategory.utilities;
    return type == TransactionType.income
        ? TransactionCategory.salary
        : TransactionCategory.other;
  }

  static String _typeToApi(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return 'income';
      case TransactionType.expense:
        return 'expense';
      case TransactionType.transfer:
        return 'transfer';
    }
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString() ?? '';
    final syncStatus = SyncStatusX.fromStorageValue(
      json['sync_status']?.toString(),
    );
    final lastModifiedAt = json['last_modified_at']?.toString();
    final lastSyncedAt = json['last_synced_at']?.toString();

    final apiType = (json['transaction_type'] ?? json['type']) as String?;
    final type = _mapTransactionType(apiType);
    final note = (json['note'] ?? json['title']) as String?;

    return TransactionModel(
      id: (json['local_id'] ?? rawId).toString(),
      title: (note == null || note.isEmpty)
          ? (type == TransactionType.income ? 'Revenu' : 'Transaction')
          : note,
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      date: DateTime.parse(json['date']),
      type: type,
      category: _mapCategory(
        json['category_name']?.toString(),
        type,
      ),
      categoryId: json['category']?.toString(),
      accountId: (json['account'] ?? json['accountId'])?.toString(),
      toAccountId: json['to_account']?.toString(),
      description: json['description'] as String?,
      serverId: json['server_id']?.toString() ?? (rawId.isEmpty ? null : rawId),
      syncStatus: syncStatus,
      isDeleted: (json['is_deleted'] as bool?) ?? false,
      lastModifiedAt: lastModifiedAt == null || lastModifiedAt.isEmpty
          ? null
          : DateTime.tryParse(lastModifiedAt),
      lastSyncedAt: lastSyncedAt == null || lastSyncedAt.isEmpty
          ? null
          : DateTime.tryParse(lastSyncedAt),
      syncError: json['sync_error']?.toString(),
    );
  }

  factory TransactionModel.fromRemoteJson(Map<String, dynamic> json) {
    final withSync = Map<String, dynamic>.from(json)
      ..['local_id'] = json['id']?.toString()
      ..['server_id'] = json['id']?.toString()
      ..['sync_status'] = SyncStatus.synced.storageValue
      ..['is_deleted'] = false
      ..['last_modified_at'] =
          (json['updated_at'] ?? json['date'])?.toString()
      ..['last_synced_at'] = DateTime.now().toIso8601String()
      ..['sync_error'] = null;
    return TransactionModel.fromJson(withSync);
  }

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    TransactionType? type,
    TransactionCategory? category,
    String? categoryId,
    String? accountId,
    String? toAccountId,
    String? description,
    String? serverId,
    SyncStatus? syncStatus,
    bool? isDeleted,
    DateTime? lastModifiedAt,
    DateTime? lastSyncedAt,
    String? syncError,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      description: description ?? this.description,
      serverId: serverId ?? this.serverId,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncError: syncError,
    );
  }

  Map<String, dynamic> toJson() {
    final note = description != null && description!.isNotEmpty
        ? '$title - $description'
        : title;

    return {
      'local_id': id,
      if (serverId != null && serverId!.isNotEmpty)
        'server_id': int.tryParse(serverId!),
      'transaction_type': _typeToApi(type),
      'amount': amount,
      'date': date.toIso8601String(),
      'account': accountId == null ? null : int.tryParse(accountId!),
      'to_account': toAccountId == null ? null : int.tryParse(toAccountId!),
      'category': categoryId == null ? null : int.tryParse(categoryId!),
      'note': note,
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
      'transaction_type': _typeToApi(type),
      'amount': amount,
      'date': date.toIso8601String(),
      'account': accountId == null ? null : int.tryParse(accountId!),
      'to_account': toAccountId == null ? null : int.tryParse(toAccountId!),
      'category': categoryId == null ? null : int.tryParse(categoryId!),
      'note': description != null && description!.isNotEmpty
          ? '$title - $description'
          : title,
    };

    if (serverId != null && serverId!.isNotEmpty) {
      payload['id'] = int.tryParse(serverId!);
    }
    if (lastSyncedAt != null) {
      payload['client_updated_at'] = lastSyncedAt!.toIso8601String();
    }
    return payload;
  }
}
