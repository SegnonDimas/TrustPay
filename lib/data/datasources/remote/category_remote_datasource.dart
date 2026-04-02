import 'package:dio/dio.dart';

import '../../../config/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<CategoryModel> createCategory(CategoryModel category);
  Future<void> deleteCategory(String id);
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final Dio _dio;

  CategoryRemoteDataSourceImpl(this._dio);

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _dio.get<dynamic>(ApiConfig.categories);
      final data = response.data;
      final list = data is Map<String, dynamic> && data['results'] is List
          ? data['results'] as List<dynamic>
          : (data as List<dynamic>? ?? const []);
      return list
          .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<CategoryModel> createCategory(CategoryModel category) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConfig.categories,
        data: category.toJson(),
      );
      return CategoryModel.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await _dio.delete<void>('${ApiConfig.categories}$id/');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
