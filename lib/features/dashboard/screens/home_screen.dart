// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:ShEC_CSE/features/dashboard/models/quick_access_state.dart';
import 'package:ShEC_CSE/features/cgpa_calculator/screens/cgpa_calculator_screen.dart';
import 'package:ShEC_CSE/features/resources/screens/resources_screen.dart';
import 'package:ShEC_CSE/features/department/screens/department_screen.dart';
import 'package:ShEC_CSE/features/club/screens/club_screen.dart';
import 'package:ShEC_CSE/features/gallery/models/gallery_state.dart';
import 'package:ShEC_CSE/backend/services/gallery_service.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const DashboardScreen({super.key, this.onNavigateToTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  Timer? _carouselTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    GalleryService.fetchGalleryItems();
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
      if (_pageController.hasClients && galleryState.value.where((item) => item.isApproved).isNotEmpty) {
        final itemCount = galleryState.value.where((item) => item.isApproved).length;
        if (_currentPage < itemCount - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  // --- Central Routing Engine for Shortcuts ---
  void _executeShortcut(BuildContext context, String id) {
    switch (id) {
      case 'tab_notices': widget.onNavigateToTab?.call(1); break;
      case 'tab_messenger': widget.onNavigateToTab?.call(2); break;
      case 'tab_jobs': widget.onNavigateToTab?.call(3); break;
      case 'tab_contests': widget.onNavigateToTab?.call(4); break;
      case 'cgpa_calc': Navigator.push(context, MaterialPageRoute(builder: (_) => const CGPACalculatorScreen())); break;
      case 'res_main': Navigator.push(context, MaterialPageRoute(builder: (_) => const YearsScreen())); break;
      case 'dept_info': Navigator.push(context, MaterialPageRoute(builder: (_) => const DepartmentScreen())); break;
      case 'prog_club': Navigator.push(context, MaterialPageRoute(builder: (_) => const ClubScreen())); break;

    // DEEP LINK: Direct to 3rd Year, Semester 1, Session 20-21
      case 'res_3_1_20':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PdfsScreen(title: 'Session 20-21 Resources', color: Colors.teal, session: '',)));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('Welcome Back!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Stay updated with departmental & club activities.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
        const SizedBox(height: 24),

        // --- ANIMATED GALLERY CAROUSEL ---
        ValueListenableBuilder<List<GalleryItem>>(
          valueListenable: galleryState,
          builder: (context, items, _) {
            final approvedItems = items.where((item) => item.isApproved).take(5).toList();
            if (approvedItems.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Gallery Highlights', () {}),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemCount: approvedItems.length,
                    itemBuilder: (context, index) {
                      return _buildCarouselItem(approvedItems[index], index);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),

        // --- EDITABLE QUICK ACCESS SECTION ---
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

        // Dynamically build the shortcut grid
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
              spacing: 16, // Horizontal spacing
              runSpacing: 16, // Vertical spacing
              alignment: WrapAlignment.start,
              children: shortcuts.map((shortcut) {
                // Determine width so 4 items fit nicely, and the 5th wraps below
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 32 - (16 * 3)) / 4, // screen width - padding - spacing
                  child: _buildQuickAccessIcon(context, shortcut.icon, shortcut.title, shortcut.color, () => _executeShortcut(context, shortcut.id)),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 32),

        _buildSectionHeader('Latest Notices', () => widget.onNavigateToTab?.call(1)),
        _buildListCard(context, icon: Icons.lightbulb, iconColor: Colors.blue, title: 'Workshop on Machine Learning Basics', subtitle: 'Join us for an introductory workshop on ML fundamentals.', tag: 'Workshop', date: 'May 15, 2026'),
        _buildListCard(context, icon: Icons.code, iconColor: Colors.blueAccent, title: 'Hackathon Registration Open', subtitle: 'Annual coding hackathon registration is now open.', tag: 'Event', date: 'May 20, 2026'),

        const SizedBox(height: 24),
        _buildSectionHeader('Upcoming Contests', () => widget.onNavigateToTab?.call(4)),
        _buildListCard(context, icon: Icons.emoji_events, iconColor: Colors.orange, title: 'Codeforces Round #892', subtitle: 'Div. 2 competitive programming contest.', tag: 'Contest', date: 'Tomorrow'),
      ],
    );
  }

  // --- THE EDIT BOTTOM SHEET ---
  void _showEditQuickAccessSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows sheet to take up more screen space
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder( // StatefulBuilder allows the bottom sheet to update its UI without rebuilding the whole screen
            builder: (BuildContext context, StateSetter setModalState) {
              final colors = Theme.of(context).colorScheme;

              void toggleShortcut(ShortcutItem item) {
                setModalState(() {
                  if (activeShortcuts.value.contains(item)) {
                    // Remove it
                    activeShortcuts.value = List.from(activeShortcuts.value)..remove(item);
                  } else {
                    // Add it (if under limit)
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
                height: MediaQuery.of(context).size.height * 0.8, // Take 80% of screen height
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
                    // List of available shortcuts
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

                    // Done Button
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
        return Center(
          child: SizedBox(
            height: Curves.easeOut.transform(value) * 200,
            width: Curves.easeOut.transform(value) * 350,
            child: child,
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
            onError: (_, __) => const AssetImage('assets/gallery/placeholder.jpg'), // fallback
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
                item.subtitle,
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

  Widget _buildListCard(BuildContext context, {required IconData icon, required Color iconColor, required String title, required String subtitle, required String tag, required String date}) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: colors.outline.withOpacity(0.1))),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(backgroundColor: iconColor.withOpacity(0.1), child: Icon(icon, color: iconColor)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: colors.onSurface.withOpacity(0.6))),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: colors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(tag, style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.bold))),
                const Spacer(),
                Text(date, style: TextStyle(color: colors.onSurface.withOpacity(0.5), fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }
}