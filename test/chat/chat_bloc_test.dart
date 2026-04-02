import 'package:flutter_test/flutter_test.dart';
import 'package:trustpay/domain/entities/chat_citation.dart';
import 'package:trustpay/domain/entities/chat_response.dart';
import 'package:trustpay/domain/entities/funding_source.dart';
import 'package:trustpay/domain/repositories/chat_repository.dart';
import 'package:trustpay/presentation/bloc/chat/chat_bloc.dart';
import 'package:trustpay/presentation/bloc/chat/chat_event.dart';

class _SuccessChatRepository implements ChatRepository {
  @override
  Future<ChatResponse> askFunding({
    required String question,
    int topK = 5,
    String? country,
    String? language,
    String? preferredLanguage,
  }) async {
    return const ChatResponse(
      answer: 'Reponse assistant',
      confidence: 0.8,
      citations: [
        ChatCitation(
          chunkId: 1,
          documentId: 10,
          documentTitle: 'Fonds PME',
          sourceUrl: '',
          score: 0.9,
          excerpt: 'extrait',
        ),
      ],
      limits: ['limit'],
      detectedLanguage: 'fr',
      modelUsed: 'openai/gpt-4o-mini',
      fallbackReason: 'preferred_language',
    );
  }

  @override
  Future<List<FundingSource>> getFundingSources() async {
    return const [
      FundingSource(
        id: 1,
        title: 'Source A',
        sourceUrl: '',
        sourceType: 'grant',
        language: 'fr',
        country: 'BJ',
        status: 'published',
        version: 1,
        publishedAt: null,
        chunkCount: 2,
        updatedAt: null,
      ),
    ];
  }
}

class _ErrorChatRepository implements ChatRepository {
  @override
  Future<ChatResponse> askFunding({
    required String question,
    int topK = 5,
    String? country,
    String? language,
    String? preferredLanguage,
  }) {
    throw Exception('network error');
  }

  @override
  Future<List<FundingSource>> getFundingSources() {
    throw Exception('network error');
  }
}

void main() {
  group('ChatBloc', () {
    test('emits user then assistant message on success', () async {
      final bloc = ChatBloc(chatRepository: _SuccessChatRepository());

      bloc.add(const SendChatMessage('Quels financements existent ?'));

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.messages.length, 2);
      expect(bloc.state.messages.first.isUser, isTrue);
      expect(bloc.state.messages.last.isUser, isFalse);
      expect(bloc.state.messages.last.citations, isNotEmpty);
      expect(bloc.state.messages.last.detectedLanguage, 'fr');
      expect(bloc.state.isSending, isFalse);

      await bloc.close();
    });

    test('keeps user message and exposes error on failure', () async {
      final bloc = ChatBloc(chatRepository: _ErrorChatRepository());

      bloc.add(const SendChatMessage('Question test'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.messages.length, 1);
      expect(bloc.state.messages.first.isUser, isTrue);
      expect(bloc.state.errorMessage, isNotNull);
      expect(bloc.state.isSending, isFalse);

      await bloc.close();
    });
  });
}
