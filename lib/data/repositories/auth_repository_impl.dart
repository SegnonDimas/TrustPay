import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/network/api_exception.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<void> register({
    required String email,
    required String password,
    required String userType,
  }) {
    return remoteDataSource.register(
      email: email,
      password: password,
      userType: userType,
    );
  }

  @override
  Future<void> login({
    required String email,
    required String password,
  }) async {
    final tokens = await remoteDataSource.login(
      email: email,
      password: password,
    );
    final access = tokens['access'] ?? '';
    final refresh = tokens['refresh'] ?? '';
    if (access.isEmpty || refresh.isEmpty) {
      throw const ApiException('Réponse d’authentification invalide.');
    }
    await localDataSource.saveTokens(
      accessToken: access,
      refreshToken: refresh,
    );
  }

  @override
  Future<User> getProfile() {
    return remoteDataSource.getProfile();
  }

  @override
  Future<void> logout() {
    return localDataSource.clearTokens();
  }

  @override
  Future<bool> hasSession() async {
    final access = await localDataSource.getAccessToken();
    final refresh = await localDataSource.getRefreshToken();
    return (access?.isNotEmpty ?? false) && (refresh?.isNotEmpty ?? false);
  }
}
