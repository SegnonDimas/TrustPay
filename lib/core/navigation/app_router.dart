import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../injection_container.dart';
import '../../presentation/pages/dashboard/dashboard_page.dart';
import '../../presentation/pages/accounts/accounts_page.dart';
import '../../presentation/pages/onboarding/onboarding_page.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/signup_page.dart';
import '../../presentation/pages/main_shell.dart';
import '../../presentation/pages/qr_scanner/qr_scanner_page.dart';
import '../../presentation/pages/qr_scanner/generate_qr_page.dart';
import '../../presentation/pages/transactions/add_transaction_page.dart';
import '../../presentation/pages/transactions/transactions_history_page.dart';
import '../../presentation/pages/categories/categories_page.dart';
import '../../presentation/pages/statistics/statistics_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/pages/chat/chat_page.dart';
import '../../presentation/bloc/chat/chat_bloc.dart';
import '../../presentation/bloc/transaction/transaction_bloc.dart';
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
        builder: (context, state) => BlocProvider(
          create: (_) => sl<TransactionBloc>(),
          child: const AddTransactionPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.transactions,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TransactionsHistoryPage(),
      ),
      GoRoute(
        path: '/categories',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CategoriesPage(),
      ),
      GoRoute(
        path: '/generate-qr',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const GenerateQrPage(),
      ),
      GoRoute(
        path: AppRoutes.fundingChat,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<ChatBloc>(),
          child: const ChatPage(),
        ),
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
            builder: (context, state) => const AccountsPage(),
          ),
          GoRoute(
            path: AppRoutes.qrScanner,
            builder: (context, state) => const QrScannerPage(),
          ),
          GoRoute(
            path: AppRoutes.stats,
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
