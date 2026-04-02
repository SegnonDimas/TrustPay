import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class SendChatMessage extends ChatEvent {
  final String question;
  final String? language;

  const SendChatMessage(
    this.question, {
    this.language,
  });

  @override
  List<Object?> get props => [question, language];
}

class LoadFundingSources extends ChatEvent {}

class ClearChatError extends ChatEvent {}
