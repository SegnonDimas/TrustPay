import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'core/network/dio_client.dart';
import 'data/datasources/local/auth_local_datasource.dart';
import 'data/datasources/local/transaction_local_datasource.dart';
import 'data/datasources/remote/account_remote_datasource.dart';
import 'data/datasources/remote/auth_remote_datasource.dart';
import 'data/datasources/remote/category_remote_datasource.dart';
import 'data/datasources/remote/chat_remote_datasource.dart';
import 'data/datasources/remote/statistics_remote_datasource.dart';
import 'data/datasources/remote/transaction_remote_datasource.dart';
import 'data/repositories/account_repository_impl.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/category_repository_impl.dart';
import 'data/repositories/chat_repository_impl.dart';
import 'data/repositories/statistics_repository_impl.dart';
import 'data/repositories/transaction_repository_impl.dart';
import 'domain/repositories/account_repository.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/category_repository.dart';
import 'domain/repositories/chat_repository.dart';
import 'domain/repositories/statistics_repository.dart';
import 'domain/repositories/transaction_repository.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/chat/chat_bloc.dart';
import 'presentation/bloc/home/home_bloc.dart';
import 'presentation/bloc/statistics/statistics_bloc.dart';
import 'presentation/bloc/transaction/transaction_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // BLoCs
  sl.registerFactory(
    () => HomeBloc(
      transactionRepository: sl(),
      accountRepository: sl(),
      statisticsRepository: sl(),
    ),
  );
  sl.registerFactory(() => TransactionBloc(transactionRepository: sl()));
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  sl.registerFactory(() => StatisticsBloc(statisticsRepository: sl()));
  sl.registerFactory(() => ChatBloc(chatRepository: sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<AccountRepository>(
    () => AccountRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<StatisticsRepository>(
    () => StatisticsRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<TransactionLocalDataSource>(
    () => TransactionLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AccountRemoteDataSource>(
    () => AccountRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<CategoryRemoteDataSource>(
    () => CategoryRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<TransactionRemoteDataSource>(
    () => TransactionRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<StatisticsRemoteDataSource>(
    () => StatisticsRemoteDataSourceImpl(sl()),
  );

  // Core
  sl.registerLazySingleton(() => DioClient(Dio(), sl()));
  sl.registerLazySingleton<Dio>(() => sl<DioClient>().dio);
}
