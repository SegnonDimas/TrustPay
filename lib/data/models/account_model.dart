import '../../domain/entities/account.dart';

class AccountModel extends Account {
  const AccountModel({
    required super.id,
    required super.name,
    required super.balance,
    required super.currency,
    required super.type,
    super.provider,
    super.iconPath,
    super.accountNumber,
  });

  static AccountType _mapAccountType(String? value) {
    switch (value) {
      case 'cash':
        return AccountType.cash;
      case 'bank':
        return AccountType.bank;
      case 'mobile_money':
      case 'mobileMoney':
        return AccountType.mobileMoney;
      default:
        return AccountType.cash;
    }
  }

  static String _accountTypeToApi(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return 'cash';
      case AccountType.bank:
        return 'bank';
      case AccountType.mobileMoney:
        return 'mobile_money';
    }
  }

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    final rawBalance = json['current_balance'] ?? json['balance'];
    return AccountModel(
      id: json['id'].toString(),
      name: (json['name'] as String?) ?? '',
      balance: double.tryParse(rawBalance.toString()) ?? 0,
      currency: (json['currency'] as String?) ?? 'XOF',
      type: _mapAccountType((json['account_type'] ?? json['type']) as String?),
      provider: json['provider'] as String?,
      iconPath: (json['icon'] ?? json['iconPath']) as String?,
      accountNumber: (json['phone_number'] ?? json['accountNumber']) as String?,
    );
  }

  AccountModel copyWith({
    String? provider,
    String? accountNumber,
  }) {
    return AccountModel(
      id: id,
      name: name,
      balance: balance,
      currency: currency,
      type: type,
      provider: provider ?? this.provider,
      iconPath: iconPath,
      accountNumber: accountNumber ?? this.accountNumber,
    );
  }

  Map<String, dynamic> toJson() {
    final resolvedIcon = (iconPath == null || iconPath!.trim().isEmpty)
        ? 'wallet'
        : iconPath!.trim();

    return {
      'name': name,
      'account_type': _accountTypeToApi(type),
      'initial_balance': balance,
      'current_balance': balance,
      'currency': currency,
      'color': '#2E7DFF',
      'icon': resolvedIcon,
      'is_active': true,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final resolvedIcon = (iconPath == null || iconPath!.trim().isEmpty)
        ? 'wallet'
        : iconPath!.trim();

    return {
      'name': name,
      'account_type': _accountTypeToApi(type),
      'current_balance': balance,
      'currency': currency,
      'color': '#2E7DFF',
      'icon': resolvedIcon,
      'is_active': true,
    };
  }
}
