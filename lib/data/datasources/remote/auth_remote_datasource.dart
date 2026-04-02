import 'package:dio/dio.dart';

import '../../../config/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, String>> login({
    required String identifier,
    required String password,
  });

  Future<void> register({
    required String email,
    required String password,
    required String userType,
  });

  Future<UserModel> getProfile();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, String>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final normalized = identifier.trim();
      final isEmail = normalized.contains('@');
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConfig.login,
        data: {
          'identifier': normalized,
          if (isEmail) 'email': normalized else 'phone_number': normalized,
          'password': password,
        },
      );

      final data = response.data ?? <String, dynamic>{};
      return {
        'access': (data['access'] as String?) ?? '',
        'refresh': (data['refresh'] as String?) ?? '',
      };
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String userType,
  }) async {
    try {
      await _dio.post<void>(
        ApiConfig.register,
        data: {
          'email': email.trim(),
          'password': password,
          'password_confirm': password,
          'user_type': userType,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiConfig.profile);
      final data = response.data ?? <String, dynamic>{};
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
