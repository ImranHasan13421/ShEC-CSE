import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import '../models/notice_state.dart';
import '../../../backend/services/notice_service.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  @override
  void initState() {
    super.initState();
    NoticeService.fetchNotices();
  }

  // --- Toggle Logic ---
  void _togglePin(NoticeItem notice, ValueNotifier<List<NoticeItem>> stateNotifier) async {
    try {
      notice.isPinned = !notice.isPinned;
      // Trigger a rebuild of the list by re-assigning the value
      stateNotifier.value = List.from(stateNotifier.value);
      
      String category = stateNotifier == clubNoticesState ? 'club' : 'department';
      await NoticeService.updateNoticeInDB(notice, category);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating pin: $e')));
    }
  }

  void _deleteNotice(NoticeItem notice, ValueNotifier<List<NoticeItem>> stateNotifier) async {
    try {
      String category = stateNotifier == clubNoticesState ? 'club' : 'department';
      await NoticeService.deleteNoticeFromDB(notice.id, category);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notice deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting notice: $e')));
    }
  }

  void _showNoticeForm(BuildContext context, ValueNotifier<List<NoticeItem>> defaultStateNotifier, {NoticeItem? existingNotice}) {
    final titleController = TextEditingController(text: existingNotice?.title ?? '');
    final subtitleController = TextEditingController(text: existingNotice?.subtitle ?? '');
    final descriptionController = TextEditingController(text: existingNotice?.description ?? '');
    
    // Track the selected category
    ValueNotifier<List<NoticeItem>> selectedNotifier = defaultStateNotifier;
    
    // Available tags and selected tags
    final List<String> availableTags = ['Academic', 'Event', 'Workshop', 'Maintenance', 'Job', 'Lecture', 'General', 'Research'];
    List<String> selectedTags = existingNotice?.tags.toList() ?? ['General'];

    File? selectedImage;
    String? currentImageUrl = existingNotice?.imagePath;

    Future<void> pickImage(StateSetter setModalState) async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setModalState(() {
          selectedImage = File(pickedFile.path);
        });
      }
    }

    // We'll manage state inside the StatefulBuilder for the bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            bool isUploading = false;

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
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Full Description', border: OutlineInputBorder()),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),

                    // Image Picker
                    const Text('Attach Image', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (selectedImage != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(selectedImage!, height: 150, width: double.infinity, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              style: IconButton.styleFrom(backgroundColor: Colors.black54),
                              onPressed: () => setModalState(() => selectedImage = null),
                            ),
                          ),
                        ],
                      )
                    else if (currentImageUrl != null && currentImageUrl!.isNotEmpty)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(currentImageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              style: IconButton.styleFrom(backgroundColor: Colors.black54),
                              onPressed: () => setModalState(() => currentImageUrl = null),
                            ),
                          ),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () => pickImage(setModalState),
                        icon: const Icon(Icons.image),
                        label: const Text('Select Image from Gallery'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
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
                        onPressed: isUploading ? null : () async {
                          if (titleController.text.isNotEmpty) {
                            setModalState(() => isUploading = true);
                            
                            String? finalImageUrl = currentImageUrl;
                            
                            // Upload new image if selected
                            if (selectedImage != null) {
                              finalImageUrl = await NoticeService.uploadImage(selectedImage!);
                            }

                            if (mounted) {
                              final messenger = ScaffoldMessenger.of(context);
                              Navigator.pop(modalContext);
                              try {
                                if (existingNotice == null) {
                                  // Add new
                                  final newNotice = NoticeItem(
                                    id: '',
                                    icon: Icons.notifications,
                                    iconColor: Colors.blue,
                                    title: titleController.text,
                                    subtitle: subtitleController.text,
                                    description: descriptionController.text,
                                    imagePath: finalImageUrl,
                                    tags: selectedTags,
                                    tagColor: Colors.blue,
                                    date: 'Just now',
                                  );
                                  String category = selectedNotifier == clubNoticesState ? 'club' : 'department';
                                  await NoticeService.addNoticeToDB(newNotice, category);
                                  if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Notice created successfully')));
                                } else {
                                  // Edit existing
                                  final updatedNotice = NoticeItem(
                                    id: existingNotice.id,
                                    icon: existingNotice.icon,
                                    iconColor: existingNotice.iconColor,
                                    title: titleController.text,
                                    subtitle: subtitleController.text,
                                    description: descriptionController.text,
                                    imagePath: finalImageUrl,
                                    tags: selectedTags,
                                    tagColor: existingNotice.tagColor,
                                    date: existingNotice.date,
                                    isPinned: existingNotice.isPinned,
                                  );
                                  final index = defaultStateNotifier.value.indexOf(existingNotice);
                                  if (index != -1) {
                                    final updatedList = List<NoticeItem>.from(defaultStateNotifier.value);
                                    updatedList[index] = updatedNotice;
                                    defaultStateNotifier.value = updatedList;
                                  }
                                  String category = defaultStateNotifier == clubNoticesState ? 'club' : 'department';
                                  await NoticeService.updateNoticeInDB(updatedNotice, category);
                                  if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Notice updated successfully')));
                                }
                              } catch (e) {
                                if (mounted) messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          }
                        },
                        child: isUploading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(existingNotice == null ? 'Create' : 'Update'),
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
            if (profile.role == UserRole.committeeMember || profile.role == UserRole.superUser) {
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
        final profile = currentProfile.value;
        final isAdmin = profile.role != UserRole.student;

        // Filter notices: students only see approved ones. Admins see all.
        final visibleNotices = notices.where((n) {
          if (n.isApproved) return true;
          return isAdmin; // Only admins see unapproved
        }).toList();

        final pinnedNotices = visibleNotices.where((n) => n.isPinned).toList();
        final unpinnedNotices = visibleNotices.where((n) => !n.isPinned).toList();

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
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    notice.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.2),
                                  ),
                                ),
                                if (!notice.isApproved)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      border: Border.all(color: Colors.red),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('PENDING', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                              ],
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
                          ValueListenableBuilder<ProfileData>(
                            valueListenable: currentProfile,
                            builder: (context, profile, _) {
                              if (profile.role == UserRole.committeeMember || profile.role == UserRole.superUser) {
                                return PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showNoticeForm(context, stateNotifier, existingNotice: notice);
                                    } else if (value == 'delete') {
                                      _deleteNotice(notice, stateNotifier);
                                    } else if (value == 'approve') {
                                      NoticeService.approveNotice(notice.id);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    if (!notice.isApproved && profile.role == UserRole.superUser)
                                      const PopupMenuItem(value: 'approve', child: Text('Approve', style: TextStyle(color: Colors.green))),
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
                        style: TextStyle(color: colors.onSurface.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
                      ),
                      if (notice.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          notice.description,
                          style: TextStyle(color: colors.onSurface.withOpacity(0.7), fontSize: 13, height: 1.4),
                        ),
                      ],
                      if (notice.imagePath != null && notice.imagePath!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            notice.imagePath!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 100,
                                color: colors.surfaceContainerHighest,
                                child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                              );
                            },
                          ),
                        ),
                      ],
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