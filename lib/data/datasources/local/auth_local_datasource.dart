import 'package:hive_flutter/hive_flutter.dart';

import '../../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveUserProfile(UserModel user);
  Future<UserModel?> getUserProfile();
  Future<void> clearTokens();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String boxName = 'auth_box';
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userProfileKey = 'user_profile';

  Future<Box<dynamic>> _openBox() {
    return Hive.openBox<dynamic>(boxName);
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final box = await _openBox();
    await box.put(accessTokenKey, accessToken);
    await box.put(refreshTokenKey, refreshToken);
  }

  @override
  Future<String?> getAccessToken() async {
    final box = await _openBox();
    return box.get(accessTokenKey) as String?;
  }

  @override
  Future<String?> getRefreshToken() async {
    final box = await _openBox();
    return box.get(refreshTokenKey) as String?;
  }

  @override
  Future<void> saveUserProfile(UserModel user) async {
    final box = await _openBox();
    await box.put(userProfileKey, user.toJson());
  }

  @override
  Future<UserModel?> getUserProfile() async {
    final box = await _openBox();
    final raw = box.get(userProfileKey);
    if (raw == null) return null;
    return UserModel.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  @override
  Future<void> clearTokens() async {
    final box = await _openBox();
    await box.delete(accessTokenKey);
    await box.delete(refreshTokenKey);
    await box.delete(userProfileKey);
  }
}
