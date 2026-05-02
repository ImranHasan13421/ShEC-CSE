import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import '../models/notice_state.dart';
import '../../../backend/services/notice_service.dart';
import '../widgets/notice_card.dart';

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
    final descriptionController = TextEditingController(text: existingNotice?.description ?? '');
    
    ValueNotifier<List<NoticeItem>> selectedNotifier = defaultStateNotifier;
    
    final List<String> availableTags = ['Academic', 'Event', 'Workshop', 'Maintenance', 'Job', 'Lecture', 'General', 'Research'];
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
                          
                          try {
                            final noticeItem = NoticeItem(
                              id: existingNotice?.id ?? '',
                              icon: Icons.notifications,
                              iconColor: Colors.blue,
                              title: titleController.text.trim(),
                              description: descriptionController.text.trim(),
                              imagePath: finalImageUrl,
                              tags: selectedTags,
                              tagColor: Colors.blue,
                              date: existingNotice?.date ?? '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                              isVisible: isVisible,
                              createdByName: existingNotice?.createdByName ?? currentProfile.value.name,
                            );

                            String category = selectedNotifier == clubNoticesState ? 'club' : 'department';
                            if (existingNotice == null) {
                              await NoticeService.addNoticeToDB(noticeItem, category);
                            } else {
                              await NoticeService.updateNoticeInDB(noticeItem, category);
                            }
                            if (context.mounted) Navigator.pop(modalContext);
                          } catch (e) {
                            debugPrint('Error saving notice: $e');
                            setModalState(() => isUploading = false);
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
        final isSuperUser = profile.designation == 'President' || profile.designation == 'Vice President';

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
            itemBuilder: (context, index) {
              final notice = filtered[index];
              return NoticeCard(
                notice: notice,
                isAdmin: isAdmin,
                isSuperUser: isSuperUser,
                onEdit: () => _showNoticeForm(context, notifier, existingNotice: notice),
                onDelete: () => _deleteNotice(notice, notifier),
                onApprove: () => NoticeService.approveNotice(notice.id),
                onToggleVisibility: () => NoticeService.toggleNoticeVisibility(notice.id, !notice.isVisible),
              );
            },
          ),
        );
      },
    );
  }
}
