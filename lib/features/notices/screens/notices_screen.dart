import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import 'package:ShEC_CSE/features/permissions/services/permissions_service.dart';
import 'package:ShEC_CSE/features/permissions/models/committee_permission.dart';
import 'package:ShEC_CSE/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ShEC_CSE/features/auth/presentation/bloc/auth_state.dart';
import 'package:ShEC_CSE/features/notices/presentation/bloc/notice_bloc.dart';
import 'package:ShEC_CSE/features/notices/presentation/bloc/notice_event.dart';
import 'package:ShEC_CSE/features/notices/presentation/bloc/notice_state.dart';
import 'package:ShEC_CSE/core/services/image_processing_service.dart';
import '../models/notice_state.dart';
import '../../../backend/services/notice_service.dart';
import '../widgets/notice_card.dart';
import 'package:ShEC_CSE/core/utils/validation_rules.dart';

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
    // Fetch notices if not already loaded
    final noticeState = context.read<NoticeBloc>().state;
    if (noticeState is! NoticesLoaded) {
      context.read<NoticeBloc>().add(const FetchNoticesRequested());
    }
  }

  void _deleteNotice(NoticeItem notice, String category) {
    context.read<NoticeBloc>().add(
      DeleteNoticeRequested(notice: notice, category: category),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleting notice...')),
    );
  }

  void _showNoticeForm(BuildContext context, String defaultCategory, {NoticeItem? existingNotice}) {
    final titleController = TextEditingController(text: existingNotice?.title ?? '');
    final descriptionController = TextEditingController(text: existingNotice?.description ?? '');
    
    String selectedCategory = defaultCategory;
    
    final List<String> availableTags = ['Academic', 'Event', 'Workshop', 'Maintenance', 'Job', 'Lecture', 'General', 'Research'];
    List<String> selectedTags = existingNotice?.tags.toList() ?? [];

    bool isVisible = existingNotice?.isVisible ?? true;
    File? selectedImage;
    String? currentImageUrl = existingNotice?.imagePath;
    bool isUploading = false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {

            Future<void> pickImage() async {
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                if (!context.mounted) return;
                
                // 1. Crop Image (Flexible aspect ratio for notices)
                final cropped = await ImageProcessingService.cropImage(
                  context, 
                  File(pickedFile.path),
                );
                
                if (cropped != null) {
                  // 2. Compress and Convert to WebP
                  final processed = await ImageProcessingService.processAndConvert(cropped);
                  if (processed != null) {
                    setModalState(() => selectedImage = processed);
                  }
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(existingNotice == null ? 'Add Notice' : 'Edit Notice', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      if (existingNotice == null) ...[
                        const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'club', label: Text('Club')),
                            ButtonSegment(value: 'department', label: Text('Department')),
                          ],
                          selected: {selectedCategory},
                          onSelectionChanged: (Set<String> newSelection) {
                            setModalState(() => selectedCategory = newSelection.first);
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
  
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *', 
                          border: OutlineInputBorder(),
                          errorStyle: TextStyle(fontSize: 10, height: 0.8),
                        ),
                        validator: (v) => ValidationRules.validateRequired(v, 'Title'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Full Description *', 
                          border: OutlineInputBorder(),
                          errorStyle: TextStyle(fontSize: 10, height: 0.8),
                        ),
                        maxLines: 4,
                        validator: (v) => ValidationRules.validateRequired(v, 'Description'),
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
                          onPressed: () async {
                            if (isUploading) return;
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => isUploading = true);
                            
                            String? finalImageUrl = currentImageUrl;
                            if (selectedImage != null) {
                              finalImageUrl = await NoticeService.uploadImage(selectedImage!);
                            }
  
                            if (!context.mounted) return;
                            
                            try {
                              final authState = context.read<AuthBloc>().state;
                              final profile = authState is AuthAuthenticated ? authState.profile : currentProfile.value;

                              final noticeItem = NoticeItem(
                                id: existingNotice?.id ?? '',
                                title: titleController.text.trim(),
                                description: descriptionController.text.trim(),
                                imagePath: finalImageUrl,
                                tags: selectedTags,
                                date: existingNotice?.date ?? '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                isVisible: isVisible,
                                createdByName: existingNotice?.createdByName ?? profile.name,
                              );
   
                              if (existingNotice == null) {
                                modalContext.read<NoticeBloc>().add(
                                  AddNoticeRequested(notice: noticeItem, category: selectedCategory),
                                );
                              } else {
                                modalContext.read<NoticeBloc>().add(
                                  UpdateNoticeRequested(notice: noticeItem, category: selectedCategory),
                                );
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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
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
        body: BlocListener<NoticeBloc, NoticeState>(
          listener: (context, state) {
            if (state is NoticeError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${state.message}'), backgroundColor: Colors.red),
              );
            } else if (state is NoticeOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notice updated successfully!'), backgroundColor: Colors.green),
              );
            }
          },
          child: BlocBuilder<NoticeBloc, NoticeState>(
            builder: (context, state) {
              if (state is NoticeLoading && state is! NoticesLoaded) {
                return const Center(child: CircularProgressIndicator());
              }

              final clubNotices = state is NoticesLoaded ? state.clubNotices : <NoticeItem>[];
              final deptNotices = state is NoticesLoaded ? state.deptNotices : <NoticeItem>[];

              return ValueListenableBuilder<ProfileData>(
                valueListenable: currentProfile,
                builder: (context, profile, _) {
                  return ValueListenableBuilder<CommitteePermission?>(
                    valueListenable: PermissionsService.currentPermissions,
                    builder: (context, currentPerms, _) {
                      return TabBarView(
                        children: [
                          _buildNoticeList(clubNotices, 'club', currentPerms, profile),
                          _buildNoticeList(deptNotices, 'department', currentPerms, profile),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        floatingActionButton: ValueListenableBuilder<CommitteePermission?>(
          valueListenable: PermissionsService.currentPermissions,
          builder: (context, currentPerms, _) {
            return BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final profile = authState is AuthAuthenticated ? authState.profile : currentProfile.value;
                final hasNoticePermission = profile.role == UserRole.superUser ||
                    (profile.role == UserRole.committeeMember && (currentPerms?.canManageNotices ?? false)) ||
                    profile.designation == 'President' ||
                    profile.designation == 'Vice President';
                
                if (hasNoticePermission) {
                  return FloatingActionButton(
                    onPressed: () {
                      final currentTab = DefaultTabController.of(context).index;
                      _showNoticeForm(context, currentTab == 0 ? 'club' : 'department');
                    },
                    child: const Icon(Icons.add),
                  );
                }
                return const SizedBox.shrink();
              },
            );
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

  Widget _buildNoticeList(List<NoticeItem> notices, String category, CommitteePermission? currentPerms, ProfileData profile) {
    final isAdmin = profile.role == UserRole.superUser ||
        (profile.role == UserRole.committeeMember && (currentPerms?.canManageNotices ?? false)) ||
        profile.designation == 'President' ||
        profile.designation == 'Vice President';
    final isSuperUser = profile.designation == 'President' || profile.designation == 'Vice President' || profile.role == UserRole.superUser;

    var filtered = notices.where((n) {
      if (!isAdmin && (!n.isApproved || !n.isVisible)) return false;
      if (selectedFilterTag == 'All') return true;
      return n.tags.contains(selectedFilterTag);
    }).toList();

    // Sort: Pinned first, then by createdAt descending
    filtered.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      final dateA = a.createdAt ?? DateTime(2000);
      final dateB = b.createdAt ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

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
      onRefresh: () async {
        context.read<NoticeBloc>().add(const FetchNoticesRequested(forceRefresh: true));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final notice = filtered[index];
          return NoticeCard(
            notice: notice,
            isAdmin: isAdmin,
            isSuperUser: isSuperUser,
            onEdit: () => _showNoticeForm(context, category, existingNotice: notice),
            onDelete: () => _deleteNotice(notice, category),
            onApprove: () => context.read<NoticeBloc>().add(ApproveNoticeRequested(noticeId: notice.id)),
            onToggleVisibility: () => context.read<NoticeBloc>().add(ToggleNoticeVisibilityRequested(noticeId: notice.id, isVisible: !notice.isVisible)),
          );
        },
      ),
    );
  }
}
