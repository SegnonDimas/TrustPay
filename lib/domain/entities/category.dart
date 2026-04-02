import 'package:equatable/equatable.dart';

enum CategoryType { income, expense }

class Category extends Equatable {
  final String id;
  final String name;
  final CategoryType type;
  final String color;
  final String icon;
  final bool isDefault;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.icon,
    required this.isDefault,
  });

  @override
  List<Object?> get props => [id, name, type, color, icon, isDefault];
}
