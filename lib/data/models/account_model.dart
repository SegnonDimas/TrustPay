import '../../domain/entities/account.dart';

class AccountModel extends Account {
  const AccountModel({
    required super.id,
    required super.name,
    required super.balance,
    required super.type,
    super.iconPath,
    super.accountNumber,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'],
      name: json['name'],
      balance: (json['balance'] as num).toDouble(),
      type: AccountType.values.firstWhere((e) => e.toString() == 'AccountType.${json['type']}'),
      iconPath: json['iconPath'],
      accountNumber: json['accountNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'type': type.toString().split('.').last,
      'iconPath': iconPath,
      'accountNumber': accountNumber,
    };
  }
}
