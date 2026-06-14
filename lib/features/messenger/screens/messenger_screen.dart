import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ShEC_CSE/features/messenger/screens/chat_screen.dart';
import 'package:ShEC_CSE/features/messenger/models/chat_state.dart';
import 'package:intl/intl.dart';
import '../presentation/bloc/chat_bloc.dart';
import '../presentation/bloc/chat_event.dart';
import '../presentation/bloc/chat_state.dart';

class MessengerScreen extends StatefulWidget {
  const MessengerScreen({super.key});

  @override
  State<MessengerScreen> createState() => _MessengerScreenState();
}

class _MessengerScreenState extends State<MessengerScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(FetchRoomsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ChatBloc>().add(FetchRoomsRequested());
        },
        child: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            final rooms = context.read<ChatBloc>().rooms;

            if (state is ChatRoomsLoading && rooms.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ChatError && rooms.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  alignment: Alignment.center,
                  child: Text(state.message),
                ),
              );
            }

            if (rooms.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  alignment: Alignment.center,
                  child: const Text('No active chat groups.'),
                ),
              );
            }

            return ValueListenableBuilder<Map<String, int>>(
              valueListenable: chatRoomUnreadCounts,
              builder: (context, unreadMap, _) {
                return ValueListenableBuilder<Map<String, ChatMessage>>(
                  valueListenable: chatRoomLastMessages,
                  builder: (context, lastMessagesMap, _) {
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        final unreadCount = unreadMap[room.id] ?? 0;
                        final lastMsg = lastMessagesMap[room.id];
                        
                        String displaySubtitle = room.description;
                        String displayTime = '';
                        
                        if (lastMsg != null) {
                          final senderName = lastMsg.isMe ? 'You' : lastMsg.senderName;
                          displaySubtitle = '$senderName: ${lastMsg.text}';
                          
                          final DateFormat timeFormat = DateFormat('h:mm a');
                          final DateFormat dayFormat = DateFormat('MMM d');
                          final now = DateTime.now();
                          if (lastMsg.createdAt.year == now.year &&
                              lastMsg.createdAt.month == now.month &&
                              lastMsg.createdAt.day == now.day) {
                            displayTime = timeFormat.format(lastMsg.createdAt);
                          } else {
                            displayTime = dayFormat.format(lastMsg.createdAt);
                          }
                        }

                        return _buildChatTile(
                          context: context,
                          title: room.name,
                          subtitle: displaySubtitle,
                          time: displayTime,
                          unreadCount: unreadCount,
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
            );
          },
        ),
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
    final isUnread = unreadCount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.surfaceContainerLow,
            isUnread 
                ? iconColor.withValues(alpha: 0.06) 
                : colors.surfaceContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnread 
              ? iconColor.withValues(alpha: 0.55) 
              : colors.outline.withValues(alpha: 0.15),
          width: isUnread ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isUnread 
                ? iconColor.withValues(alpha: 0.12) 
                : colors.shadow.withValues(alpha: 0.03),
            blurRadius: isUnread ? 12 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon Avatar with glowing background
                Stack(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            iconColor.withValues(alpha: 0.18),
                            iconColor.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: iconColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                    if (isUnread)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: iconColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.surface, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: iconColor.withValues(alpha: 0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          fontSize: 15.5,
                          color: colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isUnread 
                              ? colors.onSurface.withValues(alpha: 0.9) 
                              : colors.onSurface.withValues(alpha: 0.55),
                          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Trailing Time & Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color: isUnread ? iconColor : colors.onSurface.withValues(alpha: 0.45),
                        fontSize: 11.5,
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (isUnread) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: iconColor,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: iconColor.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}