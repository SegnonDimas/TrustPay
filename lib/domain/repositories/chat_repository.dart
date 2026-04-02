import '../entities/chat_response.dart';
import '../entities/funding_source.dart';

abstract class ChatRepository {
  Future<ChatResponse> askFunding({
    required String question,
    int topK = 5,
    String? country,
    String? language,
  });

  Future<List<FundingSource>> getFundingSources();
}
