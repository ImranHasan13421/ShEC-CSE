//lib/screens/main_screen.dart/
import 'package:ShEC_CSE/screens/gallery_screen.dart';
import 'package:ShEC_CSE/screens/messenger_screen.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'department_screen.dart';
import 'login_screen.dart';
import 'notices_screen.dart';
import 'jobs_screen.dart';
import 'contests_screen.dart';
import 'messenger_screen.dart';
import 'club_screen.dart';
import 'gallery_screen.dart';

class HomeLayout extends StatefulWidget {
  const HomeLayout({super.key});

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> {
  int _currentIndex = 0;

  // Bottom Nav Screens
  List<Widget> _getScreens() {
    return [
      DashboardScreen(
        onNavigateToTab: (index) {
          setState(() {
            _currentIndex = index; // Switches the tab when called from Home
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

    return Scaffold(
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
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () {}),
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
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: colors.primary,
              // Optional: Add a subtle background pattern or gradient here later
            ),
            accountName: const Text('Imran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: const Text('Member | CSE Dept'),
            currentAccountPicture: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const CircleAvatar(
                backgroundColor: Colors.white,
                // Replace this icon with a NetworkImage when you link Supabase profiles!
                child: Icon(Icons.person, size: 40, color: Colors.grey),
              ),
            ),
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