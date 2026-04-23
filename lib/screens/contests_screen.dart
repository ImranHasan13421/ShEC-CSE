import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Make sure you added this to pubspec.yaml

class ContestsScreen extends StatelessWidget {
  const ContestsScreen({super.key});

  // Helper method to open URLs in the external browser
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // 1. The TabBar
          Container(
            color: colors.primary,
            child: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: [
                Tab(text: 'Contests'),
                Tab(text: 'Events & Courses'),
              ],
            ),
          ),

          // 2. The Tab Views
          Expanded(
            child: TabBarView(
              children: [
                _buildContestsTab(context),
                _buildCoursesTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContestsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildContestCard(
          context: context,
          iconColor: Colors.blue,
          title: 'Codeforces Rounds',
          platform: 'Codeforces',
          level: 'Div 1, 2, 3, 4',
          date: 'Frequent / Weekly',
          url: 'https://codeforces.com/contests',
        ),
        _buildContestCard(
          context: context,
          iconColor: Colors.orange,
          title: 'LeetCode Weekly Contest',
          platform: 'LeetCode',
          level: 'All Levels',
          date: 'Every Sunday',
          url: 'https://leetcode.com/contest/',
        ),
        _buildContestCard(
          context: context,
          iconColor: Colors.teal,
          title: 'AtCoder Beginner Contest',
          platform: 'AtCoder',
          level: 'Beginner / Intermediate',
          date: 'Weekends',
          url: 'https://atcoder.jp/contests/',
        ),
        _buildContestCard(
          context: context,
          iconColor: Colors.brown,
          title: 'CodeChef Starters',
          platform: 'CodeChef',
          level: 'Rated for All',
          date: 'Every Wednesday',
          url: 'https://www.codechef.com/contests',
        ),
        _buildContestCard(
          context: context,
          iconColor: Colors.indigo,
          title: 'HackerEarth Challenges',
          platform: 'HackerEarth',
          level: 'Various',
          date: 'Ongoing & Monthly',
          url: 'https://www.hackerearth.com/challenges/',
        ),
      ],
    );
  }

  Widget _buildCoursesTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildCourseCard(
          context: context,
          icon: Icons.computer,
          iconColor: Colors.redAccent,
          title: "CS50's Intro to Computer Science",
          provider: 'Harvard University',
          tag: 'Free / Cert Optional',
          url: 'https://pll.harvard.edu/course/cs50-introduction-computer-science',
        ),
        _buildCourseCard(
          context: context,
          icon: Icons.web,
          iconColor: Colors.indigo,
          title: 'Responsive Web Design',
          provider: 'freeCodeCamp',
          tag: 'Free Certificate',
          url: 'https://www.freecodecamp.org/learn/responsive-web-design/',
        ),
        _buildCourseCard(
          context: context,
          icon: Icons.psychology,
          iconColor: Colors.blue,
          title: 'Machine Learning Specialization',
          provider: 'DeepLearning.AI',
          tag: 'Free to Audit',
          url: 'https://www.coursera.org/specializations/machine-learning-introduction',
        ),
        _buildCourseCard(
          context: context,
          icon: Icons.developer_mode,
          iconColor: Colors.teal,
          title: 'Full Stack Open',
          provider: 'University of Helsinki',
          tag: 'Free Certificate',
          url: 'https://fullstackopen.com/en/',
        ),
        _buildCourseCard(
          context: context,
          icon: Icons.lightbulb,
          iconColor: Colors.amber,
          title: 'Elements of AI',
          provider: 'University of Helsinki',
          tag: 'Free Certificate',
          url: 'https://www.elementsofai.com/',
        ),
        _buildCourseCard(
          context: context,
          icon: Icons.code,
          iconColor: Colors.deepPurple,
          title: 'Python for Everybody',
          provider: 'University of Michigan',
          tag: 'Free to Audit',
          url: 'https://www.coursera.org/specializations/python',
        ),
        _buildCourseCard(
          context: context,
          icon: Icons.data_object,
          iconColor: Colors.indigoAccent,
          title: 'JS Algorithms & Data Structures',
          provider: 'freeCodeCamp',
          tag: 'Free Certificate',
          url: 'https://www.freecodecamp.org/learn/javascript-algorithms-and-data-structures/',
        ),
        _buildCourseCard(
          context: context,
          icon: Icons.cloud,
          iconColor: Colors.cyan,
          title: 'Introduction to Cloud Computing',
          provider: 'IBM',
          tag: 'Free to Audit',
          url: 'https://www.coursera.org/learn/introduction-to-cloud',
        ),
        _buildCourseCard(
          context: context,
          icon: Icons.terminal,
          iconColor: Colors.grey.shade800,
          title: 'Intro to CS & Programming in Python',
          provider: 'MIT OpenCourseWare',
          tag: 'Free Course',
          url: 'https://ocw.mit.edu/courses/6-0001-introduction-to-computer-science-and-programming-in-python-fall-2016/',
        ),
        _buildCourseCard(
          context: context,
          icon: Icons.language,
          iconColor: Colors.redAccent,
          title: "CS50's Web Programming",
          provider: 'Harvard University',
          tag: 'Free / Cert Optional',
          url: 'https://pll.harvard.edu/course/cs50s-web-programming-python-and-javascript',
        ),
      ],
    );
  }

  Widget _buildContestCard({
    required BuildContext context,
    required Color iconColor,
    required String title,
    required String platform,
    required String level,
    required String date,
    required String url,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.emoji_events, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(platform, style: TextStyle(color: colors.onSurface.withOpacity(0.7), fontSize: 13)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(level, style: TextStyle(color: colors.error, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: colors.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 6),
                    Text(date, style: TextStyle(color: colors.onSurface.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _launchURL(url), // Launches browser URL
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Join Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String provider,
    required String tag,
    required String url,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Flexible( // Added Flexible to prevent overflow on small screens
                child: Text(
                  provider,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tag, style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () => _launchURL(url), // Launches browser URL
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.surfaceContainerHighest,
            foregroundColor: colors.primary,
            elevation: 0,
          ),
          child: const Text('Details'),
        ),
      ),
    );
  }
}