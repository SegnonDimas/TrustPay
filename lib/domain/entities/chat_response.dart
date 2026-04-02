import 'package:equatable/equatable.dart';

import 'chat_citation.dart';

class ChatResponse extends Equatable {
  final String answer;
  final double confidence;
  final List<ChatCitation> citations;
  final List<String> limits;
  final String detectedLanguage;
  final String modelUsed;
  final String fallbackReason;

  const ChatResponse({
    required this.answer,
    required this.confidence,
    required this.citations,
    required this.limits,
    this.detectedLanguage = '',
    this.modelUsed = '',
    this.fallbackReason = '',
  });

  @override
  List<Object?> get props => [
        answer,
        confidence,
        citations,
        limits,
        detectedLanguage,
        modelUsed,
        fallbackReason,
      ];
}
