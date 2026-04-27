import 'package:flutter/material.dart';
import 'package:ShEC_CSE/features/messenger/screens/chat_screen.dart'; // Make sure this imports the file we just updated

class MessengerScreen extends StatelessWidget {
  const MessengerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // 0. Alumni Association
          _buildChatTile(
            context: context,
            title: 'Alumni Association',
            subtitle: 'Interested, meet me at home...',
            time: '5:16 PM',
            unreadCount: 0,
            icon: Icons.diamond_outlined,
            iconColor: Colors.red, // Distinct Indigo Color
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    groupName: 'Alumni Association',
                    memberCount: '21',
                    themeColor: Colors.red,
                    messages: _getAlumniMesseges(),
                  ),
                ),
              );
            },
          ),

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

  List<Map<String, dynamic>> _getAlumniMesseges() {
    return [
      {'sender': 'Soikot Bhuiyan', 'text': "Hey everyone! Looking for an asset manager for a game development startup.", 'time': '9:00 AM', 'isCommittee': false, 'isMe': false},
      {'sender': 'Me', 'text': "Tanvirul Islam might be interested", 'time': '9:05 AM', 'isCommittee': false, 'isMe': true},
      {'sender': 'Tanvirul Islam', 'text': "Sure, I am willing to work", 'time': '9:10 AM', 'isCommittee': false, 'isMe': false},
      {'sender': 'Soikot Bhuiyan', 'text': "Ok, 2 PM. Meet me at campus", 'time': '9:12 AM', 'isCommittee': true, 'isMe': false},
      {'sender': 'Abdul Aowal Asif', 'text': "A Junior Flutter Developer with minimum 1 year experience is needed in Ezze Softwares Company. Anyone interested please response!", 'time': '5:16 PM', 'isCommittee': false, 'isMe': false},
      {'sender': 'Me', 'text': "Interested, meet me at home, we will discuss about salary", 'time': '5:16 PM', 'isCommittee': false, 'isMe': true},
    ];
  }

  List<Map<String, dynamic>> _getGeneralMessages() {
    return [
      {'sender': 'Sarah Johnson', 'text': "Hey everyone! Don't forget about the workshop tomorrow.", 'time': '9:00 AM', 'isCommittee': true, 'isMe': false},
      {'sender': 'Me', 'text': "Thanks for the reminder! What time does it start?", 'time': '9:05 AM', 'isCommittee': false, 'isMe': true},
      {'sender': 'Mike Chen', 'text': "It starts at 2 PM in the main auditorium.", 'time': '9:10 AM', 'isCommittee': false, 'isMe': false},
      {'sender': 'Sarah Johnson', 'text': "Yes, 2 PM sharp. Please be on time!", 'time': '9:12 AM', 'isCommittee': true, 'isMe': false},
      {'sender': 'Me', 'text': "Got it! See you all there.", 'time': '9:15 AM', 'isCommittee': false, 'isMe': true},
      {'sender': 'Abdul Aowal Asif', 'text': "Sounds good, I'll come by around 1.30 PM.", 'time': '5:18 PM', 'isCommittee': false, 'isMe': false},
      {'sender': 'Saifur Rahman', 'text': "Guys, don't forget we have the Machine Learning workshop tomorrow at 10 AM in the main lab.", 'time': '6:00 PM', 'isCommittee': true, 'isMe': false},
      {'sender': 'Me', 'text': "Do we need to install anything on our laptops beforehand?", 'time': '6:05 PM', 'isCommittee': false, 'isMe': true},
      {'sender': 'Saifur Rahman', 'text': "Yes, please have Python and Anaconda installed before you arrive.", 'time': '6:08 PM', 'isCommittee': true, 'isMe': false},
      {'sender': 'MD. Imran Hasan', 'text': "I've pinned the installation guide document to the group description.", 'time': '6:10 PM', 'isCommittee': true, 'isMe': false},
      {'sender': 'Me', 'text': "Awesome, thanks bhai!", 'time': '6:12 PM', 'isCommittee': false, 'isMe': true},
      {'sender': 'Toifika Tasnim Oishe', 'text': "Can someone share the slides from yesterday's Data Structures class?", 'time': '7:30 PM', 'isCommittee': true, 'isMe': false},
      {'sender': 'MD. Mehedi Hasan Mridul', 'text': "Uploading them right now...", 'time': '7:32 PM', 'isCommittee': true, 'isMe': false},
      {'sender': 'MD. Mehedi Hasan Mridul', 'text': "📄 DS_Lecture_04_Trees.pdf", 'time': '7:33 PM', 'isCommittee': true, 'isMe': false},
      {'sender': 'Toifika Tasnim Oishe', 'text': "Got it, thanks Mridul!", 'time': '7:35 PM', 'isCommittee': true, 'isMe': false},
      {'sender': 'Istiak Hossain Khan', 'text': "Is anyone participating in the Codeforces Round #892 tonight?", 'time': '8:00 PM', 'isCommittee': true, 'isMe': false},
      {'sender': 'Me', 'text': "I'm in! Aiming to finally reach Specialist tier 🤞", 'time': '8:02 PM', 'isCommittee': false, 'isMe': true},
      {'sender': 'Tanvirul islam', 'text': "Best of luck! I'll be skipping this one, got a project deadline at midnight.", 'time': '8:05 PM', 'isCommittee': true, 'isMe': false},
      {'sender': 'Soikot Bhuiyan', 'text': "Has the department published the final exam routine yet?", 'time': '8:20 PM', 'isCommittee': false, 'isMe': false},
      {'sender': 'Saifur Rahman', 'text': "Not officially, but I heard from the faculty it might start from the 15th of next month.", 'time': '8:25 PM', 'isCommittee': true, 'isMe': false},
      {'sender': 'Abdul Aowal Asif', 'text': "Ah, time to actually start studying I guess 😅", 'time': '8:26 PM', 'isCommittee': false, 'isMe': false},
      {'sender': 'Me', 'text': "Relatable. My syllabus is completely untouched.", 'time': '8:28 PM', 'isCommittee': false, 'isMe': true},
      {'sender': 'MD. Imran Hasan', 'text': "Don't worry, we'll organize a club group study session next week to cover the hard topics.", 'time': '8:35 PM', 'isCommittee': true, 'isMe': false},
      {'sender': 'Istiak Hossain Khan', 'text': "Count me in for that study session!", 'time': '8:36 PM', 'isCommittee': true, 'isMe': false},
      {'sender': 'Saifur Rahman', 'text': "Perfect. Let's finalize the date by Friday.", 'time': '8:45 PM', 'isCommittee': true, 'isMe': false},
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