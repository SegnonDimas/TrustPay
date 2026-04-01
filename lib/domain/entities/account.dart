import 'package:equatable/equatable.dart';

enum AccountType { cash, bank, mobileMoney }

class Account extends Equatable {
  final String id;
  final String name;
  final double balance;
  final AccountType type;
  final String? iconPath;
  final String? accountNumber;

  const Account({
    required this.id,
    required this.name,
    required this.balance,
    required this.type,
    this.iconPath,
    this.accountNumber,
  });

  @override
  List<Object?> get props => [id, name, balance, type, iconPath, accountNumber];
}
