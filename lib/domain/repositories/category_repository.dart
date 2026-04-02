import '../entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getCategories();
  Future<Category> createCategory({
    required String name,
    required CategoryType type,
    String color = '#2E7DFF',
    String icon = 'category',
  });
  Future<void> deleteCategory(String id);
}
