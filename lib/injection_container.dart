import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'core/network/dio_client.dart';
import 'data/datasources/local/transaction_local_datasource.dart';
import 'data/repositories/transaction_repository_impl.dart';
import 'domain/repositories/transaction_repository.dart';
import 'presentation/bloc/home/home_bloc.dart';
import 'presentation/bloc/transaction/transaction_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // BLoCs
  sl.registerFactory(() => HomeBloc(transactionRepository: sl()));
  sl.registerFactory(() => TransactionBloc(transactionRepository: sl()));

  // Repositories
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<TransactionLocalDataSource>(
    () => TransactionLocalDataSourceImpl(),
  );

  // Core
  sl.registerLazySingleton(() => DioClient(Dio()));
}
