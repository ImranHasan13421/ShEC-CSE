// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:ShEC_CSE/core/services/theme_service.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import 'package:ShEC_CSE/features/dashboard/screens/home_screen.dart';
import 'package:ShEC_CSE/features/department/screens/department_screen.dart';
import 'package:ShEC_CSE/features/auth/screens/auth_animated_screen.dart';
import 'package:ShEC_CSE/backend/services/auth_service.dart';
import 'package:ShEC_CSE/features/notices/screens/notices_screen.dart';
import 'package:ShEC_CSE/features/jobs/screens/jobs_screen.dart';
import 'package:ShEC_CSE/features/contests/screens/contests_screen.dart';
import 'package:ShEC_CSE/features/messenger/screens/messenger_screen.dart';
import 'package:ShEC_CSE/backend/services/notification_service.dart';
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
import 'package:ShEC_CSE/backend/services/chat_service.dart';

import '../../../backend/services/notification_service.dart';

class HomeLayout extends StatefulWidget {
  const HomeLayout({super.key});

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _screens = [
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
    // Initialize Notification Service
    NotificationService.initialize();
    // Initialize Real-time subscriptions
    NoticeService.subscribeToNotices();
    JobService.subscribeToJobs();
    ContestService.subscribeToContests();
    ChatService.subscribeToAllMessages();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-fetch and re-subscribe to ensure we didn't miss anything while in background
      NoticeService.fetchNotices(forceRefresh: true);
      JobService.fetchJobs(forceRefresh: true);
      ContestService.fetchContestsAndCourses(forceRefresh: true);
      ChatService.fetchRooms();
    }
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
          children: _screens,
        ),
        bottomNavigationBar: ValueListenableBuilder<Map<String, int>>(
          valueListenable: NotificationService.unreadCounts,
          builder: (context, unread, _) {
            return BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() => _currentIndex = index);
                // Clear unread for the selected tab
                if (index == 1) NotificationService.clearUnread('notices');
                if (index == 2) NotificationService.clearUnread('messenger');
                if (index == 3) NotificationService.clearUnread('contests');
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: colors.primary,
              unselectedItemColor: colors.onSurface.withValues(alpha: 0.5),
              items: [
                const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Badge(
                    label: unread['notices']! > 0 ? Text('${unread['notices']}') : null,
                    isLabelVisible: unread['notices']! > 0,
                    child: const Icon(Icons.notifications),
                  ),
                  label: 'Notices',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    label: unread['messenger']! > 0 ? Text('${unread['messenger']}') : null,
                    isLabelVisible: unread['messenger']! > 0,
                    child: const Icon(Icons.message),
                  ),
                  label: 'Messenger',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    label: unread['contests']! > 0 ? Text('${unread['contests']}') : null,
                    isLabelVisible: unread['contests']! > 0,
                    child: const Icon(Icons.emoji_events),
                  ),
                  label: 'Contests',
                ),
              ],
            );
          },
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
                ValueListenableBuilder<Map<String, int>>(
                  valueListenable: NotificationService.unreadCounts,
                  builder: (context, unread, _) {
                    return _drawerItem(
                      context, 
                      Icons.work_outline, 
                      'Job Board', 
                      const JobsScreen(),
                      badgeCount: unread['jobs'] ?? 0,
                      onTap: () => NotificationService.clearUnread('jobs'),
                    );
                  }
                ),
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
                
                const Divider(),
                _drawerSection(context, 'Appearance'),
                _buildThemeSelector(context, colors),
                const SizedBox(height: 12),
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
                  MaterialPageRoute(builder: (context) => const AuthAnimatedScreen()),
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

  Widget _buildThemeSelector(BuildContext context, ColorScheme colors) {
    final themeService = ThemeService.instance;
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Theme Mode',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: AppThemeMode.values.map((mode) {
                  final isSelected = themeService.themeMode == mode;
                  IconData icon;
                  String label;
                  switch (mode) {
                    case AppThemeMode.system:
                      icon = Icons.brightness_auto_outlined;
                      label = 'System';
                      break;
                    case AppThemeMode.light:
                      icon = Icons.light_mode_outlined;
                      label = 'Light';
                      break;
                    case AppThemeMode.dark:
                      icon = Icons.dark_mode_outlined;
                      label = 'Dark';
                      break;
                    case AppThemeMode.night:
                      icon = Icons.nights_stay_outlined;
                      label = 'Night';
                      break;
                  }
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Tooltip(
                        message: label,
                        child: InkWell(
                          onTap: () => themeService.setThemeMode(mode),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            decoration: BoxDecoration(
                              color: isSelected ? colors.primary.withValues(alpha: 0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? colors.primary : colors.outline.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              icon,
                              size: 20,
                              color: isSelected ? colors.primary : colors.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Primary Color',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppColorTheme.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final colorTheme = AppColorTheme.values[index];
                    final isSelected = themeService.colorTheme == colorTheme;
                    Color color;
                    switch (colorTheme) {
                      case AppColorTheme.teal:
                        color = const Color(0xFF00ADB5);
                        break;
                      case AppColorTheme.blue:
                        color = const Color(0xFF1E88E5);
                        break;
                      case AppColorTheme.purple:
                        color = const Color(0xFF8E24AA);
                        break;
                      case AppColorTheme.green:
                        color = const Color(0xFF43A047);
                        break;
                      case AppColorTheme.amber:
                        color = const Color(0xFFFFB300);
                        break;
                      case AppColorTheme.crimson:
                        color = const Color(0xFFE53935);
                        break;
                    }
                    return GestureDetector(
                      onTap: () => themeService.setColorTheme(colorTheme),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? colors.onSurface : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _drawerItem(BuildContext context, IconData icon, String title, Widget destination, {int badgeCount = 0, VoidCallback? onTap}) {
    return ListTile(
      leading: badgeCount > 0 
          ? Badge(label: Text('$badgeCount'), child: Icon(icon, size: 22))
          : Icon(icon, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      dense: true,
      onTap: () {
        Navigator.pop(context);
        if (onTap != null) onTap();
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