import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import '../models/contest_state.dart';
import '../../../backend/services/contest_service.dart';

class ContestsScreen extends StatefulWidget {
  const ContestsScreen({super.key});

  @override
  State<ContestsScreen> createState() => _ContestsScreenState();
}

class _ContestsScreenState extends State<ContestsScreen> {
  @override
  void initState() {
    super.initState();
    ContestService.fetchContestsAndCourses();
  }
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  void _showForm(BuildContext context, ValueNotifier<List<ContestItem>> stateNotifier, bool isCourse, {ContestItem? existingItem}) {
    final titleController = TextEditingController(text: existingItem?.title ?? '');
    final platformController = TextEditingController(text: existingItem?.platform ?? '');
    final levelController = TextEditingController(text: existingItem?.level ?? '');
    final dateController = TextEditingController(text: existingItem?.date ?? '');
    final urlController = TextEditingController(text: existingItem?.url ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existingItem == null ? (isCourse ? 'Add Course' : 'Add Contest') : (isCourse ? 'Edit Course' : 'Edit Contest'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: platformController,
                decoration: const InputDecoration(labelText: 'Platform / Provider', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: levelController,
                decoration: const InputDecoration(labelText: 'Level / Tag', border: OutlineInputBorder()),
              ),
              if (!isCourse) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: 'Date / Frequency', border: OutlineInputBorder()),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'URL', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty) {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(modalContext);
                      try {
                        final newItem = ContestItem(
                          id: existingItem?.id ?? '',
                          title: titleController.text,
                          platform: platformController.text,
                          level: levelController.text,
                          date: dateController.text,
                          url: urlController.text,
                          iconColor: existingItem?.iconColor ?? Colors.blue,
                          isCourse: isCourse,
                        );

                        if (existingItem == null) {
                          await ContestService.addContestToDB(newItem);
                          if (mounted) messenger.showSnackBar(SnackBar(content: Text('${isCourse ? 'Course' : 'Contest'} created successfully')));
                        } else {
                          final index = stateNotifier.value.indexOf(existingItem);
                          if (index != -1) {
                            final updatedList = List<ContestItem>.from(stateNotifier.value);
                            updatedList[index] = newItem;
                            stateNotifier.value = updatedList;
                          }
                          await ContestService.updateContestInDB(newItem);
                          if (mounted) messenger.showSnackBar(SnackBar(content: Text('${isCourse ? 'Course' : 'Contest'} updated successfully')));
                        }
                      } catch (e) {
                        if (mounted) messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: Text(existingItem == null ? 'Create' : 'Update'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _deleteItem(ContestItem item, ValueNotifier<List<ContestItem>> stateNotifier) async {
    try {
      await ContestService.deleteContestFromDB(item);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            Container(
              color: colors.primary,
              child: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'Contests'),
                  Tab(text: 'Events & Courses'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTab(context, contestState, false),
                  _buildTab(context, courseState, true),
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
                      if (tabIndex == 0) {
                        _showForm(context, contestState, false);
                      } else {
                        _showForm(context, courseState, true);
                      }
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

  Widget _buildTab(BuildContext context, ValueNotifier<List<ContestItem>> stateNotifier, bool isCourse) {
    return ValueListenableBuilder<List<ContestItem>>(
      valueListenable: stateNotifier,
      builder: (context, items, _) {
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            if (isCourse) {
              return _buildCourseCard(context, item, stateNotifier);
            } else {
              return _buildContestCard(context, item, stateNotifier);
            }
          },
        );
      },
    );
  }

  Widget _buildContestCard(BuildContext context, ContestItem item, ValueNotifier<List<ContestItem>> stateNotifier) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.emoji_events, color: item.iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          _buildAdminMenu(item, stateNotifier),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(item.platform, style: TextStyle(color: colors.onSurface.withOpacity(0.7), fontSize: 13)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(item.level, style: TextStyle(color: colors.error, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: colors.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 6),
                    Text(item.date, style: TextStyle(color: colors.onSurface.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _launchURL(item.url),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Join Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, ContestItem item, ValueNotifier<List<ContestItem>> stateNotifier) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: item.iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.computer, color: item.iconColor),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold))),
            _buildAdminMenu(item, stateNotifier),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  item.platform,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(item.level, style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () => _launchURL(item.url),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.surfaceContainerHighest,
            foregroundColor: colors.primary,
            elevation: 0,
          ),
          child: const Text('Details'),
        ),
      ),
    );
  }

  Widget _buildAdminMenu(ContestItem item, ValueNotifier<List<ContestItem>> stateNotifier) {
    return ValueListenableBuilder<ProfileData>(
      valueListenable: currentProfile,
      builder: (context, profile, _) {
        if (profile.role == UserRole.committeeMember) {
          return PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (value) {
              if (value == 'edit') {
                _showForm(context, stateNotifier, item.isCourse, existingItem: item);
              } else if (value == 'delete') {
                _deleteItem(item, stateNotifier);
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
    );
  }
}