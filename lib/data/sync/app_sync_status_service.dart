import 'dart:async';

import 'app_sync_status.dart';

class AppSyncStatusService {
  final _controller = StreamController<AppSyncStatus>.broadcast();
  AppSyncStatus _currentStatus = AppSyncStatus.idle;

  Stream<AppSyncStatus> get stream => _controller.stream;
  AppSyncStatus get currentStatus => _currentStatus;

  void setStatus(AppSyncStatus status) {
    if (_currentStatus == status) return;
    _currentStatus = status;
    _controller.add(status);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
