import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ShEC_CSE/features/dashboard/models/quick_access_state.dart';
import 'package:ShEC_CSE/features/cgpa_calculator/screens/cgpa_calculator_screen.dart';
import 'package:ShEC_CSE/features/resources/screens/resources_screen.dart';
import 'package:ShEC_CSE/features/department/screens/department_screen.dart';
import 'package:ShEC_CSE/features/club/screens/club_screen.dart';
import 'package:ShEC_CSE/features/gallery/models/gallery_state.dart';
import 'package:ShEC_CSE/backend/services/gallery_service.dart';
import 'package:ShEC_CSE/backend/services/notice_service.dart';
import 'package:ShEC_CSE/backend/services/contest_service.dart';
import 'package:ShEC_CSE/features/notices/models/notice_state.dart';
import 'package:ShEC_CSE/features/contests/models/contest_state.dart';
import 'package:ShEC_CSE/features/gallery/screens/gallery_screen.dart';
import 'package:ShEC_CSE/features/notices/widgets/notice_card.dart';
import 'package:ShEC_CSE/features/auth/screens/auth_animated_screen.dart';
import 'dart:async';

import '../../jobs/screens/jobs_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const DashboardScreen({super.key, this.onNavigateToTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  late AnimationController _backgroundController;
  late AnimationController _floatController;
  Timer? _carouselTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    GalleryService.fetchGalleryItems();
    NoticeService.fetchNotices();
    ContestService.fetchContestsAndCourses();
    _startCarouselTimer();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    _backgroundController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 6), (Timer timer) {
      if (_pageController.hasClients && galleryState.value.where((item) => item.isApproved).isNotEmpty) {
        final itemCount = galleryState.value.where((item) => item.isApproved).length;
        if (_currentPage < itemCount - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  void _executeShortcut(BuildContext context, String id) {
    switch (id) {
      case 'tab_notices': widget.onNavigateToTab?.call(1); break;
      case 'tab_messenger': widget.onNavigateToTab?.call(2); break;
      case 'tab_jobs': Navigator.push(context, MaterialPageRoute(builder: (_) => const JobsScreen())); break;
      case 'tab_contests': widget.onNavigateToTab?.call(3); break;
      case 'cgpa_calc': Navigator.push(context, MaterialPageRoute(builder: (_) => const CGPACalculatorScreen())); break;
      case 'res_main': Navigator.push(context, MaterialPageRoute(builder: (_) => const YearsScreen())); break;
      case 'dept_info': Navigator.push(context, MaterialPageRoute(builder: (_) => const DepartmentScreen())); break;
      case 'prog_club': Navigator.push(context, MaterialPageRoute(builder: (_) => const ClubScreen())); break;
      case 'res_3_1_20':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PdfsScreen(title: 'Session 20-21 Resources', color: Colors.teal, session: '20-21', semester: '1st Semester',)));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0216), 
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return CustomPaint(
                painter: CosmicPainter(_backgroundController.value),
                size: size,
              );
            },
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                ValueListenableBuilder<List<GalleryItem>>(
                  valueListenable: galleryState,
                  builder: (context, items, _) {
                    final approvedItems = items.where((item) => item.isApproved).take(5).toList();
                    if (approvedItems.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Highlights', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GalleryScreen()))),
                        const SizedBox(height: 15),
                        SizedBox(
                          height: 220,
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (int page) => setState(() => _currentPage = page),
                            itemCount: approvedItems.length,
                            itemBuilder: (context, index) => _buildParallaxGalleryItem(approvedItems[index], index),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    );
                  },
                ),
                _buildSectionHeader('Quick Actions', () => _showEditQuickAccessSheet(context)),
                const SizedBox(height: 15),
                ValueListenableBuilder<List<ShortcutItem>>(
                  valueListenable: activeShortcuts,
                  builder: (context, shortcuts, _) {
                    return Wrap(
                      spacing: 15,
                      runSpacing: 15,
                      alignment: WrapAlignment.start,
                      children: shortcuts.map((shortcut) {
                        return SizedBox(
                          width: (size.width - 40 - (15 * 3)) / 4,
                          child: _buildFloatingShortcut(context, shortcut),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 35),
                _buildSectionHeader('Latest Notices', () => widget.onNavigateToTab?.call(1)),
                const SizedBox(height: 15),
                ValueListenableBuilder<List<NoticeItem>>(
                  valueListenable: clubNoticesState,
                  builder: (context, clubNotices, _) {
                    return ValueListenableBuilder<List<NoticeItem>>(
                      valueListenable: deptNoticesState,
                      builder: (context, deptNotices, _) {
                        final allNotices = [...clubNotices, ...deptNotices];
                        final filtered = allNotices.where((n) => n.isApproved && n.isVisible).toList();
                        filtered.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
                        final latest = filtered.take(3).toList();
                        if (latest.isEmpty) return const _EmptyState(text: 'No cosmic signals yet...');
                        return Column(
                          children: latest.map((n) => _buildGlassNoticeCard(n)).toList(),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 30),
                _buildSectionHeader('Upcoming Missions', () => widget.onNavigateToTab?.call(3)),
                const SizedBox(height: 15),
                ValueListenableBuilder<List<ContestItem>>(
                  valueListenable: contestState,
                  builder: (context, contests, _) {
                    final latest = contests.where((c) => c.isApproved && c.isVisible).take(2).toList();
                    if (latest.isEmpty) return const _EmptyState(text: 'All quiet in the galaxy...');
                    return Column(
                      children: latest.map((c) => _buildGlassContestCard(c)).toList(),
                    );
                  },
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome, Explorer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.blueAccent, blurRadius: 10)],
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.notifications_none_rounded, color: Colors.blueAccent),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: const Text(
            'VIEW ALL',
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParallaxGalleryItem(GalleryItem item, int index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double pageOffset = 0;
        if (_pageController.position.haveDimensions) {
          pageOffset = _pageController.page! - index;
        }
        double scale = (1 - (pageOffset.abs() * 0.1)).clamp(0.8, 1.0);
        
        return Transform.scale(
          scale: scale,
          child: _buildGlassCard(
            padding: EdgeInsets.zero,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    item.imagePath,
                    fit: BoxFit.cover,
                    alignment: Alignment(pageOffset * 2, 0),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(item.description, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
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

  Widget _buildFloatingShortcut(BuildContext context, ShortcutItem shortcut) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final floatY = math.sin(_floatController.value * 2 * math.pi) * 5;
        return Transform.translate(
          offset: Offset(0, floatY),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => _executeShortcut(context, shortcut.id),
        child: Column(
          children: [
            _buildGlassCard(
              width: 65, height: 65,
              padding: EdgeInsets.zero,
              child: Icon(shortcut.icon, color: Colors.blueAccent, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              shortcut.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassNoticeCard(NoticeItem n) {
    return _buildGlassCard(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.campaign_outlined, color: Colors.pinkAccent),
        ),
        title: Text(n.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(n.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
        onTap: () => widget.onNavigateToTab?.call(1),
      ),
    );
  }

  Widget _buildGlassContestCard(ContestItem c) {
    return _buildGlassCard(
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.emoji_events_outlined, color: Colors.blueAccent),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('${c.platform} • ${c.date}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(c.level, style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({
    Widget? child,
    double? width,
    double? height,
    EdgeInsets? margin,
    EdgeInsets? padding,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }

  void _showEditQuickAccessSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2024),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              final unselectedShortcuts = availableShortcuts.where((item) => !activeShortcuts.value.contains(item)).toList();
              return Container(
                height: MediaQuery.of(context).size.height * 0.8,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                    const Text('RECONFIGURE SENSORS', style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    const SizedBox(height: 10),
                    const Text('Edit Quick Access', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        children: [
                          if (activeShortcuts.value.isNotEmpty) ...[
                            const Text('ACTIVE SHORTCUTS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            ...activeShortcuts.value.map((item) => ListTile(
                              leading: Icon(item.icon, color: Colors.blueAccent),
                              title: Text(item.title, style: const TextStyle(color: Colors.white)),
                              trailing: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                              onTap: () => setModalState(() => activeShortcuts.value = List.from(activeShortcuts.value)..remove(item)),
                            )),
                            const Divider(color: Colors.white10, height: 30),
                          ],
                          const Text('AVAILABLE SHORTCUTS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          ...unselectedShortcuts.map((item) => ListTile(
                            leading: Icon(item.icon, color: Colors.white24),
                            title: Text(item.title, style: const TextStyle(color: Colors.white)),
                            trailing: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
                            onTap: () {
                              if (activeShortcuts.value.length < 4) {
                                setModalState(() => activeShortcuts.value = List.from(activeShortcuts.value)..add(item));
                              }
                            },
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _GlowButton(text: 'SAVE CONFIG', onTap: () => Navigator.pop(context)),
                  ],
                ),
              );
            }
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(child: Text(text, style: const TextStyle(color: Colors.white24, fontStyle: FontStyle.italic))),
    );
  }
}

class _GlowButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _GlowButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(colors: [Color(0xFF00ADB5), Color(0xFF6C63FF)]),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
        ),
      ),
    );
  }
}