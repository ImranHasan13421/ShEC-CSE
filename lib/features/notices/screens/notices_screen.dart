import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import '../models/notice_state.dart';
import '../../../backend/services/notice_service.dart';
import 'notice_detail_screen.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  String selectedFilterTag = 'All';

  @override
  void initState() {
    super.initState();
    NoticeService.fetchNotices();
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
    
    ValueNotifier<List<NoticeItem>> selectedNotifier = defaultStateNotifier;
    
    final List<String> availableTags = ['Academic', 'Event', 'Workshop', 'Maintenance', 'Job', 'Lecture', 'General', 'Research'];
    // For new notices, tags should be empty by default as per user request
    List<String> selectedTags = existingNotice?.tags.toList() ?? [];

    bool isVisible = existingNotice?.isVisible ?? true;
    File? selectedImage;
    String? currentImageUrl = existingNotice?.imagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            bool isUploading = false;

            Future<void> pickImage() async {
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
              if (pickedFile != null) {
                setModalState(() => selectedImage = File(pickedFile.path));
              }
            }

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
                    Text(existingNotice == null ? 'Add Notice' : 'Edit Notice', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    if (existingNotice == null) ...[
                      const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SegmentedButton<ValueNotifier<List<NoticeItem>>>(
                        segments: [
                          ButtonSegment(value: clubNoticesState, label: const Text('Club')),
                          ButtonSegment(value: deptNoticesState, label: const Text('Department')),
                        ],
                        selected: {selectedNotifier},
                        onSelectionChanged: (Set<ValueNotifier<List<NoticeItem>>> newSelection) {
                          setModalState(() => selectedNotifier = newSelection.first);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subtitleController,
                      decoration: const InputDecoration(labelText: 'Short Subtitle', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Full Description', border: OutlineInputBorder()),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),

                    const Text('Photo / Attachment', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (selectedImage != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(selectedImage!, height: 150, width: double.infinity, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8, right: 8,
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
                            top: 8, right: 8,
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
                        onPressed: pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Select Image'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      ),
                    const SizedBox(height: 16),

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
                                selectedTags.add(tag);
                              } else {
                                selectedTags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Visible to Members', style: TextStyle(fontWeight: FontWeight.bold)),
                      value: isVisible,
                      onChanged: (val) => setModalState(() => isVisible = val),
                    ),
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isUploading ? null : () async {
                          if (titleController.text.isEmpty) return;
                          setModalState(() => isUploading = true);
                          
                          String? finalImageUrl = currentImageUrl;
                          if (selectedImage != null) {
                            finalImageUrl = await NoticeService.uploadImage(selectedImage!);
                          }

                          if (!context.mounted) return;
                          Navigator.pop(modalContext);
                          
                          try {
                            final noticeItem = NoticeItem(
                              id: existingNotice?.id ?? '',
                              icon: Icons.notifications,
                              iconColor: Colors.blue,
                              title: titleController.text.trim(),
                              subtitle: subtitleController.text.trim(),
                              description: descriptionController.text.trim(),
                              imagePath: finalImageUrl,
                              tags: selectedTags,
                              tagColor: Colors.blue,
                              date: existingNotice?.date ?? 'Just now',
                              isVisible: isVisible,
                              createdByName: existingNotice?.createdByName ?? currentProfile.value.name,
                            );

                            String category = selectedNotifier == clubNoticesState ? 'club' : 'department';
                            if (existingNotice == null) {
                              await NoticeService.addNoticeToDB(noticeItem, category);
                            } else {
                              await NoticeService.updateNoticeInDB(noticeItem, category);
                            }
                          } catch (e) {
                            debugPrint('Error saving notice: $e');
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notices'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Club Notices'),
              Tab(text: 'Department Notices'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildNoticeList(clubNoticesState),
            _buildNoticeList(deptNoticesState),
          ],
        ),
        floatingActionButton: ValueListenableBuilder<ProfileData>(
          valueListenable: currentProfile,
          builder: (context, profile, _) {
            if (profile.role != UserRole.student) {
              return FloatingActionButton(
                onPressed: () {
                  final currentTab = DefaultTabController.of(context).index;
                  _showNoticeForm(context, currentTab == 0 ? clubNoticesState : deptNoticesState);
                },
                child: const Icon(Icons.add),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showFilterDialog() {
    final tags = ['All', 'Academic', 'Event', 'Workshop', 'Maintenance', 'Job', 'Lecture', 'General', 'Research'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Tag'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: tags.map((tag) => ListTile(
              title: Text(tag),
              leading: Radio<String>(
                value: tag,
                groupValue: selectedFilterTag,
                onChanged: (val) {
                  setState(() => selectedFilterTag = val!);
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                setState(() => selectedFilterTag = tag);
                Navigator.pop(context);
              },
            )).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeList(ValueNotifier<List<NoticeItem>> notifier) {
    return ValueListenableBuilder<List<NoticeItem>>(
      valueListenable: notifier,
      builder: (context, notices, _) {
        final profile = currentProfile.value;
        final isAdmin = profile.role != UserRole.student;

        var filtered = notices.where((n) {
          if (!isAdmin && (!n.isApproved || !n.isVisible)) return false;
          if (selectedFilterTag == 'All') return true;
          return n.tags.contains(selectedFilterTag);
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('No notices found.', style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => NoticeService.fetchNotices(forceRefresh: true),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) => _buildMinimalNoticeCard(filtered[index], notifier),
          ),
        );
      },
    );
  }

  Widget _buildMinimalNoticeCard(NoticeItem notice, ValueNotifier<List<NoticeItem>> notifier) {
    final colors = Theme.of(context).colorScheme;
    final isAdmin = currentProfile.value.role != UserRole.student;
    final isSuperUser = currentProfile.value.designation == 'President' || currentProfile.value.designation == 'Vice President';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoticeDetailScreen(notice: notice))),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: notice.iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(notice.icon, color: notice.iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(notice.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        if (!notice.isApproved)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                            child: const Text('PENDING', style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                        if (isAdmin)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 18),
                            onSelected: (val) {
                              if (val == 'edit') _showNoticeForm(context, notifier, existingNotice: notice);
                              if (val == 'delete') _deleteNotice(notice, notifier);
                              if (val == 'approve') NoticeService.approveNotice(notice.id);
                              if (val == 'visibility') NoticeService.toggleNoticeVisibility(notice.id, !notice.isVisible);
                            },
                            itemBuilder: (_) => [
                              if (!notice.isApproved && isSuperUser)
                                const PopupMenuItem(value: 'approve', child: Text('Approve', style: TextStyle(color: Colors.green))),
                              PopupMenuItem(value: 'visibility', child: Text(notice.isVisible ? 'Hide' : 'Show')),
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(notice.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.onSurface.withValues(alpha: 0.6), fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(notice.date, style: TextStyle(color: colors.onSurface.withValues(alpha: 0.4), fontSize: 11)),
                        const Spacer(),
                        if (notice.tags.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: notice.tagColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text(notice.tags.first, style: TextStyle(color: notice.tagColor, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        if (!notice.isVisible)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text('HIDDEN', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
