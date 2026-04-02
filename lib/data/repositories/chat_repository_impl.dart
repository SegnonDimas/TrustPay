import '../../domain/entities/chat_response.dart';
import '../../domain/entities/funding_source.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/remote/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ChatResponse> askFunding({
    required String question,
    int topK = 5,
    String? country,
    String? language,
    String? preferredLanguage,
  }) {
    return remoteDataSource.askFunding(
      question: question,
      topK: topK,
      country: country,
      language: language,
      preferredLanguage: preferredLanguage,
    );
  }

  @override
  Future<List<FundingSource>> getFundingSources() {
    return remoteDataSource.getFundingSources();
  }
}
