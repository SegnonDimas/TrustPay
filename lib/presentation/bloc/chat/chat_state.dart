import 'package:equatable/equatable.dart';

import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/funding_source.dart';

class ChatState extends Equatable {
  final List<ChatMessage> messages;
  final List<FundingSource> sources;
  final bool isSending;
  final bool isLoadingSources;
  final String? errorMessage;

  const ChatState({
    this.messages = const [],
    this.sources = const [],
    this.isSending = false,
    this.isLoadingSources = false,
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    List<FundingSource>? sources,
    bool? isSending,
    bool? isLoadingSources,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      sources: sources ?? this.sources,
      isSending: isSending ?? this.isSending,
      isLoadingSources: isLoadingSources ?? this.isLoadingSources,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        messages,
        sources,
        isSending,
        isLoadingSources,
        errorMessage,
      ];
}
