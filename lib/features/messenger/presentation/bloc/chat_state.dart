import 'package:equatable/equatable.dart';
import '../../models/chat_state.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatRoomsLoading extends ChatState {}

class ChatRoomsLoaded extends ChatState {
  final List<ChatRoom> rooms;

  const ChatRoomsLoaded({required this.rooms});

  @override
  List<Object?> get props => [rooms];
}

class ChatHistoryLoading extends ChatState {}

class ChatHistoryLoaded extends ChatState {
  final List<ChatMessage> messages;

  const ChatHistoryLoaded({required this.messages});

  @override
  List<Object?> get props => [messages];
}

class ChatError extends ChatState {
  final String message;

  const ChatError({required this.message});

  @override
  List<Object?> get props => [message];
}
