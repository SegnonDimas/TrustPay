class ApiConfig {
  static const String baseUrl = 'https://finetrack-22e5.onrender.com';
  static const String apiPrefix = '/api';
  static const String openRouterBaseUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String openRouterApiKey =
      String.fromEnvironment('OPENROUTER_API_KEY');

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

  // Accounting
  static const String accountingPeriod = '$apiPrefix/accounting/period/';
  static const String accountingBilans = '$apiPrefix/accounting/bilans/';
  static const String accountingKpis = '$apiPrefix/accounting/kpis/';
  static const String accountingExportCsv = '$apiPrefix/accounting/export/csv/';

  // Export
  static const String exportCsv = '$apiPrefix/export/csv/';
  static const String exportJson = '$apiPrefix/export/json/';

  // Funding RAG
  static const String fundingAsk = '$apiPrefix/funding/ask/';
  static const String fundingSources = '$apiPrefix/funding/sources/';
}
