class ApiConfig {
  static const String baseUrl = 'https://finetrack-22e5.onrender.com';
  static const String apiPrefix = '/api';

  // Auth
  static const String login = '$apiPrefix/auth/login/';
  static const String register = '$apiPrefix/auth/register/';
  static const String refresh = '$apiPrefix/auth/refresh/';
  static const String profile = '$apiPrefix/auth/profile/';

  // Core
  static const String accounts = '$apiPrefix/accounts/';
  static const String mobileMoneyWallets =
      '$apiPrefix/accounts/mobile-money-wallets/';
  static const String transactions = '$apiPrefix/transactions/';
  static const String categories = '$apiPrefix/categories/';

  // Statistics
  static const String statisticsSummary = '$apiPrefix/statistics/summary/';
  static const String statisticsByCategory = '$apiPrefix/statistics/by-category/';
  static const String statisticsTrends = '$apiPrefix/statistics/trends/';
}
