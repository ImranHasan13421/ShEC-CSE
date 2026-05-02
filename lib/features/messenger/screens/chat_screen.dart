import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final String groupName;
  final String memberCount;
  final Color themeColor;
  final List<Map<String, dynamic>> messages;

  const ChatScreen({
    super.key,
    required this.groupName,
    required this.memberCount,
    required this.themeColor,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor, // Dynamic Theme Color
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white24,
              radius: 20,
              child: Icon(Icons.group, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(groupName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  Text('$memberCount members', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                if (msg['isMe'] == true) {
                  return _buildSentMessage(
                    context: context,
                    message: msg['text'],
                    time: msg['time'],
                  );
                } else {
                  return _buildReceivedMessage(
                    context: context,
                    sender: msg['sender'],
                    message: msg['text'],
                    time: msg['time'],
                    isCommittee: msg['isCommittee'],
                  );
                }
              },
            ),
          ),
          _buildMessageInput(context, colors),
        ],
      ),
    );
  }

  Widget _buildReceivedMessage({
    required BuildContext context,
    required String sender,
    required String message,
    required String time,
    required bool isCommittee,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, right: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(sender, style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold)),
              if (isCommittee) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Committee', style: TextStyle(color: themeColor, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ]
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
            ),
            child: Text(message, style: TextStyle(color: colors.onSurface, fontSize: 14)),
          ),
          const SizedBox(height: 4),
          Text(time, style: TextStyle(fontSize: 10, color: colors.onSurface.withValues(alpha: 0.4))),
        ],
      ),
    );
  }

  Widget _buildSentMessage({required BuildContext context, required String message, required String time}) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: themeColor, // Dynamic Theme Color for sent messages
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          const SizedBox(height: 4),
          Text(time, style: TextStyle(fontSize: 10, color: colors.onSurface.withValues(alpha: 0.4))),
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outline.withValues(alpha: 0.1))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.attach_file, color: colors.onSurface.withValues(alpha: 0.5)),
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: colors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: themeColor, // Dynamic Theme Color
              radius: 24,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}