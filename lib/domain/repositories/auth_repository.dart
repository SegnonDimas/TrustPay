import '../entities/user.dart';

abstract class AuthRepository {
  Future<void> register({
    required String email,
    required String password,
    required String userType,
  });

  Future<void> login({
    required String identifier,
    required String password,
  });

  Future<User> getProfile();
  Future<User?> getCachedProfile();
  Future<void> logout();
  Future<bool> hasSession();
}
