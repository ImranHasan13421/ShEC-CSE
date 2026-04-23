import 'package:flutter/material.dart';
import 'chat_screen.dart'; // Make sure this imports the file we just updated

class MessengerScreen extends StatelessWidget {
  const MessengerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messenger'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // 1. General Club Group
          _buildChatTile(
            context: context,
            title: 'General Club Group',
            subtitle: 'Got it! See you all there.',
            time: '9:15 AM',
            unreadCount: 0,
            icon: Icons.groups,
            iconColor: colors.primary, // Default Teal
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    groupName: 'General Club Group',
                    memberCount: '156',
                    themeColor: colors.primary,
                    messages: _getGeneralMessages(),
                  ),
                ),
              );
            },
          ),

          // 2. Problem Solving and Instruction Group
          _buildChatTile(
            context: context,
            title: 'Problem Solving and Instruction Group',
            subtitle: 'We will cover this optimization tomorrow!',
            time: 'Yesterday',
            unreadCount: 3,
            icon: Icons.code,
            iconColor: Colors.indigo, // Distinct Indigo Color
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    groupName: 'Problem Solving & Instruction',
                    memberCount: '84',
                    themeColor: Colors.indigo,
                    messages: _getProblemSolvingMessages(),
                  ),
                ),
              );
            },
          ),

          // 3. Course Related Discussion Group
          _buildChatTile(
            context: context,
            title: 'Course Related Discussion Group',
            subtitle: 'Make sure to focus on process scheduling.',
            time: 'Mon',
            unreadCount: 0,
            icon: Icons.menu_book,
            iconColor: Colors.orange, // Distinct Orange Color
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    groupName: 'Course Related Discussion',
                    memberCount: '120',
                    themeColor: Colors.orange.shade700,
                    messages: _getCourseMessages(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.message),
      ),
    );
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
        backgroundColor: iconColor.withOpacity(0.1),
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
            color: unreadCount > 0 ? colors.onSurface : colors.onSurface.withOpacity(0.6),
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
              color: unreadCount > 0 ? iconColor : colors.onSurface.withOpacity(0.5),
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

  // --- MOCK DATA GENERATORS ---

  List<Map<String, dynamic>> _getGeneralMessages() {
    return [
      {'sender': 'Sarah Johnson', 'text': "Hey everyone! Don't forget about the workshop tomorrow.", 'time': '9:00 AM', 'isCommittee': true, 'isMe': false},
      {'sender': 'Me', 'text': "Thanks for the reminder! What time does it start?", 'time': '9:05 AM', 'isCommittee': false, 'isMe': true},
      {'sender': 'Mike Chen', 'text': "It starts at 2 PM in the main auditorium.", 'time': '9:10 AM', 'isCommittee': false, 'isMe': false},
      {'sender': 'Sarah Johnson', 'text': "Yes, 2 PM sharp. Please be on time!", 'time': '9:12 AM', 'isCommittee': true, 'isMe': false},
      {'sender': 'Me', 'text': "Got it! See you all there.", 'time': '9:15 AM', 'isCommittee': false, 'isMe': true},
    ];
  }

  List<Map<String, dynamic>> _getProblemSolvingMessages() {
    return [
      {'sender': 'Me', 'text': "Did anyone figure out the Time Limit Exceeded error on Codeforces problem C?", 'time': '4:30 PM', 'isCommittee': false, 'isMe': true},
      {'sender': 'Fahim Rahman', 'text': "Yeah, you need to use a HashMap instead of nested loops. It brings it down to O(n) complexity.", 'time': '4:35 PM', 'isCommittee': false, 'isMe': false},
      {'sender': 'Me', 'text': "Ah! That makes so much sense. Let me try rewriting it now.", 'time': '4:38 PM', 'isCommittee': false, 'isMe': true},
      {'sender': 'Ahmed Hassan', 'text': "Great catch Fahim! We will cover this specific HashMap optimization in tomorrow's weekly coding session.", 'time': '5:00 PM', 'isCommittee': true, 'isMe': false},
    ];
  }

  List<Map<String, dynamic>> _getCourseMessages() {
    return [
      {'sender': 'Nusrat Jahan', 'text': "Does anyone have the exact syllabus for the Operating Systems Mid-term?", 'time': '10:00 AM', 'isCommittee': false, 'isMe': false},
      {'sender': 'Me', 'text': "Yes, it covers chapters 1 through 4 from the main textbook.", 'time': '10:05 AM', 'isCommittee': false, 'isMe': true},
      {'sender': 'Dr. Abu Ashik Md Irfan', 'text': "Correct. Make sure to focus heavily on process scheduling algorithms for the written portion.", 'time': '10:30 AM', 'isCommittee': true, 'isMe': false},
    ];
  }
}