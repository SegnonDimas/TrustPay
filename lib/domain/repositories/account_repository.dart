import '../entities/account.dart';

abstract class AccountRepository {
  Future<List<Account>> getAccounts();
  Future<Account> getAccountDetails(String id);
  Future<Account> createAccount(Account account);
  Future<Account> createMobileMoneyWallet({
    required String provider,
    required String phoneNumber,
  });
  Future<void> updateAccount(Account account);
  Future<void> deleteAccount(String id);
}
