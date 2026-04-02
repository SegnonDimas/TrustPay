import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class SendChatMessage extends ChatEvent {
  final String question;
  final String? preferredLanguage;

  const SendChatMessage(
    this.question, {
    this.preferredLanguage,
  });

  @override
  List<Object?> get props => [question, preferredLanguage];
}

class LoadFundingSources extends ChatEvent {}

class ClearChatError extends ChatEvent {}
