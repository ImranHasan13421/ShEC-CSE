import 'package:flutter/material.dart';
import 'package:ShEC_CSE/features/messenger/screens/chat_screen.dart';
import 'package:ShEC_CSE/features/messenger/models/chat_state.dart';
import 'package:ShEC_CSE/backend/services/chat_service.dart';

class MessengerScreen extends StatefulWidget {
  const MessengerScreen({super.key});

  @override
  State<MessengerScreen> createState() => _MessengerScreenState();
}

class _MessengerScreenState extends State<MessengerScreen> {
  @override
  void initState() {
    super.initState();
    ChatService.fetchRooms();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: ValueListenableBuilder<bool>(
        valueListenable: isLoadingChatRooms,
        builder: (context, isLoading, _) {
          if (isLoading) return const Center(child: CircularProgressIndicator());

          return ValueListenableBuilder<List<ChatRoom>>(
            valueListenable: chatRoomsList,
            builder: (context, rooms, _) {
              if (rooms.isEmpty) return const Center(child: Text('No active chat groups.'));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  return _buildChatTile(
                    context: context,
                    title: room.name,
                    subtitle: room.description,
                    time: '', // Could be updated with last message time
                    unreadCount: 0,
                    icon: _getIcon(room.type),
                    iconColor: _getColor(room.type, colors),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            roomId: room.id,
                            groupName: room.name,
                            themeColor: _getColor(room.type, colors),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIcon(ChatRoomType type) {
    switch (type) {
      case ChatRoomType.committee: return Icons.shield;
      case ChatRoomType.problemSolving: return Icons.code;
      default: return Icons.groups;
    }
  }

  Color _getColor(ChatRoomType type, ColorScheme colors) {
    switch (type) {
      case ChatRoomType.committee: return Colors.red;
      case ChatRoomType.problemSolving: return Colors.indigo;
      default: return colors.primary;
    }
  }

  Widget _buildChatTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String time,
    required int unreadCount,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: iconColor.withValues(alpha: 0.1),
        child: Icon(icon, color: iconColor, size: 28),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: unreadCount > 0 ? colors.onSurface : colors.onSurface.withValues(alpha: 0.6),
            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: TextStyle(
              color: unreadCount > 0 ? iconColor : colors.onSurface.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 6),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}