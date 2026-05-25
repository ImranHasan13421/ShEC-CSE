import 'package:flutter/material.dart';
import 'package:ShEC_CSE/features/dashboard/models/quick_access_state.dart';
import 'package:ShEC_CSE/features/cgpa_calculator/screens/cgpa_calculator_screen.dart';
import 'package:ShEC_CSE/features/resources/screens/resources_screen.dart';
import 'package:ShEC_CSE/features/department/presentation/screens/department_screen.dart';
import 'package:ShEC_CSE/features/club/screens/club_screen.dart';
import 'package:ShEC_CSE/features/gallery/models/gallery_state.dart';
import 'package:ShEC_CSE/backend/services/gallery_service.dart';
import 'package:ShEC_CSE/backend/services/notice_service.dart';
import 'package:ShEC_CSE/backend/services/contest_service.dart';
import 'package:ShEC_CSE/features/notices/models/notice_state.dart';
import 'package:ShEC_CSE/features/contests/models/contest_state.dart';
import 'package:ShEC_CSE/features/contests/presentation/bloc/contest_bloc.dart';
import 'package:ShEC_CSE/features/contests/presentation/bloc/contest_event.dart';
import 'package:ShEC_CSE/features/contests/presentation/bloc/contest_state.dart';
import 'package:ShEC_CSE/features/gallery/screens/gallery_screen.dart';
import 'package:ShEC_CSE/features/notices/widgets/notice_card.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ShEC_CSE/features/notices/presentation/bloc/notice_bloc.dart';
import 'package:ShEC_CSE/features/notices/presentation/bloc/notice_event.dart';
import 'package:ShEC_CSE/features/notices/presentation/bloc/notice_state.dart';
import 'package:ShEC_CSE/features/gallery/presentation/bloc/gallery_bloc.dart';
import 'package:ShEC_CSE/features/gallery/presentation/bloc/gallery_event.dart';
import 'package:ShEC_CSE/features/gallery/presentation/bloc/gallery_state.dart';

import '../../jobs/screens/jobs_screen.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const DashboardScreen({super.key, this.onNavigateToTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PageController _pageController = PageController(
    initialPage: 10080,
    viewportFraction: 0.85,
  );
  int _currentPage = 10080;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    context.read<GalleryBloc>().add(const FetchGalleryItemsRequested());
    context.read<NoticeBloc>().add(const FetchNoticesRequested());
    context.read<ContestBloc>().add(const FetchContestsRequested());
    _startCarouselTimer();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      final state = context.read<GalleryBloc>().state;
      final approvedCount = state is GalleryLoaded
          ? state.items.where((item) => item.isApproved).length
          : 0;
      if (_pageController.hasClients && approvedCount > 0) {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
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
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ValueListenableBuilder<ProfileData>(
          valueListenable: currentProfile,
          builder: (context, profile, _) {
            final hour = DateTime.now().hour;
            String greeting;
            String emoji;
            if (hour >= 5 && hour < 12) {
              greeting = 'Good Morning';
              emoji = '☀️';
            } else if (hour >= 12 && hour < 17) {
              greeting = 'Good Afternoon';
              emoji = '🌤️';
            } else if (hour >= 17 && hour < 21) {
              greeting = 'Good Evening';
              emoji = '🌇';
            } else {
              greeting = 'Good Night';
              emoji = '🌙';
            }

            final name = profile.firstName.isNotEmpty
                ? profile.firstName
                : (profile.name.isNotEmpty && profile.name != 'Guest' ? profile.name : '');

            final displayStr = name.isNotEmpty ? '$greeting, $name $emoji' : '$greeting $emoji';

            return Text(
              displayStr,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            );
          },
        ),
        const SizedBox(height: 4),
        Text('Stay updated with departmental & club activities.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
        const SizedBox(height: 24),

        // --- ANIMATED GALLERY CAROUSEL ---
        BlocBuilder<GalleryBloc, GalleryState>(
          builder: (context, state) {
            final items = state is GalleryLoaded ? state.items : <GalleryItem>[];
            final approvedItems = items.where((item) => item.isApproved).take(5).toList();
            if (approvedItems.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Gallery Highlights', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GalleryScreen()))),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (page) {
                      _currentPage = page;
                    },
                    itemCount: 1000000, // Pseudo-infinite scroll space
                    itemBuilder: (context, index) {
                      final itemIndex = index % approvedItems.length;
                      return _buildCarouselItem(approvedItems[itemIndex], index);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),

        // --- QUICK ACCESS SECTION ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Quick Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => _showEditQuickAccessSheet(context),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ValueListenableBuilder<List<ShortcutItem>>(
          valueListenable: activeShortcuts,
          builder: (context, shortcuts, _) {
            if (shortcuts.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1))),
                child: const Center(child: Text('Tap Edit to add shortcuts.')),
              );
            }
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.start,
              children: shortcuts.map((shortcut) {
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 32 - (16 * 3)) / 4,
                  child: _buildQuickAccessIcon(context, shortcut.icon, shortcut.title, shortcut.color, () => _executeShortcut(context, shortcut.id)),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 32),

        _buildSectionHeader('Latest Notices', () => widget.onNavigateToTab?.call(1)),
        BlocBuilder<NoticeBloc, NoticeState>(
          builder: (context, state) {
            if (state is NoticeLoading) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final clubNotices = state is NoticesLoaded ? state.clubNotices : <NoticeItem>[];
            final deptNotices = state is NoticesLoaded ? state.deptNotices : <NoticeItem>[];
            
            // Combine, sort by pinned first, then by date (latest first)
            final allNotices = [...clubNotices, ...deptNotices];
            final filtered = allNotices.where((n) => n.isApproved && n.isVisible).toList();
            
            // Sort: Pinned first, then by createdAt descending
            filtered.sort((a, b) {
              if (a.isPinned && !b.isPinned) return -1;
              if (!a.isPinned && b.isPinned) return 1;
              
              // If both pinned or both unpinned, sort by date
              final dateA = a.createdAt ?? DateTime(2000);
              final dateB = b.createdAt ?? DateTime(2000);
              return dateB.compareTo(dateA);
            });

            final latest = filtered.take(3).toList();
            
            if (latest.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No recent notices')));
            
            return Column(
              children: latest.map((n) => NoticeCard(notice: n)).toList(),
            );
          },
        ),

        const SizedBox(height: 24),
        _buildSectionHeader('Upcoming Contests', () => widget.onNavigateToTab?.call(3)),
        BlocBuilder<ContestBloc, ContestState>(
          builder: (context, state) {
            if (state is ContestLoading) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (state is ContestLoaded) {
              final latest = state.items.where((c) => c.isApproved && c.isVisible).take(2).toList();
              if (latest.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No upcoming contests')));
              return Column(
                children: latest.map((c) => _buildListCard(
                  context, 
                  icon: Icons.emoji_events, 
                  iconColor: Colors.orange, 
                  title: c.title, 
                  subtitle: '${c.platform} | Level/Div: ${c.level}', 
                  tag: 'Contest', 
                  date: c.date,
                  onTap: () => widget.onNavigateToTab?.call(3),
                )).toList(),
              );
            }
            return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No upcoming contests')));
          },
        ),
      ],
    );
  }

  void _showEditQuickAccessSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              final colors = Theme.of(context).colorScheme;

              void toggleShortcut(ShortcutItem item) {
                setModalState(() {
                  if (activeShortcuts.value.contains(item)) {
                    activeShortcuts.value = List.from(activeShortcuts.value)..remove(item);
                  } else {
                    if (activeShortcuts.value.length < 4) {
                      activeShortcuts.value = List.from(activeShortcuts.value)..add(item);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 4 shortcuts allowed!')));
                    }
                  }
                });
              }

              final unselectedShortcuts = availableShortcuts.where((item) => !activeShortcuts.value.contains(item)).toList();

              return Container(
                height: MediaQuery.of(context).size.height * 0.8,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: colors.onSurface.withOpacity(0.2), borderRadius: BorderRadius.circular(2)))),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Edit Quick Access', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('${activeShortcuts.value.length}/4', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Select and drag up to 4 shortcuts for your dashboard.', style: TextStyle(color: colors.onSurface.withOpacity(0.6))),
                    const SizedBox(height: 16),

                    if (activeShortcuts.value.isNotEmpty) ...[
                      const Text('Active Shortcuts (Drag to reorder)', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        onReorder: (oldIndex, newIndex) {
                          setModalState(() {
                            if (oldIndex < newIndex) {
                              newIndex -= 1;
                            }
                            final item = activeShortcuts.value.removeAt(oldIndex);
                            activeShortcuts.value.insert(newIndex, item);
                            activeShortcuts.value = List.from(activeShortcuts.value);
                          });
                        },
                        children: activeShortcuts.value.map((item) {
                          return ListTile(
                            key: ValueKey('active_${item.id}'),
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(backgroundColor: item.color.withOpacity(0.1), child: Icon(item.icon, color: item.color, size: 20)),
                            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                                  onPressed: () => toggleShortcut(item),
                                ),
                                const Icon(Icons.drag_handle, color: Colors.grey),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const Divider(height: 32),
                    ],

                    const Text('Available Shortcuts', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: unselectedShortcuts.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = unselectedShortcuts[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(backgroundColor: item.color.withOpacity(0.1), child: Icon(item.icon, color: item.color, size: 20)),
                            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.green),
                              onPressed: () => toggleShortcut(item),
                            ),
                            onTap: () => toggleShortcut(item),
                          );
                        },
                      ),
                    ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Save & Close', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            }
        );
      },
    );
  }

  Widget _buildQuickAccessIcon(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.1)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(onPressed: onViewAll, child: const Text('View All')),
      ],
    );
  }

  Widget _buildCarouselItem(GalleryItem item, int index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.position.haveDimensions) {
          value = _pageController.page! - index;
          value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
        }
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GalleryScreen())),
          child: Center(
            child: SizedBox(
              height: Curves.easeOut.transform(value) * 200,
              width: Curves.easeOut.transform(value) * 350,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(item.imagePath),
            fit: BoxFit.cover,
            onError: (_, __) => const AssetImage('assets/gallery/placeholder.jpg'), 
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Colors.transparent, Colors.black87],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.5, 1.0],
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                item.description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
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

  Widget _buildListCard(BuildContext context, {required IconData icon, required Color iconColor, required String title, required String subtitle, required String tag, required String date, required VoidCallback onTap}) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: colors.outline.withOpacity(0.1))),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: colors.secondaryContainer, borderRadius: BorderRadius.circular(4)),
                          child: Text(tag, style: TextStyle(fontSize: 10, color: colors.onSecondaryContainer, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Text(date, style: TextStyle(fontSize: 10, color: colors.onSurface.withOpacity(0.5))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: colors.onSurface.withOpacity(0.6)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurface.withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }
}