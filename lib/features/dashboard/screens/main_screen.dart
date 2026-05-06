// lib/features/dashboard/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:hidden_drawer_menu/hidden_drawer_menu.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:ShEC_CSE/core/services/theme_service.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import 'package:ShEC_CSE/features/dashboard/screens/home_screen.dart';
import 'package:ShEC_CSE/features/department/screens/department_screen.dart';
import 'package:ShEC_CSE/features/auth/screens/auth_animated_screen.dart';
import 'package:ShEC_CSE/backend/services/auth_service.dart';
import 'package:ShEC_CSE/backend/services/update_service.dart';
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
    // Check for App Updates
    UpdateService.instance.checkForUpdates();
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

  String _getAppBarTitle(int index) {
    switch (index) {
      case 1:
        return 'Notices';
      case 2:
        return 'Messenger';
      case 3:
        return 'Contests';
      default:
        return 'ShEC CSE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SimpleHiddenDrawer(
      menu: _MainDrawerMenu(colors: colors),
      screenSelectedBuilder: (position, controller) {
        return PopScope(
          canPop: _currentIndex == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            setState(() => _currentIndex = 0);
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => controller.toggle(),
              ),
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
            body: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  )
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ValueListenableBuilder<Map<String, int>>(
                    valueListenable: NotificationService.unreadCounts,
                    builder: (context, unread, _) {
                      return GNav(
                        rippleColor: colors.primary.withValues(alpha: 0.1),
                        hoverColor: colors.primary.withValues(alpha: 0.05),
                        gap: 8,
                        activeColor: colors.primary,
                        iconSize: 22,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        duration: const Duration(milliseconds: 300),
                        tabBackgroundColor: colors.primary.withValues(alpha: 0.1),
                        color: colors.onSurface.withValues(alpha: 0.6),
                        tabs: [
                          const GButton(
                            icon: Icons.home,
                            text: 'Home',
                          ),
                          GButton(
                            icon: Icons.notifications,
                            text: 'Notices',
                            leading: Badge(
                              label: unread['notices']! > 0 ? Text('${unread['notices']}') : null,
                              isLabelVisible: unread['notices']! > 0,
                              child: Icon(
                                Icons.notifications,
                                color: _currentIndex == 1 ? colors.primary : colors.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          GButton(
                            icon: Icons.message,
                            text: 'Messenger',
                            leading: Badge(
                              label: unread['messenger']! > 0 ? Text('${unread['messenger']}') : null,
                              isLabelVisible: unread['messenger']! > 0,
                              child: Icon(
                                Icons.message,
                                color: _currentIndex == 2 ? colors.primary : colors.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          GButton(
                            icon: Icons.emoji_events,
                            text: 'Contests',
                            leading: Badge(
                              label: unread['contests']! > 0 ? Text('${unread['contests']}') : null,
                              isLabelVisible: unread['contests']! > 0,
                              child: Icon(
                                Icons.emoji_events,
                                color: _currentIndex == 3 ? colors.primary : colors.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                        selectedIndex: _currentIndex,
                        onTabChange: (index) {
                          setState(() => _currentIndex = index);
                          if (index == 1) NotificationService.clearUnread('notices');
                          if (index == 2) NotificationService.clearUnread('messenger');
                          if (index == 3) NotificationService.clearUnread('contests');
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
      slidePercent: 60.0,
      verticalScalePercent: 90.0,
      contentCornerRadius: 24.0,
      enableCornerAnimation: true,
    );
  }
}

class _MainDrawerMenu extends StatelessWidget {
  final ColorScheme colors;

  const _MainDrawerMenu({required this.colors});

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService.instance;
    final isNight = themeService.themeMode == AppThemeMode.night;
    final controller = SimpleHiddenDrawerController.of(context);

    final bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isNight
          ? [const Color(0xFF0D0E10), const Color(0xFF15161A)]
          : themeService.themeMode == AppThemeMode.dark
              ? [const Color(0xFF1F2128), const Color(0xFF181A20)]
              : [
                  colors.primary.withValues(alpha: 0.08),
                  colors.surface,
                ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.55,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _menuSectionHeader('Academic & Career'),
                      _menuItem(
                        context,
                        controller,
                        icon: Icons.assignment_outlined,
                        title: 'Results',
                        destination: const ResultsScreen(),
                      ),
                      ValueListenableBuilder<Map<String, int>>(
                        valueListenable: NotificationService.unreadCounts,
                        builder: (context, unread, _) {
                          final count = unread['jobs'] ?? 0;
                          return _menuItem(
                            context,
                            controller,
                            icon: Icons.work_outline,
                            title: 'Job Board',
                            destination: const JobsScreen(),
                            badgeCount: count,
                            onTap: () => NotificationService.clearUnread('jobs'),
                          );
                        },
                      ),
                      _menuItem(
                        context,
                        controller,
                        icon: Icons.folder_copy_outlined,
                        title: 'Previous Resources',
                        destination: const YearsScreen(),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(color: Colors.grey, thickness: 0.1),
                      ),
                      _menuSectionHeader('Department & People'),
                      _menuItem(
                        context,
                        controller,
                        icon: Icons.contact_phone_outlined,
                        title: 'Teacher Contacts',
                        destination: const TeacherContactsScreen(),
                      ),
                      _menuItem(
                        context,
                        controller,
                        icon: Icons.people_outline,
                        title: 'Club Members',
                        destination: const ClubMembersScreen(),
                      ),
                      _menuItem(
                        context,
                        controller,
                        icon: Icons.school_outlined,
                        title: 'Alumni',
                        destination: const AlumniScreen(),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(color: Colors.grey, thickness: 0.1),
                      ),
                      _menuSectionHeader('Media & Tools'),
                      _menuItem(
                        context,
                        controller,
                        icon: Icons.photo_library_outlined,
                        title: 'Gallery',
                        destination: const GalleryScreen(),
                      ),
                      _menuItem(
                        context,
                        controller,
                        icon: Icons.calculate_outlined,
                        title: 'CGPA Calculator',
                        destination: const CGPACalculatorScreen(),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(color: Colors.grey, thickness: 0.1),
                      ),
                      _menuSectionHeader('Abouts'),
                      _menuItem(
                        context,
                        controller,
                        icon: Icons.account_balance_outlined,
                        title: 'CSE Department Info',
                        destination: const DepartmentScreen(),
                      ),
                      _menuItem(
                        context,
                        controller,
                        icon: Icons.code,
                        title: 'Programming Club',
                        destination: const ClubScreen(),
                      ),
                      _menuItem(
                        context,
                        controller,
                        icon: Icons.group_work_outlined,
                        title: 'Contributors',
                        destination: const ContributorsScreen(),
                      ),
                      ListenableBuilder(
                        listenable: UpdateService.instance,
                        builder: (context, _) {
                          final hasUpdate = UpdateService.instance.hasUpdate;
                          return _menuItem(
                            context,
                            controller,
                            icon: Icons.system_update_outlined,
                            title: 'App Update',
                            badgeCount: hasUpdate ? -1 : 0,
                            onTap: () {
                              _showUpdateDialog(context);
                            },
                          );
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(color: Colors.grey, thickness: 0.1),
                      ),
                      _menuSectionHeader('Appearance'),
                      _buildThemeSelectorInsideMenu(context),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: InkWell(
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
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.redAccent.withValues(alpha: 0.05),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout, color: Colors.redAccent, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Log Out',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final controller = SimpleHiddenDrawerController.of(context);
    return ValueListenableBuilder<ProfileData>(
      valueListenable: currentProfile,
      builder: (context, profile, _) {
        return InkWell(
          onTap: () {
            controller.toggle();
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          },
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: colors.surfaceContainer,
                    backgroundImage: profile.imagePath != null && profile.imagePath!.startsWith('http')
                        ? NetworkImage(profile.imagePath!) as ImageProvider
                        : null,
                    child: (profile.imagePath == null || !profile.imagePath!.startsWith('http'))
                        ? Icon(Icons.person, size: 30, color: colors.primary)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.designation,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        profile.email,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurface.withValues(alpha: 0.45),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 12.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: colors.primary.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    SimpleHiddenDrawerController controller, {
    required IconData icon,
    required String title,
    Widget? destination,
    int badgeCount = 0,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: () {
        controller.toggle();
        if (onTap != null) onTap();
        if (destination != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (badgeCount != 0)
              Badge(
                label: badgeCount > 0 ? Text('$badgeCount') : null,
                child: Icon(icon, color: colors.onSurface.withValues(alpha: 0.7), size: 22),
              )
            else
              Icon(icon, color: colors.onSurface.withValues(alpha: 0.7), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface.withValues(alpha: 0.85),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: colors.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelectorInsideMenu(BuildContext context) {
    final themeService = ThemeService.instance;
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Theme Mode',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  Row(
                    children: [
                      _buildThemeModeButton(context, themeService, AppThemeMode.system, 'System', Icons.brightness_auto_outlined),
                      const SizedBox(width: 8),
                      _buildThemeModeButton(context, themeService, AppThemeMode.light, 'Light', Icons.light_mode_outlined),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildThemeModeButton(context, themeService, AppThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
                      const SizedBox(width: 8),
                      _buildThemeModeButton(context, themeService, AppThemeMode.night, 'Night', Icons.nights_stay_outlined),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Color Scheme',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppColorTheme.values.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 6),
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
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
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

  Widget _buildThemeModeButton(
    BuildContext context,
    ThemeService themeService,
    AppThemeMode mode,
    String label,
    IconData icon,
  ) {
    final isSelected = themeService.themeMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => themeService.setThemeMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : colors.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : colors.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : colors.onSurface.withValues(alpha: 0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateDialog(BuildContext parentContext) {
    final colors = Theme.of(parentContext).colorScheme;
    final updateService = UpdateService.instance;

    showDialog(
      context: parentContext,
      barrierDismissible: true,
      builder: (dialogContext) {
        final versionController = TextEditingController(text: '1.0.1');
        final buildController = TextEditingController(text: '${UpdateService.currentBuildNumber + 1}');
        final urlController = TextEditingController();
        final notesController = TextEditingController();
        bool isPublishTab = false;
        bool isActionLoading = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isSuperUser = currentProfile.value.role == UserRole.superUser;

            return Dialog(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.system_update_outlined, color: colors.primary, size: 24),
                          const SizedBox(width: 10),
                          const Text(
                            'App Update',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(thickness: 0.5),
                      const SizedBox(height: 10),

                      if (isSuperUser) ...[
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setDialogState(() => isPublishTab = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: !isPublishTab ? colors.primary : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Check Update',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: !isPublishTab ? colors.primary : colors.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () => setDialogState(() => isPublishTab = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: isPublishTab ? colors.primary : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Publish Update',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isPublishTab ? colors.primary : colors.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                      ],

                      if (isPublishTab && isSuperUser) ...[
                        _buildInputField(colors, 'Version Name', versionController, 'e.g. 1.0.1'),
                        const SizedBox(height: 10),
                        _buildInputField(colors, 'Build Number', buildController, 'e.g. 2', isNumber: true),
                        const SizedBox(height: 10),
                        _buildInputField(colors, 'APK Download URL', urlController, 'e.g. https://...'),
                        const SizedBox(height: 10),
                        _buildInputField(colors, 'Release Notes', notesController, 'What\'s new in this build...', maxLines: 3),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: isActionLoading
                              ? null
                              : () async {
                                  final version = versionController.text.trim();
                                  final buildStr = buildController.text.trim();
                                  final url = urlController.text.trim();
                                  final notes = notesController.text.trim();

                                  if (version.isEmpty || buildStr.isEmpty || url.isEmpty) {
                                    ScaffoldMessenger.of(parentContext).showSnackBar(
                                      const SnackBar(content: Text('Please fill out all required fields.')),
                                    );
                                    return;
                                  }

                                  final buildNum = int.tryParse(buildStr);
                                  if (buildNum == null) {
                                    ScaffoldMessenger.of(parentContext).showSnackBar(
                                      const SnackBar(content: Text('Build number must be a valid integer.')),
                                    );
                                    return;
                                  }

                                  setDialogState(() => isActionLoading = true);
                                  try {
                                    await updateService.uploadNewVersion(
                                      version: version,
                                      buildNumber: buildNum,
                                      downloadUrl: url,
                                      releaseNotes: notes,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(parentContext).showSnackBar(
                                        const SnackBar(content: Text('New version published successfully!')),
                                      );
                                      Navigator.pop(context);
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(parentContext).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  } finally {
                                    setDialogState(() => isActionLoading = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 45),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: isActionLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Publish Build', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ] else ...[
                        ListenableBuilder(
                          listenable: updateService,
                          builder: (context, _) {
                            final hasUpdate = updateService.hasUpdate;
                            final isLoading = updateService.isLoading;

                            if (isLoading) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (hasUpdate) {
                              return Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.stars, color: colors.primary, size: 28),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'New Version Available!',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: colors.primary,
                                                ),
                                              ),
                                              Text(
                                                'Version ${updateService.latestVersion} (Build ${updateService.latestBuildNumber})',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  if (updateService.releaseNotes.isNotEmpty) ...[
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Release Notes:',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: colors.onSurface.withValues(alpha: 0.03),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      constraints: const BoxConstraints(maxHeight: 120),
                                      child: SingleChildScrollView(
                                        child: Text(
                                          updateService.releaseNotes,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colors.onSurface.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        await updateService.triggerUpdate();
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(parentContext).showSnackBar(
                                            SnackBar(content: Text('Error: $e')),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.download, size: 18),
                                    label: const Text('Download & Install Now', style: TextStyle(fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(double.infinity, 45),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 2,
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.green.withValues(alpha: 0.1),
                                        ),
                                        child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
                                      ),
                                      const SizedBox(height: 15),
                                      const Text(
                                        'You are on the latest version!',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Current Version: v${UpdateService.currentVersion} (${UpdateService.currentBuildNumber})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colors.onSurface.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await updateService.checkForUpdates();
                                  },
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Check for Updates'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colors.primary,
                                    side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
                                    minimumSize: const Size(double.infinity, 40),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputField(
    ColorScheme colors,
    String label,
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: colors.onSurface.withValues(alpha: 0.35)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: colors.onSurface.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.onSurface.withValues(alpha: 0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.onSurface.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
          ),
        ),
      ],
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
          border: Border.all(color: widget.colors.primary.withValues(alpha: 0.2), width: 2),
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