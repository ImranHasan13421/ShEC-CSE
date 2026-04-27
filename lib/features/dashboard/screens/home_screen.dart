// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:ShEC_CSE/features/dashboard/models/quick_access_state.dart';
import 'package:ShEC_CSE/features/cgpa_calculator/screens/cgpa_calculator_screen.dart';
import 'package:ShEC_CSE/features/resources/screens/resources_screen.dart';
import 'package:ShEC_CSE/features/department/screens/department_screen.dart';
import 'package:ShEC_CSE/features/club/screens/club_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int)? onNavigateToTab;

  const DashboardScreen({super.key, this.onNavigateToTab});

  // --- Central Routing Engine for Shortcuts ---
  void _executeShortcut(BuildContext context, String id) {
    switch (id) {
      case 'tab_notices': onNavigateToTab?.call(1); break;
      case 'tab_messenger': onNavigateToTab?.call(2); break;
      case 'tab_jobs': onNavigateToTab?.call(3); break;
      case 'tab_contests': onNavigateToTab?.call(4); break;
      case 'cgpa_calc': Navigator.push(context, MaterialPageRoute(builder: (_) => const CGPACalculatorScreen())); break;
      case 'res_main': Navigator.push(context, MaterialPageRoute(builder: (_) => const YearsScreen())); break;
      case 'dept_info': Navigator.push(context, MaterialPageRoute(builder: (_) => const DepartmentScreen())); break;
      case 'prog_club': Navigator.push(context, MaterialPageRoute(builder: (_) => const ClubScreen())); break;

    // DEEP LINK: Direct to 3rd Year, Semester 1, Session 20-21
      case 'res_3_1_20':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PdfsScreen(title: 'Session 20-21 Resources', color: Colors.teal)));
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

        _buildSectionHeader('Latest Notices', () => onNavigateToTab?.call(1)),
        _buildListCard(context, icon: Icons.lightbulb, iconColor: Colors.blue, title: 'Workshop on Machine Learning Basics', subtitle: 'Join us for an introductory workshop on ML fundamentals.', tag: 'Workshop', date: 'May 15, 2026'),
        _buildListCard(context, icon: Icons.code, iconColor: Colors.blueAccent, title: 'Hackathon Registration Open', subtitle: 'Annual coding hackathon registration is now open.', tag: 'Event', date: 'May 20, 2026'),

        const SizedBox(height: 24),
        _buildSectionHeader('Upcoming Contests', () => onNavigateToTab?.call(4)),
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

              return Container(
                height: MediaQuery.of(context).size.height * 0.7, // Take 70% of screen height
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
                    Text('Select up to 4 shortcuts for your dashboard.', style: TextStyle(color: colors.onSurface.withOpacity(0.6))),
                    const SizedBox(height: 16),

                    // List of all available shortcuts
                    Expanded(
                      child: ListView.separated(
                        itemCount: availableShortcuts.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = availableShortcuts[index];
                          final isSelected = activeShortcuts.value.contains(item);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(backgroundColor: item.color.withOpacity(0.1), child: Icon(item.icon, color: item.color, size: 20)),
                            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            trailing: Checkbox(
                              value: isSelected,
                              activeColor: colors.primary,
                              onChanged: (bool? value) => toggleShortcut(item),
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