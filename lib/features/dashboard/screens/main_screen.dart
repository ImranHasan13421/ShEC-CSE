// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import 'package:ShEC_CSE/features/dashboard/screens/home_screen.dart';
import 'package:ShEC_CSE/features/department/screens/department_screen.dart';
import 'package:ShEC_CSE/features/auth/screens/login_screen.dart';
import 'package:ShEC_CSE/backend/services/auth_service.dart';
import 'package:ShEC_CSE/features/notices/screens/notices_screen.dart';
import 'package:ShEC_CSE/features/jobs/screens/jobs_screen.dart';
import 'package:ShEC_CSE/features/contests/screens/contests_screen.dart';
import 'package:ShEC_CSE/features/messenger/screens/messenger_screen.dart';
import 'package:ShEC_CSE/features/club/screens/club_screen.dart';
import 'package:ShEC_CSE/features/gallery/screens/gallery_screen.dart';
import 'package:ShEC_CSE/features/profile/screens/profile_screen.dart';
import 'package:ShEC_CSE/features/cgpa_calculator/screens/cgpa_calculator_screen.dart';
import 'package:ShEC_CSE/features/resources/screens/resources_screen.dart';
import 'package:ShEC_CSE/features/results/screens/results_screen.dart';
import 'package:ShEC_CSE/features/department/screens/teacher_contacts_screen.dart';
import 'package:ShEC_CSE/features/club/screens/club_members_screen.dart';
import 'package:ShEC_CSE/features/about/screens/contributors_screen.dart';
import 'package:ShEC_CSE/features/alumni/screens/alumni_screen.dart';
import 'package:ShEC_CSE/backend/services/notice_service.dart';
import 'package:ShEC_CSE/backend/services/job_service.dart';
import 'package:ShEC_CSE/backend/services/contest_service.dart';

class HomeLayout extends StatefulWidget {
  const HomeLayout({super.key});

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize Real-time subscriptions
    NoticeService.subscribeToNotices();
    JobService.subscribeToJobs();
    ContestService.subscribeToContests();
  }

  List<Widget> _getScreens() {
    return [
      DashboardScreen(
        onNavigateToTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      const NoticesScreen(),
      const MessengerScreen(),
      const ContestsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        setState(() => _currentIndex = 0);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/branding/logo.png', height: 28, width: 28),
              const SizedBox(width: 12),
              Text(
                _currentIndex == 0 ? 'ShEC CSE' : _getAppBarTitle(_currentIndex),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            ValueListenableBuilder<ProfileData>(
              valueListenable: currentProfile,
              builder: (context, profile, _) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                    },
                    child: _AnimatedProfileIcon(profile: profile, colors: colors),
                  ),
                );
              },
            ),
          ],
        ),
        drawer: _buildDrawer(context, colors),
        body: IndexedStack(
          index: _currentIndex,
          children: _getScreens(),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: colors.primary,
          unselectedItemColor: colors.onSurface.withValues(alpha: 0.5),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notices'),
            BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messenger'),
            BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Contests'),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 1: return 'Notices';
      case 2: return 'Messenger';
      case 3: return 'Contests';
      default: return 'ShEC CSE';
    }
  }

  Widget _buildDrawer(BuildContext context, ColorScheme colors) {
    return Drawer(
      backgroundColor: colors.surface,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ValueListenableBuilder<ProfileData>(
                  valueListenable: currentProfile,
                  builder: (context, profile, _) {
                    return UserAccountsDrawerHeader(
                      decoration: BoxDecoration(color: colors.primary),
                      accountName: Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      accountEmail: Text('${profile.designation} • ${profile.email}'),
                      currentAccountPicture: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            backgroundImage: profile.imagePath != null && profile.imagePath!.startsWith('http')
                                ? NetworkImage(profile.imagePath!) as ImageProvider
                                : null,
                            child: (profile.imagePath == null || !profile.imagePath!.startsWith('http'))
                                ? const Icon(Icons.person, size: 40, color: Colors.grey)
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                _drawerSection(context, 'Academic & Career'),
                _drawerItem(context, Icons.assignment_outlined, 'Results', const ResultsScreen()),
                _drawerItem(context, Icons.work_outline, 'Job Board', const JobsScreen()),
                _drawerItem(context, Icons.folder_copy_outlined, 'Previous Resources', const YearsScreen()),
                
                const Divider(),
                _drawerSection(context, 'Department & People'),
                _drawerItem(context, Icons.contact_phone_outlined, 'Teacher Contacts', const TeacherContactsScreen()),
                _drawerItem(context, Icons.people_outline, 'Club Members', const ClubMembersScreen()),
                _drawerItem(context, Icons.school_outlined, 'Alumni', const AlumniScreen()),
                
                const Divider(),
                _drawerSection(context, 'Media & Tools'),
                _drawerItem(context, Icons.photo_library_outlined, 'Gallery', const GalleryScreen()),
                _drawerItem(context, Icons.calculate_outlined, 'CGPA Calculator', const CGPACalculatorScreen()),
                
                const Divider(),
                _drawerSection(context, 'Abouts'),
                _drawerItem(context, Icons.account_balance_outlined, 'CSE Department Info', const DepartmentScreen()),
                _drawerItem(context, Icons.code, 'Programming Club', const ClubScreen()),
                _drawerItem(context, Icons.group_work_outlined, 'Contributors', const ContributorsScreen()),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await AuthService.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _drawerSection(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, Widget destination) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      dense: true,
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      },
    );
  }
}

class _AnimatedProfileIcon extends StatefulWidget {
  final ProfileData profile;
  final ColorScheme colors;
  const _AnimatedProfileIcon({required this.profile, required this.colors});

  @override
  State<_AnimatedProfileIcon> createState() => _AnimatedProfileIconState();
}

class _AnimatedProfileIconState extends State<_AnimatedProfileIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: widget.colors.primary.withOpacity(0.2), width: 2),
        ),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: widget.colors.primaryContainer,
          backgroundImage: widget.profile.imagePath != null && widget.profile.imagePath!.startsWith('http')
              ? NetworkImage(widget.profile.imagePath!) as ImageProvider
              : null,
          child: (widget.profile.imagePath == null || !widget.profile.imagePath!.startsWith('http'))
              ? Icon(Icons.person, color: widget.colors.primary, size: 20)
              : null,
        ),
      ),
    );
  }
}