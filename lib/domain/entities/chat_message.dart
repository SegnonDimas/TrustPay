import 'package:equatable/equatable.dart';

import 'chat_citation.dart';

class ChatMessage extends Equatable {
  final String text;
  final bool isUser;
  final DateTime createdAt;
  final List<ChatCitation> citations;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.citations = const [],
  });

  @override
  List<Object?> get props => [text, isUser, createdAt, citations];
}
