import 'package:equatable/equatable.dart';

import 'chat_citation.dart';

class ChatMessage extends Equatable {
  final String text;
  final bool isUser;
  final DateTime createdAt;
  final List<ChatCitation> citations;
  final List<String> limits;
  final String detectedLanguage;
  final String modelUsed;
  final String fallbackReason;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.citations = const [],
    this.limits = const [],
    this.detectedLanguage = '',
    this.modelUsed = '',
    this.fallbackReason = '',
  });

  @override
  List<Object?> get props => [
        text,
        isUser,
        createdAt,
        citations,
        limits,
        detectedLanguage,
        modelUsed,
        fallbackReason,
      ];
}
