import 'package:equatable/equatable.dart';
import '../../models/chat_state.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class FetchRoomsRequested extends ChatEvent {}

class FetchHistoryRequested extends ChatEvent {
  final String roomId;

  const FetchHistoryRequested({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class SendMessageRequested extends ChatEvent {
  final String roomId;
  final String text;

  const SendMessageRequested({required this.roomId, required this.text});

  @override
  List<Object?> get props => [roomId, text];
}

class ReceiveMessageRequested extends ChatEvent {
  final ChatMessage message;

  const ReceiveMessageRequested({required this.message});

  @override
  List<Object?> get props => [message];
}
