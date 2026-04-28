import 'package:flutter/material.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import '../models/notice_state.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  // --- Toggle Logic ---
  void _togglePin(NoticeItem notice, ValueNotifier<List<NoticeItem>> stateNotifier) {
    notice.isPinned = !notice.isPinned;
    // Trigger a rebuild of the list by re-assigning the value
    stateNotifier.value = List.from(stateNotifier.value);
  }

  void _deleteNotice(NoticeItem notice, ValueNotifier<List<NoticeItem>> stateNotifier) {
    stateNotifier.value = List.from(stateNotifier.value)..remove(notice);
  }

  void _showNoticeForm(BuildContext context, ValueNotifier<List<NoticeItem>> defaultStateNotifier, {NoticeItem? existingNotice}) {
    final titleController = TextEditingController(text: existingNotice?.title ?? '');
    final subtitleController = TextEditingController(text: existingNotice?.subtitle ?? '');
    
    // We'll manage state inside the StatefulBuilder for the bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Track the selected category
            ValueNotifier<List<NoticeItem>> selectedNotifier = defaultStateNotifier;
            
            // Available tags and selected tags
            final List<String> availableTags = ['Academic', 'Event', 'Workshop', 'Maintenance', 'Job', 'Lecture', 'General', 'Research'];
            List<String> selectedTags = existingNotice?.tags.toList() ?? ['General'];

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(existingNotice == null ? 'Add Notice' : 'Edit Notice', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    // Category Selection
                    if (existingNotice == null) ...[
                      const Text('Notice Category', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SegmentedButton<ValueNotifier<List<NoticeItem>>>(
                        segments: [
                          ButtonSegment(value: clubNoticesState, label: const Text('Club')),
                          ButtonSegment(value: deptNoticesState, label: const Text('Department')),
                        ],
                        selected: {selectedNotifier},
                        onSelectionChanged: (Set<ValueNotifier<List<NoticeItem>>> newSelection) {
                          setModalState(() {
                            selectedNotifier = newSelection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subtitleController,
                      decoration: const InputDecoration(labelText: 'Subtitle', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    // Tags Selection
                    const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: availableTags.map((tag) {
                        return FilterChip(
                          label: Text(tag, style: const TextStyle(fontSize: 12)),
                          selected: selectedTags.contains(tag),
                          onSelected: (bool selected) {
                            setModalState(() {
                              if (selected) {
                                if (selectedTags.contains('General') && tag != 'General') {
                                  selectedTags.remove('General');
                                }
                                selectedTags.add(tag);
                              } else {
                                selectedTags.remove(tag);
                                if (selectedTags.isEmpty) {
                                  selectedTags.add('General');
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleController.text.isNotEmpty) {
                            if (existingNotice == null) {
                              // Add new
                              final newNotice = NoticeItem(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                icon: Icons.notifications,
                                iconColor: Colors.blue,
                                title: titleController.text,
                                subtitle: subtitleController.text,
                                tags: selectedTags,
                                tagColor: Colors.blue,
                                date: 'Just now',
                              );
                              selectedNotifier.value = List.from(selectedNotifier.value)..insert(0, newNotice);
                            } else {
                              // Edit existing
                              final index = defaultStateNotifier.value.indexOf(existingNotice);
                              if (index != -1) {
                                final updatedList = List<NoticeItem>.from(defaultStateNotifier.value);
                                updatedList[index] = NoticeItem(
                                  id: existingNotice.id,
                                  icon: existingNotice.icon,
                                  iconColor: existingNotice.iconColor,
                                  title: titleController.text,
                                  subtitle: subtitleController.text,
                                  tags: selectedTags,
                                  tagColor: existingNotice.tagColor,
                                  date: existingNotice.date,
                                  isPinned: existingNotice.isPinned,
                                );
                                defaultStateNotifier.value = updatedList;
                              }
                            }
                            Navigator.pop(context);
                          }
                        },
                        child: Text(existingNotice == null ? 'Create' : 'Update'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            // 1. The TabBar
            Container(
              color: colors.primary, // Matches your original AppBar background
              child: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'Club Notices'),
                  Tab(text: 'Department Notices'),
                ],
              ),
            ),

            // 2. The Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  _buildNoticesTab(clubNoticesState),
                  _buildNoticesTab(deptNoticesState),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: ValueListenableBuilder<ProfileData>(
          valueListenable: currentProfile,
          builder: (context, profile, _) {
            if (profile.role == UserRole.committeeMember) {
              return Builder(
                builder: (context) {
                  return FloatingActionButton(
                    onPressed: () {
                      final tabIndex = DefaultTabController.of(context).index;
                      final targetState = tabIndex == 0 ? clubNoticesState : deptNoticesState;
                      _showNoticeForm(context, targetState);
                    },
                    child: const Icon(Icons.add),
                  );
                }
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildNoticesTab(ValueNotifier<List<NoticeItem>> stateNotifier) {
    return ValueListenableBuilder<List<NoticeItem>>(
      valueListenable: stateNotifier,
      builder: (context, notices, _) {
        final pinnedNotices = notices.where((n) => n.isPinned).toList();
        final unpinnedNotices = notices.where((n) => !n.isPinned).toList();

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (pinnedNotices.isNotEmpty) ...[
              _buildSectionTitle('📌 Pinned Notices'),
              ...pinnedNotices.map((notice) => _buildNoticeCard(notice, stateNotifier)),
              const SizedBox(height: 16),
            ],
            if (unpinnedNotices.isNotEmpty) ...[
              _buildSectionTitle('All Notices'),
              ...unpinnedNotices.map((notice) => _buildNoticeCard(notice, stateNotifier)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildNoticeCard(NoticeItem notice, ValueNotifier<List<NoticeItem>> stateNotifier) {
    final colors = Theme.of(context).colorScheme;

    // Pinned cards get a subtle yellowish background tint in light mode
    final backgroundColor = notice.isPinned
        ? (Theme.of(context).brightness == Brightness.light ? Colors.amber.shade50 : colors.surfaceContainerHighest)
        : colors.surface;

    final borderColor = notice.isPinned ? Colors.amber.withOpacity(0.5) : colors.outline.withOpacity(0.1);

    return Card(
      key: ValueKey(notice.id),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: notice.isPinned ? 1.5 : 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: notice.isPinned ? Colors.white : notice.iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(notice.icon, color: notice.iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notice.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.2),
                            ),
                          ),
                          // Pinned Button
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: IconButton(
                              icon: Icon(
                                notice.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                color: notice.isPinned ? Colors.redAccent : colors.onSurface.withOpacity(0.3),
                                size: 22,
                              ),
                              onPressed: () => _togglePin(notice, stateNotifier),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              splashRadius: 24,
                            ),
                          ),
                          // Edit/Delete options for Committee Member
                          ValueListenableBuilder<ProfileData>(
                            valueListenable: currentProfile,
                            builder: (context, profile, _) {
                              if (profile.role == UserRole.committeeMember) {
                                return PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showNoticeForm(context, stateNotifier, existingNotice: notice);
                                    } else if (value == 'delete') {
                                      _deleteNotice(notice, stateNotifier);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notice.subtitle,
                        style: TextStyle(color: colors.onSurface.withOpacity(0.7), fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6.0,
                    runSpacing: 4.0,
                    children: notice.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: notice.isPinned ? Colors.white : notice.tagColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: notice.tagColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(color: notice.tagColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Icon(Icons.calendar_today, size: 12, color: colors.onSurface.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text(
                  notice.date,
                  style: TextStyle(color: colors.onSurface.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}