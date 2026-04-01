import '../entities/account.dart';

abstract class AccountRepository {
  Future<List<Account>> getAccounts();
  Future<Account> getAccountDetails(String id);
}
