import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/chat_message.dart';
import '../../../domain/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;

  ChatBloc({required this.chatRepository}) : super(const ChatState()) {
    on<SendChatMessage>(_onSendChatMessage);
    on<LoadFundingSources>(_onLoadFundingSources);
    on<ClearChatError>(_onClearChatError);
  }

  Future<void> _onSendChatMessage(
    SendChatMessage event,
    Emitter<ChatState> emit,
  ) async {
    final question = event.question.trim();
    if (question.isEmpty) {
      return;
    }

    final userMessage = ChatMessage(
      text: question,
      isUser: true,
      createdAt: DateTime.now(),
    );
    emit(
      state.copyWith(
        messages: [...state.messages, userMessage],
        isSending: true,
        clearError: true,
      ),
    );

    try {
      final response = await chatRepository.askFunding(
        question: question,
        language: event.language,
      );
      final assistantMessage = ChatMessage(
        text: response.answer,
        isUser: false,
        createdAt: DateTime.now(),
        citations: response.citations,
        limits: response.limits,
        detectedLanguage: response.detectedLanguage,
        modelUsed: response.modelUsed,
        fallbackReason: response.fallbackReason,
      );
      emit(
        state.copyWith(
          messages: [...state.messages, assistantMessage],
          isSending: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSending: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadFundingSources(
    LoadFundingSources event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isLoadingSources: true, clearError: true));
    try {
      final sources = await chatRepository.getFundingSources();
      emit(
        state.copyWith(
          sources: sources,
          isLoadingSources: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingSources: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onClearChatError(
    ClearChatError event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(clearError: true));
  }
}
