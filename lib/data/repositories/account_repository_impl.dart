import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/remote/account_remote_datasource.dart';
import '../models/account_model.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource remoteDataSource;

  AccountRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Account>> getAccounts() {
    return remoteDataSource.getAccounts();
  }

  @override
  Future<Account> getAccountDetails(String id) {
    return remoteDataSource.getAccount(id);
  }

  @override
  Future<Account> createAccount(Account account) {
    return remoteDataSource.createAccount(
      AccountModel(
        id: account.id,
        name: account.name,
        balance: account.balance,
        currency: account.currency,
        type: account.type,
        provider: account.provider,
        iconPath: account.iconPath,
        accountNumber: account.accountNumber,
      ),
    );
  }

  @override
  Future<Account> createMobileMoneyWallet({
    required String provider,
    required String phoneNumber,
  }) {
    return remoteDataSource.createMobileMoneyWallet(
      provider: provider,
      phoneNumber: phoneNumber,
    );
  }

  @override
  Future<void> updateAccount(Account account) {
    return remoteDataSource.updateAccount(
      AccountModel(
        id: account.id,
        name: account.name,
        balance: account.balance,
        currency: account.currency,
        type: account.type,
        provider: account.provider,
        iconPath: account.iconPath,
        accountNumber: account.accountNumber,
      ),
    );
  }

  @override
  Future<void> deleteAccount(String id) {
    return remoteDataSource.deleteAccount(id);
  }
}
