import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/sync/app_sync_status.dart';
import '../../data/sync/app_sync_status_service.dart';
import '../../injection_container.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final statusService = sl<AppSyncStatusService>();

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              if (isDesktop) _buildNavigationRail(context),
              Expanded(child: child),
            ],
          ),
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: StreamBuilder<AppSyncStatus>(
                stream: statusService.stream,
                initialData: statusService.currentStatus,
                builder: (context, snapshot) {
                  final status = snapshot.data ?? AppSyncStatus.idle;
                  if (status == AppSyncStatus.idle) {
                    return const SizedBox.shrink();
                  }
                  return _buildSyncBadge(status);
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop ? null : _buildBottomNavigationBar(context),
    );
  }

  Widget _buildSyncBadge(AppSyncStatus status) {
    final (label, color) = switch (status) {
      AppSyncStatus.syncing => ('Synchronisation...', Colors.orange),
      AppSyncStatus.synced => ('Synchronisé', Colors.green),
      AppSyncStatus.offline => ('Hors ligne', Colors.grey),
      AppSyncStatus.error => ('Erreur sync', AppColors.error),
      AppSyncStatus.idle => ('', Colors.transparent),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int selectedIndex = _getSelectedIndex(location);

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => _onItemTapped(index, context),
      labelType: NavigationRailLabelType.all,
      leading: const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 32),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Tableau'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.account_balance_outlined),
          selectedIcon: Icon(Icons.account_balance),
          label: Text('Comptes'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.qr_code_scanner),
          selectedIcon: Icon(Icons.qr_code_scanner),
          label: Text('Payer'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: Text('Stats'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Profil'),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int selectedIndex = _getSelectedIndex(location);

    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) => _onItemTapped(index, context),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Tableau'),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_outlined), activeIcon: Icon(Icons.account_balance), label: 'Comptes'),
        BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Payer'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Stats'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
      ],
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/accounts')) return 1;
    if (location.startsWith('/qr-scanner')) return 2;
    if (location.startsWith('/stats')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/dashboard'); break;
      case 1: context.go('/accounts'); break;
      case 2: context.go('/qr-scanner'); break;
      case 3: context.go('/stats'); break;
      case 4: context.go('/profile'); break;
    }
  }
}
