import 'package:equatable/equatable.dart';
import 'sync_status.dart';

enum AccountType { cash, bank, mobileMoney }

class Account extends Equatable {
  final String id;
  final String name;
  final double balance;
  final String currency;
  final AccountType type;
  final String? provider;
  final String? iconPath;
  final String? accountNumber;
  final String? serverId;
  final SyncStatus syncStatus;
  final bool isDeleted;
  final DateTime? lastModifiedAt;
  final DateTime? lastSyncedAt;
  final String? syncError;

  const Account({
    required this.id,
    required this.name,
    required this.balance,
    this.currency = 'XOF',
    required this.type,
    this.provider,
    this.iconPath,
    this.accountNumber,
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
        balance,
        currency,
        type,
        provider,
        iconPath,
        accountNumber,
        serverId,
        syncStatus,
        isDeleted,
        lastModifiedAt,
        lastSyncedAt,
        syncError,
      ];
}
