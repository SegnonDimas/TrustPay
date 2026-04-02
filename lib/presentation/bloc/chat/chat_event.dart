import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class SendChatMessage extends ChatEvent {
  final String question;

  const SendChatMessage(this.question);

  @override
  List<Object?> get props => [question];
}

class LoadFundingSources extends ChatEvent {}

class ClearChatError extends ChatEvent {}
