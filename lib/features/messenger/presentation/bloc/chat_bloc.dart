import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../backend/services/chat_service.dart';
import '../../models/chat_state.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final List<ChatMessage> _messages = [];
  final List<ChatRoom> _rooms = [];

  List<ChatRoom> get rooms => _rooms;

  ChatBloc() : super(ChatInitial()) {
    on<FetchRoomsRequested>(_onFetchRoomsRequested);
    on<FetchHistoryRequested>(_onFetchHistoryRequested);
    on<SendMessageRequested>(_onSendMessageRequested);
    on<ReceiveMessageRequested>(_onReceiveMessageRequested);
  }

  Future<void> _onFetchRoomsRequested(
    FetchRoomsRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatRoomsLoading());
    try {
      final fetchedRooms = await ChatService.fetchRooms();
      _rooms.clear();
      _rooms.addAll(fetchedRooms);
      emit(ChatRoomsLoaded(rooms: List.from(_rooms)));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onFetchHistoryRequested(
    FetchHistoryRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatHistoryLoading());
    try {
      _messages.clear();
      final history = await ChatService.fetchMessageHistory(event.roomId);
      _messages.addAll(history);
      emit(ChatHistoryLoaded(messages: List.from(_messages)));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onSendMessageRequested(
    SendMessageRequested event,
    Emitter<ChatState> emit,
  ) async {
    final user = Supabase.instance.client.auth.currentUser;
    final tempMsg = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      roomId: event.roomId,
      senderId: user?.id ?? '',
      senderName: 'Me',
      text: event.text,
      createdAt: DateTime.now(),
      isMe: true,
    );

    // Optimistically add the message and emit
    _messages.add(tempMsg);
    emit(ChatHistoryLoaded(messages: List.from(_messages)));

    try {
      final realMsg = await ChatService.sendMessage(event.roomId, event.text);
      if (realMsg != null) {
        final index = _messages.indexWhere((m) => m.id == tempMsg.id);
        if (index != -1) {
          _messages[index] = realMsg;
        } else {
          _messages.add(realMsg);
        }
        emit(ChatHistoryLoaded(messages: List.from(_messages)));
      }
    } catch (e) {
      // Remove temporary message on failure, or just keep it and show error
      _messages.removeWhere((m) => m.id == tempMsg.id);
      emit(ChatHistoryLoaded(messages: List.from(_messages)));
      emit(ChatError(message: 'Failed to send message: ${e.toString()}'));
    }
  }

  void _onReceiveMessageRequested(
    ReceiveMessageRequested event,
    Emitter<ChatState> emit,
  ) {
    if (!_messages.any((m) => m.id == event.message.id)) {
      _messages.add(event.message);
      emit(ChatHistoryLoaded(messages: List.from(_messages)));
    }
  }
}
