import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.type,
    required super.color,
    required super.icon,
    required super.isDefault,
  });

  static CategoryType _mapType(String? value) {
    return (value ?? '').toLowerCase().contains('income')
        ? CategoryType.income
        : CategoryType.expense;
  }

  static String _toApiType(CategoryType type) {
    return type == CategoryType.income ? 'income' : 'expense';
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'].toString(),
      name: (json['name'] as String?) ?? '',
      type: _mapType(json['category_type'] as String?),
      color: (json['color'] as String?) ?? '#2E7DFF',
      icon: (json['icon'] as String?) ?? 'category',
      isDefault: (json['is_default'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category_type': _toApiType(type),
      'color': color,
      'icon': icon,
      'is_default': isDefault,
    };
  }
}
