import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/remote/category_remote_datasource.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;

  CategoryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Category>> getCategories() {
    return remoteDataSource.getCategories();
  }

  @override
  Future<Category> createCategory({
    required String name,
    required CategoryType type,
    String color = '#2E7DFF',
    String icon = 'category',
  }) {
    return remoteDataSource.createCategory(
      CategoryModel(
        id: '',
        name: name,
        type: type,
        color: color,
        icon: icon,
        isDefault: false,
      ),
    );
  }

  @override
  Future<void> deleteCategory(String id) {
    return remoteDataSource.deleteCategory(id);
  }
}
