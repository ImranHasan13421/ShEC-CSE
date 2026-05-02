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
    bool isVisible = existingItem?.isVisible ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(existingItem == null ? 'Add Contest' : 'Edit Contest', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Contest Name (e.g. Codeforces Round #892)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: platformController,
                      decoration: const InputDecoration(labelText: 'Platform (e.g. Codeforces, VJudge)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: levelController,
                      decoration: const InputDecoration(labelText: 'Level / Division', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(labelText: 'Date & Time', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: urlController,
                      decoration: const InputDecoration(labelText: 'Contest Link / URL', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Visible to Members'),
                      value: isVisible,
                      onChanged: (val) => setModalState(() => isVisible = val),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (titleController.text.isNotEmpty && urlController.text.isNotEmpty) {
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
                                isCourse: false,
                                isVisible: isVisible,
                                createdByName: existingItem?.createdByName ?? currentProfile.value.name,
                              );

                              if (existingItem == null) {
                                await ContestService.addContestToDB(newItem);
                                if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Contest added successfully')));
                              } else {
                                await ContestService.updateContestInDB(newItem);
                                if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Contest updated successfully')));
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
              ),
            );
          },
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programming Contests'),
      ),
      body: _buildTab(context, contestState, false),
      floatingActionButton: ValueListenableBuilder<ProfileData>(
        valueListenable: currentProfile,
        builder: (context, profile, _) {
          if (profile.role != UserRole.student) {
            return FloatingActionButton(
              onPressed: () => _showForm(context, contestState, false),
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildTab(BuildContext context, ValueNotifier<List<ContestItem>> stateNotifier, bool isCourse) {
    return ValueListenableBuilder<List<ContestItem>>(
      valueListenable: stateNotifier,
      builder: (context, items, _) {
        final profile = currentProfile.value;
        final isAdmin = profile.role != UserRole.student;
        final visibleItems = items.where((j) {
          if (isAdmin) return true;
          return j.isApproved && j.isVisible;
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: visibleItems.length,
          itemBuilder: (context, index) {
            final item = visibleItems[index];
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
        side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
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
                    color: item.iconColor.withValues(alpha: 0.1),
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
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                if (!item.isApproved)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('PENDING', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ),
                            _buildAdminMenu(item, stateNotifier, currentProfile.value),
                        ],
                      ),
                      if (!item.isVisible)
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Text('HIDDEN FROM MEMBERS', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(item.platform, style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7), fontSize: 13)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.error.withValues(alpha: 0.1),
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
                    Icon(Icons.calendar_today, size: 14, color: colors.onSurface.withValues(alpha: 0.6)),
                    const SizedBox(width: 6),
                    Text(item.date, style: TextStyle(color: colors.onSurface.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500)),
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
        side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
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
            Expanded(
              child: Row(
                children: [
                  Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                  if (!item.isApproved)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: const Text('PENDING', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            _buildAdminMenu(item, stateNotifier, currentProfile.value),
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
                  color: colors.primary.withValues(alpha: 0.1),
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

  Widget _buildAdminMenu(ContestItem item, ValueNotifier<List<ContestItem>> stateNotifier, ProfileData profile) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (value) {
        if (value == 'edit') {
          _showForm(context, stateNotifier, false, existingItem: item);
        } else if (value == 'delete') {
          _deleteItem(item, stateNotifier);
        } else if (value == 'approve') {
          ContestService.approveContest(item.id);
        } else if (value == 'visibility') {
          ContestService.toggleContestVisibility(item.id, !item.isVisible);
        }
      },
      itemBuilder: (context) => [
        if (!item.isApproved && (profile.designation == 'President' || profile.designation == 'Vice President'))
          const PopupMenuItem(value: 'approve', child: Text('Approve', style: TextStyle(color: Colors.green))),
        PopupMenuItem(value: 'visibility', child: Text(item.isVisible ? 'Hide' : 'Show')),
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    );
  }
}