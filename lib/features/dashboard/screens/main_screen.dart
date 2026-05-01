// lib/screens/main_screen.dart
import 'dart:io';
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
import 'package:ShEC_CSE/features/about/screens/about_us_screen.dart';
import 'package:ShEC_CSE/features/about/screens/contributors_screen.dart';

class HomeLayout extends StatefulWidget {
  const HomeLayout({super.key});

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> {
  int _currentIndex = 0;

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

    // --- Added PopScope here ---
    return PopScope(
      canPop: _currentIndex == 0, // Only allow popping (exiting app) if on the Home tab
      onPopInvoked: (didPop) {
        if (didPop) {
          return; // The app successfully exited, do nothing
        }
        // If canPop was false (we are on another tab), switch back to the Home tab
        setState(() {
          _currentIndex = 0;
        });
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
            // Dynamic Profile Icon in AppBar
            ValueListenableBuilder<ProfileData>(
              valueListenable: currentProfile,
              builder: (context, profile, _) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                    },
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.0),
                      duration: const Duration(seconds: 1),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) {
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: colors.primaryContainer,
                        backgroundImage: profile.imagePath != null ? FileImage(File(profile.imagePath!)) : null,
                        child: profile.imagePath == null ? Icon(Icons.person, color: colors.primary, size: 20) : null,
                      ),
                    ),
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
          unselectedItemColor: colors.onSurface.withOpacity(0.5),
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
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Dynamic Drawer Header
          ValueListenableBuilder<ProfileData>(
            valueListenable: currentProfile,
            builder: (context, profile, _) {
              return UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: colors.primary),
                accountName: Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                accountEmail: Text('${profile.designation} • ${profile.email}'),
                currentAccountPicture: GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Close Drawer
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      backgroundImage: profile.imagePath != null ? FileImage(File(profile.imagePath!)) : null,
                      child: profile.imagePath == null ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
                    ),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('CSE Department Info'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DepartmentScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Programming Club'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ClubScreen()));
            },
          ),
          
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Academic & Career', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Results'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.work),
            title: const Text('Job Board'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const JobsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_copy),
            title: const Text('Previous Resources'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const YearsScreen()));
            },
          ),

          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Department & People', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.contact_phone),
            title: const Text('Teacher Contacts'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherContactsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Club Members'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ClubMembersScreen()));
            },
          ),

          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Media & Tools', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Gallery'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GalleryScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.calculate),
            title: const Text('CGPA Calculator'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CGPACalculatorScreen()));
            },
          ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About Us'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutUsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.group_work),
            title: const Text('Contributors'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ContributorsScreen()));
            },
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
        ],
      ),
    );
  }
}