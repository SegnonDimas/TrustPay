import '../../domain/entities/account.dart';
import '../../domain/entities/sync_status.dart';

class AccountModel extends Account {
  const AccountModel({
    required super.id,
    required super.name,
    required super.balance,
    required super.currency,
    required super.type,
    super.provider,
    super.iconPath,
    super.accountNumber,
    super.serverId,
    super.syncStatus,
    super.isDeleted,
    super.lastModifiedAt,
    super.lastSyncedAt,
    super.syncError,
  });

  static AccountType _mapAccountType(String? value) {
    switch (value) {
      case 'cash':
        return AccountType.cash;
      case 'bank':
        return AccountType.bank;
      case 'mobile_money':
      case 'mobileMoney':
        return AccountType.mobileMoney;
      default:
        return AccountType.cash;
    }
  }

  static String _accountTypeToApi(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return 'cash';
      case AccountType.bank:
        return 'bank';
      case AccountType.mobileMoney:
        return 'mobile_money';
    }
  }

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    final rawBalance = json['current_balance'] ?? json['balance'];
    final rawId = json['id']?.toString() ?? '';
    return AccountModel(
      id: (json['local_id'] ?? rawId).toString(),
      name: (json['name'] as String?) ?? '',
      balance: double.tryParse(rawBalance.toString()) ?? 0,
      currency: (json['currency'] as String?) ?? 'XOF',
      type: _mapAccountType((json['account_type'] ?? json['type']) as String?),
      provider: json['provider'] as String?,
      iconPath: (json['icon'] ?? json['iconPath']) as String?,
      accountNumber: (json['phone_number'] ?? json['accountNumber']) as String?,
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

  factory AccountModel.fromRemoteJson(Map<String, dynamic> json) {
    final withSync = Map<String, dynamic>.from(json)
      ..['local_id'] = json['id']?.toString()
      ..['server_id'] = json['id']?.toString()
      ..['sync_status'] = SyncStatus.synced.storageValue
      ..['is_deleted'] = false
      ..['last_modified_at'] =
          (json['updated_at'] ?? json['created_at'])?.toString()
      ..['last_synced_at'] = DateTime.now().toIso8601String()
      ..['sync_error'] = null;
    return AccountModel.fromJson(withSync);
  }

  AccountModel copyWith({
    String? id,
    String? name,
    double? balance,
    String? currency,
    AccountType? type,
    String? provider,
    String? iconPath,
    String? accountNumber,
    String? serverId,
    SyncStatus? syncStatus,
    bool? isDeleted,
    DateTime? lastModifiedAt,
    DateTime? lastSyncedAt,
    String? syncError,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      provider: provider ?? this.provider,
      iconPath: iconPath ?? this.iconPath,
      accountNumber: accountNumber ?? this.accountNumber,
      serverId: serverId ?? this.serverId,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncError: syncError,
    );
  }

  Map<String, dynamic> toJson() {
    final resolvedIcon = (iconPath == null || iconPath!.trim().isEmpty)
        ? 'wallet'
        : iconPath!.trim();

    return {
      'name': name,
      'account_type': _accountTypeToApi(type),
      'initial_balance': balance,
      'current_balance': balance,
      'currency': currency,
      'color': '#2E7DFF',
      'icon': resolvedIcon,
      'is_active': true,
    };
  }

  Map<String, dynamic> toJsonForStorage() {
    return {
      'id': id,
      'name': name,
      'current_balance': balance,
      'currency': currency,
      'account_type': _accountTypeToApi(type),
      'provider': provider,
      'icon': iconPath,
      'phone_number': accountNumber,
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
      'account_type': _accountTypeToApi(type),
      'initial_balance': balance,
      'current_balance': balance,
      'currency': currency,
      'color': '#2E7DFF',
      'icon': (iconPath == null || iconPath!.trim().isEmpty)
          ? 'wallet'
          : iconPath!.trim(),
      'is_active': true,
    };
    if (serverId != null && serverId!.isNotEmpty) {
      payload['id'] = int.tryParse(serverId!);
    }
    if (lastSyncedAt != null) {
      payload['client_updated_at'] = lastSyncedAt!.toIso8601String();
    }
    return payload;
  }

  Map<String, dynamic> toUpdateJson() {
    final resolvedIcon = (iconPath == null || iconPath!.trim().isEmpty)
        ? 'wallet'
        : iconPath!.trim();

    return {
      'name': name,
      'account_type': _accountTypeToApi(type),
      'current_balance': balance,
      'currency': currency,
      'color': '#2E7DFF',
      'icon': resolvedIcon,
      'is_active': true,
    };
  }
}
