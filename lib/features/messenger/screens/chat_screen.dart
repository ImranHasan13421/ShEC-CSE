import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_state.dart';
import '../../../backend/services/chat_service.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String groupName;
  final Color themeColor;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.groupName,
    required this.themeColor,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupRealtime();
  }

  Future<void> _loadMessages() async {
    final history = await ChatService.fetchMessageHistory(widget.roomId);
    if (mounted) {
      setState(() {
        _messages.addAll(history);
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _setupRealtime() {
    _subscription = ChatService.subscribeToRoom(widget.roomId, (newMessage) {
      if (mounted) {
        setState(() {
          // Only add if not already present (prevents duplicates from local echo)
          if (!_messages.any((m) => m.id == newMessage.id)) {
            _messages.add(newMessage);
          }
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    if (_subscription != null) {
      Supabase.instance.client.removeChannel(_subscription!);
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    
    // 1. Local Echo: Add to UI immediately
    final tempMsg = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      roomId: widget.roomId,
      senderId: Supabase.instance.client.auth.currentUser?.id ?? '',
      senderName: 'Me',
      text: text,
      createdAt: DateTime.now(),
      isMe: true,
    );

    setState(() {
      _messages.add(tempMsg);
    });
    _scrollToBottom();

    // 2. Send to server
    final realMsg = await ChatService.sendMessage(widget.roomId, text);
    
    // 3. Replace temp message with real one to sync ID
    if (mounted && realMsg != null) {
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempMsg.id);
        if (index != -1) {
          _messages[index] = realMsg;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.themeColor,
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
                  Text(widget.groupName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  Text('Chat Group', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    if (msg.isMe) {
                      return _buildSentMessage(
                        context: context,
                        message: msg.text,
                        time: DateFormat('h:mm a').format(msg.createdAt),
                      );
                    } else {
                      return _buildReceivedMessage(
                        context: context,
                        sender: msg.senderName,
                        message: msg.text,
                        time: DateFormat('h:mm a').format(msg.createdAt),
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
  }) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, right: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sender, style: TextStyle(fontSize: 12, color: colors.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
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
              border: Border.all(color: colors.outline.withOpacity(0.1)),
            ),
            child: Text(message, style: TextStyle(color: colors.onSurface, fontSize: 14)),
          ),
          const SizedBox(height: 4),
          Text(time, style: TextStyle(fontSize: 10, color: colors.onSurface.withOpacity(0.4))),
        ],
      ),
    );
  }

  Widget _buildSentMessage({required BuildContext context, required String message, required String time}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.themeColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          const SizedBox(height: 4),
          Text(time, style: TextStyle(fontSize: 10, color: Colors.black.withOpacity(0.4))),
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outline.withOpacity(0.1))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                onSubmitted: (_) => _handleSendMessage(),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: colors.onSurface.withOpacity(0.4)),
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
              backgroundColor: widget.themeColor,
              radius: 24,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _handleSendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}