import 'package:equatable/equatable.dart';

import 'chat_citation.dart';

class ChatResponse extends Equatable {
  final String answer;
  final double confidence;
  final List<ChatCitation> citations;
  final List<String> limits;

  const ChatResponse({
    required this.answer,
    required this.confidence,
    required this.citations,
    required this.limits,
  });

  @override
  List<Object?> get props => [answer, confidence, citations, limits];
}
