import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'core/network/dio_client.dart';
import 'data/datasources/local/account_local_datasource.dart';
import 'data/datasources/local/auth_local_datasource.dart';
import 'data/datasources/local/category_local_datasource.dart';
import 'data/datasources/local/sync_operation_local_datasource.dart';
import 'data/datasources/local/sync_snapshot_local_datasource.dart';
import 'data/datasources/local/transaction_local_datasource.dart';
import 'data/datasources/remote/account_remote_datasource.dart';
import 'data/datasources/remote/accounting_remote_datasource.dart';
import 'data/datasources/remote/auth_remote_datasource.dart';
import 'data/datasources/remote/category_remote_datasource.dart';
import 'data/datasources/remote/chat_remote_datasource.dart';
import 'data/datasources/remote/export_remote_datasource.dart';
import 'data/datasources/remote/initial_sync_remote_datasource.dart';
import 'data/datasources/remote/statistics_remote_datasource.dart';
import 'data/datasources/remote/transaction_remote_datasource.dart';
import 'data/local/local_finance_analytics.dart';
import 'data/repositories/account_repository_impl.dart';
import 'data/repositories/accounting_repository_impl.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/category_repository_impl.dart';
import 'data/repositories/chat_repository_impl.dart';
import 'data/repositories/export_repository_impl.dart';
import 'data/repositories/statistics_repository_impl.dart';
import 'data/repositories/transaction_repository_impl.dart';
import 'data/sync/account_sync_service.dart';
import 'data/sync/app_sync_coordinator.dart';
import 'data/sync/app_sync_status_service.dart';
import 'data/sync/category_sync_service.dart';
import 'data/sync/initial_sync_service.dart';
import 'data/sync/transaction_sync_service.dart';
import 'domain/repositories/account_repository.dart';
import 'domain/repositories/accounting_repository.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/category_repository.dart';
import 'domain/repositories/chat_repository.dart';
import 'domain/repositories/export_repository.dart';
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
  sl.registerFactory(
    () => AuthBloc(
      authRepository: sl(),
      initialSyncService: sl(),
    ),
  );
  sl.registerFactory(
    () => StatisticsBloc(
      statisticsRepository: sl(),
      accountingRepository: sl(),
    ),
  );
  sl.registerFactory(() => ChatBloc(chatRepository: sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<AccountRepository>(
    () => AccountRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      syncService: sl(),
    ),
  );
  sl.registerLazySingleton<AccountingRepository>(
    () => AccountingRepositoryImpl(
      remoteDataSource: sl(),
      transactionLocalDataSource: sl(),
      analytics: sl(),
    ),
  );
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      syncService: sl(),
    ),
  );
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<ExportRepository>(
    () => ExportRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      syncService: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => InitialSyncService(
      remoteDataSource: sl(),
      authLocalDataSource: sl(),
      accountLocalDataSource: sl(),
      categoryLocalDataSource: sl(),
      transactionLocalDataSource: sl(),
      syncSnapshotLocalDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<StatisticsRepository>(
    () => StatisticsRepositoryImpl(
      remoteDataSource: sl(),
      transactionLocalDataSource: sl(),
      accountLocalDataSource: sl(),
      categoryLocalDataSource: sl(),
      analytics: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AccountLocalDataSource>(
    () => AccountLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<CategoryLocalDataSource>(
    () => CategoryLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<SyncOperationLocalDataSource>(
    () => SyncOperationLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<SyncSnapshotLocalDataSource>(
    () => SyncSnapshotLocalDataSourceImpl(),
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
  sl.registerLazySingleton<AccountingRemoteDataSource>(
    () => AccountingRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ExportRemoteDataSource>(
    () => ExportRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<InitialSyncRemoteDataSource>(
    () => InitialSyncRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton(
    () => Connectivity(),
  );

  sl.registerLazySingleton(() => const LocalFinanceAnalytics());
  sl.registerLazySingleton(() => AppSyncStatusService());

  sl.registerLazySingleton(
    () => CategorySyncService(
      localDataSource: sl(),
      operationLocalDataSource: sl(),
      remoteDataSource: sl(),
      connectivity: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => AccountSyncService(
      localDataSource: sl(),
      operationLocalDataSource: sl(),
      remoteDataSource: sl(),
      connectivity: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => TransactionSyncService(
      localDataSource: sl(),
      accountLocalDataSource: sl(),
      categoryLocalDataSource: sl(),
      operationLocalDataSource: sl(),
      remoteDataSource: sl(),
      connectivity: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => AppSyncCoordinator(
      connectivity: sl(),
      authLocalDataSource: sl(),
      statusService: sl(),
      categorySyncService: sl(),
      accountSyncService: sl(),
      transactionSyncService: sl(),
    ),
  );

  // Core
  sl.registerLazySingleton(() => DioClient(Dio(), sl()));
  sl.registerLazySingleton<Dio>(() => sl<DioClient>().dio);
}
