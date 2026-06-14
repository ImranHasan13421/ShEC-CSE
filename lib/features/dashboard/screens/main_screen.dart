import 'package:flutter/material.dart';
import 'package:hidden_drawer_menu/hidden_drawer_menu.dart';
import 'package:ShEC_CSE/features/dashboard/screens/home_screen.dart';
import 'package:ShEC_CSE/backend/services/update_service.dart';
import 'package:ShEC_CSE/features/notices/screens/notices_screen.dart';
import 'package:ShEC_CSE/features/messenger/screens/messenger_screen.dart';
import 'package:ShEC_CSE/features/contests/screens/contests_screen.dart';
import 'package:ShEC_CSE/backend/services/notification_service.dart';
import 'package:ShEC_CSE/features/profile/presentation/screens/profile_screen.dart';
import 'package:ShEC_CSE/backend/services/notice_service.dart';
import 'package:ShEC_CSE/backend/services/job_service.dart';
import 'package:ShEC_CSE/backend/services/contest_service.dart';
import 'package:ShEC_CSE/backend/services/chat_service.dart';
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/main_drawer_menu.dart';
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/ambient_background.dart';
import 'package:ShEC_CSE/core/services/tour_service.dart';
import 'main/widgets/main_navigation_bar.dart';
import 'main/widgets/main_app_bar.dart';
import 'main/widgets/onboarding_tour.dart';

class HomeLayout extends StatefulWidget {
  static final ValueNotifier<int> activeTab = ValueNotifier<int>(0);

  const HomeLayout({super.key});

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late List<Widget> _screens;
  bool _isUpdateDialogShowing = false;

  // Keys for Guided Onboarding Spotlight Tour
  final GlobalKey _drawerKey = GlobalKey();
  final GlobalKey _profileKey = GlobalKey();
  final GlobalKey _noticesTabKey = GlobalKey();
  final GlobalKey _messengerTabKey = GlobalKey();
  final GlobalKey _contestsTabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HomeLayout.activeTab.addListener(_handleTabChange);
    _currentIndex = HomeLayout.activeTab.value;

    _screens = [
      DashboardScreen(
        onNavigateToTab: (index) {
          HomeLayout.activeTab.value = index;
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

    // Check & Subscribe for App Updates
    UpdateService.instance.subscribeToUpdates();
    UpdateService.instance.addListener(_handleUpdateStatus);
    UpdateService.instance.checkForUpdates();

    // Initialize Tour Service and auto-trigger on first app launch
    TourService.instance.init().then((_) {
      if (!TourService.instance.hasCompletedTour) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              TourService.instance.startTour();
            }
          });
        });
      }
    });
  }

  void _handleTabChange() {
    if (mounted) {
      setState(() {
        _currentIndex = HomeLayout.activeTab.value;
      });
    }
  }

  void _handleUpdateStatus() {
    if (UpdateService.instance.hasUpdate && UpdateService.instance.isMajor) {
      if (!_isUpdateDialogShowing) {
        setState(() {
          _isUpdateDialogShowing = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            MainDrawerMenu.showUpdateDialog(context, force: true);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    HomeLayout.activeTab.removeListener(_handleTabChange);
    WidgetsBinding.instance.removeObserver(this);
    UpdateService.instance.removeListener(_handleUpdateStatus);
    UpdateService.instance.unsubscribeFromUpdates();
    // Unsubscribe from services to prevent memory leaks and duplicate notifications
    NoticeService.unsubscribeFromNotices();
    JobService.unsubscribeFromJobs();
    ContestService.unsubscribeFromContests();
    ChatService.unsubscribeFromMessages();
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

      // Force re-establish dynamic WebSocket channels to keep foreground/background switches synchronized
      NoticeService.unsubscribeFromNotices().then((_) => NoticeService.subscribeToNotices());
      JobService.unsubscribeFromJobs().then((_) => JobService.subscribeToJobs());
      ContestService.unsubscribeFromContests().then((_) => ContestService.subscribeToContests());
      ChatService.unsubscribeFromMessages().then((_) => ChatService.subscribeToAllMessages());
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
      menu: MainDrawerMenu(colors: colors),
      screenSelectedBuilder: (position, controller) {
        return PopScope(
          canPop: _currentIndex == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            setState(() => _currentIndex = 0);
          },
          child: AmbientTimeBackground(
            child: Stack(
              children: [
                Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: MainAppBar(
                    currentIndex: _currentIndex,
                    onMenuPressed: () => controller.toggle(),
                    onProfilePressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                    },
                    colors: colors,
                    drawerKey: _drawerKey,
                    profileKey: _profileKey,
                    title: _currentIndex == 0 ? 'ShEC CSE' : _getAppBarTitle(_currentIndex),
                  ),
                  body: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                  bottomNavigationBar: MainNavigationBar(
                    currentIndex: _currentIndex,
                    onTabChange: (index) {
                      HomeLayout.activeTab.value = index;
                      if (index == 1) NotificationService.clearUnread('notices');
                      if (index == 2) NotificationService.clearUnread('messenger');
                      if (index == 3) NotificationService.clearUnread('contests');
                    },
                    colors: colors,
                    noticesTabKey: _noticesTabKey,
                    messengerTabKey: _messengerTabKey,
                    contestsTabKey: _contestsTabKey,
                  ),
                ),

                // Interactive Guided Onboarding Spotlight Tour Overlay
                OnboardingTour(
                  drawerKey: _drawerKey,
                  profileKey: _profileKey,
                  noticesTabKey: _noticesTabKey,
                  messengerTabKey: _messengerTabKey,
                  contestsTabKey: _contestsTabKey,
                  onStepChanged: (stepIndex) {
                    int newIndex = 0;
                    if (stepIndex <= 2) {
                      newIndex = 0;
                    } else if (stepIndex == 3) {
                      newIndex = 1;
                    } else if (stepIndex == 4) {
                      newIndex = 2;
                    } else if (stepIndex == 5) {
                      newIndex = 3;
                    }
                    HomeLayout.activeTab.value = newIndex;
                  },
                ),
              ],
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