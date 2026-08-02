import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../datasources/local/auth_local_datasource.dart';
import 'app_sync_status.dart';
import 'app_sync_status_service.dart';
import 'account_sync_service.dart';
import 'category_sync_service.dart';
import 'transaction_sync_service.dart';

class AppSyncCoordinator {
  final Connectivity connectivity;
  final AuthLocalDataSource authLocalDataSource;
  final AppSyncStatusService statusService;
  final CategorySyncService categorySyncService;
  final AccountSyncService accountSyncService;
  final TransactionSyncService transactionSyncService;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _started = false;
  bool _isSyncing = false;

  AppSyncCoordinator({
    required this.connectivity,
    required this.authLocalDataSource,
    required this.statusService,
    required this.categorySyncService,
    required this.accountSyncService,
    required this.transactionSyncService,
  });

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _subscription = connectivity.onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.none)) {
        statusService.setStatus(AppSyncStatus.offline);
      } else {
        unawaited(syncAll());
      }
    });
    await syncAll();
  }

  Future<void> syncAll() async {
    if (_isSyncing) return;
    final accessToken = await authLocalDataSource.getAccessToken();
    final refreshToken = await authLocalDataSource.getRefreshToken();
    if ((accessToken?.isEmpty ?? true) || (refreshToken?.isEmpty ?? true)) {
      statusService.setStatus(AppSyncStatus.idle);
      return;
    }
    if (!await categorySyncService.hasConnectivity()) {
      statusService.setStatus(AppSyncStatus.offline);
      return;
    }
    _isSyncing = true;
    statusService.setStatus(AppSyncStatus.syncing);
    try {
      await categorySyncService.syncPendingCategories();
      await accountSyncService.syncPendingAccounts();
      await transactionSyncService.syncPendingTransactions();
      statusService.setStatus(AppSyncStatus.synced);
    } catch (_) {
      statusService.setStatus(AppSyncStatus.error);
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _started = false;
  }
}
