// lib/screens/main_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/profile_state.dart';
import 'home_screen.dart';
import 'department_screen.dart';
import 'login_screen.dart';
import 'notices_screen.dart';
import 'jobs_screen.dart';
import 'contests_screen.dart';
import 'messenger_screen.dart';
import 'club_screen.dart';
import 'gallery_screen.dart';
import 'profile_screen.dart';
import 'cgpa_calculator_screen.dart';
import 'resources_screen.dart';

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
      const JobsScreen(),
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
              Image.asset('assets/logo.png', height: 28, width: 28),
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
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white24,
                      backgroundImage: profile.imagePath != null ? FileImage(File(profile.imagePath!)) : null,
                      child: profile.imagePath == null ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
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
            BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
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
      case 3: return 'Job Board';
      case 4: return 'Contests';
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
                accountEmail: Text(profile.email),
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
          ListTile(
            leading: const Icon(Icons.folder_copy),
            title: const Text('Previous Resources'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const YearsScreen()));
            },
          ),
          const Divider(), // Existing divider before Log Out
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}