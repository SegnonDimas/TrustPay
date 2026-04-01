import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/pages/dashboard/dashboard_page.dart';
import '../../presentation/pages/onboarding/onboarding_page.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/signup_page.dart';
import '../../presentation/pages/main_shell.dart';
import '../../presentation/pages/qr_scanner/qr_scanner_page.dart';
import '../../presentation/pages/qr_scanner/generate_qr_page.dart';
import '../../presentation/pages/transactions/add_transaction_page.dart';
import '../../presentation/pages/statistics/statistics_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../constants/app_routes.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    initialLocation: AppRoutes.splash,
    navigatorKey: _rootNavigatorKey,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: '/add-transaction',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddTransactionPage(),
      ),
      GoRoute(
        path: '/generate-qr',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const GenerateQrPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.accounts,
            builder: (context, state) => const PlaceholderPage(title: 'Mes Comptes'),
          ),
          GoRoute(
            path: AppRoutes.qrScanner,
            builder: (context, state) => const QrScannerPage(),
          ),
          GoRoute(
            path: '/stats',
            builder: (context, state) => const StatisticsPage(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
  );
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Écran $title en cours de développement')),
    );
  }
}
