import 'package:flutter/material.dart';

enum ChatRoomType { committee, general, problemSolving }

class ChatRoom {
  final String id;
  final String name;
  final String description;
  final ChatRoomType type;
  final String iconKey;
  final DateTime createdAt;

  ChatRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.iconKey,
    required this.createdAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    ChatRoomType parsedType;
    switch (json['type']) {
      case 'committee': parsedType = ChatRoomType.committee; break;
      case 'problem_solving': parsedType = ChatRoomType.problemSolving; break;
      default: parsedType = ChatRoomType.general;
    }

    return ChatRoom(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      type: parsedType,
      iconKey: json['icon_key'] ?? 'groups',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
    required this.isMe,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    return ChatMessage(
      id: json['id'],
      roomId: json['room_id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      text: json['text'],
      createdAt: DateTime.parse(json['created_at']),
      isMe: json['sender_id'] == currentUserId,
    );
  }
}

// Global Notifiers
final ValueNotifier<List<ChatRoom>> chatRoomsList = ValueNotifier([]);
final ValueNotifier<bool> isLoadingChatRooms = ValueNotifier(false);
