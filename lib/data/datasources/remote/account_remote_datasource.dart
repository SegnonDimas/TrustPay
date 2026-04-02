import 'package:dio/dio.dart';

import '../../../config/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/entities/account.dart';
import '../../models/account_model.dart';

abstract class AccountRemoteDataSource {
  Future<List<AccountModel>> getAccounts();
  Future<AccountModel> getAccount(String id);
  Future<AccountModel> createAccount(AccountModel account);
  Future<AccountModel> createMobileMoneyWallet({
    required String provider,
    required String phoneNumber,
  });
  Future<void> updateAccount(AccountModel account);
  Future<void> deleteAccount(String id);
}

class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  final Dio _dio;

  AccountRemoteDataSourceImpl(this._dio);

  Future<String?> _resolveWalletAccountId({
    required String provider,
    required String phoneNumber,
  }) async {
    final response = await _dio.get<dynamic>(ApiConfig.mobileMoneyWallets);
    final data = response.data;
    final walletList =
        data is Map<String, dynamic> && data['results'] is List
            ? data['results'] as List<dynamic>
            : (data as List<dynamic>? ?? const []);

    final normalizedProvider = provider.trim().toUpperCase();
    final normalizedPhone = phoneNumber.trim();

    for (final item in walletList) {
      final wallet = Map<String, dynamic>.from(item as Map);
      final walletProvider = wallet['provider']?.toString().trim().toUpperCase();
      final walletPhone = wallet['phone_number']?.toString().trim();
      if (walletProvider == normalizedProvider &&
          walletPhone == normalizedPhone) {
        final accountId = wallet['account_id']?.toString();
        if (accountId != null && accountId.isNotEmpty) return accountId;
      }
    }
    return null;
  }

  @override
  Future<List<AccountModel>> getAccounts() async {
    try {
      final response = await _dio.get<dynamic>(ApiConfig.accounts);
      final data = response.data;
      final list = data is Map<String, dynamic> && data['results'] is List
          ? data['results'] as List<dynamic>
          : (data as List<dynamic>? ?? const []);
      final accounts = list
          .map((e) => AccountModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      try {
        final walletResponse = await _dio.get<dynamic>(ApiConfig.mobileMoneyWallets);
        final walletData = walletResponse.data;
        final walletList =
            walletData is Map<String, dynamic> && walletData['results'] is List
                ? walletData['results'] as List<dynamic>
                : (walletData as List<dynamic>? ?? const []);

        final walletByAccountId = <String, Map<String, dynamic>>{};
        for (final item in walletList) {
          final wallet = Map<String, dynamic>.from(item as Map);
          final accountId = wallet['account_id']?.toString();
          if (accountId != null && accountId.isNotEmpty) {
            walletByAccountId[accountId] = wallet;
          }
        }

        return accounts.map((account) {
          if (account.type != AccountType.mobileMoney) return account;
          final wallet = walletByAccountId[account.id];
          if (wallet == null) return account;
          return account.copyWith(
            provider: wallet['provider']?.toString(),
            accountNumber: wallet['phone_number']?.toString(),
          );
        }).toList();
      } on DioException catch (walletError) {
        // Wallet endpoint is restricted for non-professional profiles.
        if (walletError.response?.statusCode == 403) {
          return accounts;
        }
        rethrow;
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<AccountModel> getAccount(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiConfig.accounts}$id/',
      );
      return AccountModel.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<AccountModel> createAccount(AccountModel account) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConfig.accounts,
        data: account.toJson(),
      );
      return AccountModel.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<AccountModel> createMobileMoneyWallet({
    required String provider,
    required String phoneNumber,
  }) async {
    try {
      final normalizedProvider = provider.trim().toUpperCase();
      final normalizedPhone = phoneNumber.trim();
      final walletResponse = await _dio.post<Map<String, dynamic>>(
        ApiConfig.mobileMoneyWallets,
        data: {
          'provider': normalizedProvider,
          'phone_number': normalizedPhone,
        },
      );
      final walletData = walletResponse.data ?? <String, dynamic>{};
      var accountId = walletData['account_id']?.toString();
      if (accountId == null || accountId.isEmpty) {
        accountId = await _resolveWalletAccountId(
          provider: normalizedProvider,
          phoneNumber: normalizedPhone,
        );
      }
      if (accountId == null || accountId.isEmpty) {
        throw const ApiException(
          'Wallet cree mais compte associe introuvable dans la reponse.',
        );
      }
      return getAccount(accountId);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> updateAccount(AccountModel account) async {
    try {
      await _dio.patch<void>(
        '${ApiConfig.accounts}${account.id}/',
        data: account.toUpdateJson(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    try {
      await _dio.delete<void>('${ApiConfig.accounts}$id/');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
