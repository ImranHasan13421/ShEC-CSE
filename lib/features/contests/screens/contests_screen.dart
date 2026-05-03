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
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showForm(BuildContext context, {ContestItem? existingItem}) {
    final titleController = TextEditingController(text: existingItem?.title ?? '');
    final platformController = TextEditingController(text: existingItem?.platform ?? '');
    final levelController = TextEditingController(text: existingItem?.level ?? '');
    final dateController = TextEditingController(text: existingItem?.date ?? '');
    final urlController = TextEditingController(text: existingItem?.url ?? '');
    final descriptionController = TextEditingController(text: existingItem?.description ?? '');
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
                left: 24, right: 24, top: 24,
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
                      decoration: const InputDecoration(labelText: 'Contest Name *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: platformController,
                      decoration: const InputDecoration(labelText: 'Platform (e.g. Codeforces) *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: TextField(
                        controller: levelController,
                        decoration: const InputDecoration(labelText: 'Level / Div', border: OutlineInputBorder()),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(
                        controller: dateController,
                        decoration: const InputDecoration(labelText: 'Date & Time', border: OutlineInputBorder()),
                      )),
                    ]),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description / Rules', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: urlController,
                      decoration: const InputDecoration(labelText: 'Contest Link / URL *', border: OutlineInputBorder()),
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
                              final item = ContestItem(
                                id: existingItem?.id ?? '',
                                title: titleController.text.trim(),
                                platform: platformController.text.trim(),
                                level: levelController.text.trim(),
                                date: dateController.text.trim(),
                                url: urlController.text.trim(),
                                description: descriptionController.text.trim(),
                                isVisible: isVisible,
                                createdByName: existingItem?.createdByName ?? currentProfile.value.name,
                              );

                              if (existingItem == null) {
                                await ContestService.addContestToDB(item);
                                if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Contest added')));
                              } else {
                                await ContestService.updateContestInDB(item);
                                if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Contest updated')));
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programming Contests'),
      ),
      body: ValueListenableBuilder<List<ContestItem>>(
        valueListenable: contestState,
        builder: (context, items, _) {
          final isAdmin = currentProfile.value.role != UserRole.student;
          final visibleItems = items.where((j) {
            if (isAdmin) return true;
            return j.isApproved && j.isVisible;
          }).toList();

          if (visibleItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 64, color: colors.onSurface.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  Text('No upcoming contests.', style: TextStyle(color: colors.onSurface.withValues(alpha: 0.4))),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ContestService.fetchContestsAndCourses(forceRefresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: visibleItems.length,
              itemBuilder: (context, index) => _buildContestCard(visibleItems[index]),
            ),
          );
        },
      ),
      floatingActionButton: ValueListenableBuilder<ProfileData>(
        valueListenable: currentProfile,
        builder: (context, profile, _) {
          if (profile.role != UserRole.student) {
            return FloatingActionButton(
              onPressed: () => _showForm(context),
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContestCard(ContestItem item) {
    final colors = Theme.of(context).colorScheme;
    final isAdmin = currentProfile.value.role != UserRole.student;
    final isSuperUser = currentProfile.value.designation == 'President' || currentProfile.value.designation == 'Vice President';
    const contestIconColor = Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: contestIconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.emoji_events, color: contestIconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                          if (isAdmin)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20),
                              onSelected: (val) {
                                if (val == 'edit') _showForm(context, existingItem: item);
                                if (val == 'delete') ContestService.deleteContestFromDB(item);
                                if (val == 'approve') ContestService.approveContest(item.id);
                                if (val == 'visibility') ContestService.toggleContestVisibility(item.id, !item.isVisible);
                              },
                              itemBuilder: (_) => [
                                if (!item.isApproved && isSuperUser)
                                  const PopupMenuItem(value: 'approve', child: Text('Approve', style: TextStyle(color: Colors.green))),
                                PopupMenuItem(value: 'visibility', child: Text(item.isVisible ? 'Hide' : 'Show')),
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(item.platform, style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(item.description, style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7), fontSize: 13)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (item.level.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: colors.secondaryContainer, borderRadius: BorderRadius.circular(6)),
                    child: Text(item.level, style: TextStyle(color: colors.onSecondaryContainer, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                if (item.level.isNotEmpty) const SizedBox(width: 12),
                Icon(Icons.calendar_month, size: 14, color: colors.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(item.date, style: TextStyle(color: colors.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                const Spacer(),
                if (!item.isApproved)
                   const Text('PENDING', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _launchURL(item.url),
                icon: const Icon(Icons.launch, size: 18),
                label: const Text('Join Now', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}