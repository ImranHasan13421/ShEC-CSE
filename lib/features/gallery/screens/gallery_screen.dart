import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/ambient_background.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import 'package:ShEC_CSE/core/services/image_processing_service.dart';
import '../models/gallery_state.dart';
import '../presentation/bloc/gallery_bloc.dart';
import '../presentation/bloc/gallery_event.dart';
import '../presentation/bloc/gallery_state.dart';
import '../../../backend/services/gallery_service.dart';
import 'gallery_detail_screen.dart';
import 'package:ShEC_CSE/core/utils/validation_rules.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GalleryBloc>().add(const FetchGalleryItemsRequested(forceRefresh: true));
  }

  void _showGalleryForm(BuildContext context, {GalleryItem? existingItem}) {
    final galleryBloc = context.read<GalleryBloc>();
    final titleController = TextEditingController(text: existingItem?.title ?? '');
    final descriptionController = TextEditingController(text: existingItem?.description ?? '');
    bool isVisible = existingItem?.isVisible ?? true;
    final formKey = GlobalKey<FormState>();

    final List<dynamic> mediaList = [];
    if (existingItem != null) {
      if (existingItem.imagePaths.isNotEmpty) {
        mediaList.addAll(existingItem.imagePaths);
      } else if (existingItem.imagePath.isNotEmpty) {
        mediaList.add(existingItem.imagePath);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isUploading = false;
            String uploadingStatus = '';

            Future<void> pickImage() async {
              if (mediaList.length >= 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You can upload up to 5 images.'))
                );
                return;
              }
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                if (!context.mounted) return;
                
                // 1. Crop Image (Flexible for gallery)
                final cropped = await ImageProcessingService.cropImage(
                  context, 
                  File(pickedFile.path),
                );
                
                if (cropped != null) {
                  // 2. Compress and Convert to WebP
                  final processed = await ImageProcessingService.processAndConvert(cropped);
                  // Delete the intermediate cropped file since we now have the compressed WebP file
                  _deleteLocalFileSilently(cropped);
                  
                  if (processed != null) {
                    setModalState(() => mediaList.add(processed));
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
                      Text(
                        existingItem == null ? 'Add Gallery Item' : 'Edit Gallery Item',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
  
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Event Title *', border: OutlineInputBorder()),
                        validator: (v) => ValidationRules.validateRequired(v, 'Event title'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: 'Description / Location', border: OutlineInputBorder()),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Visible to Members'),
                        value: isVisible,
                        onChanged: (val) => setModalState(() => isVisible = val),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 8),
  
                      const Text('Photos (Up to 5) *', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: mediaList.length + (mediaList.length < 5 ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == mediaList.length) {
                              return GestureDetector(
                                onTap: pickImage,
                                child: Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.grey.shade50,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.grey.shade500),
                                      const SizedBox(height: 4),
                                      Text('Add Photo', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final item = mediaList[index];
                            final isLocal = item is File;

                            return Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 12),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: isLocal
                                        ? Image.file(item, height: 120, width: 120, fit: BoxFit.cover)
                                        : Image.network(
                                            item,
                                            height: 120,
                                            width: 120,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              height: 120,
                                              width: 120,
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.broken_image, size: 32),
                                            ),
                                          ),
                                  ),
                                  if (isLocal)
                                    Positioned(
                                      bottom: 6,
                                      left: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.withValues(alpha: 0.85),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        final removedItem = mediaList[index];
                                        if (removedItem is File) {
                                          _deleteLocalFileSilently(removedItem);
                                        }
                                        setModalState(() {
                                          mediaList.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
  
                      const SizedBox(height: 24),
                      if (isUploading) ...[
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(strokeWidth: 3),
                              const SizedBox(height: 12),
                              Text(
                                uploadingStatus,
                                style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ] else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              if (mediaList.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one image')));
                                return;
                              }
    
                              setModalState(() {
                                isUploading = true;
                                uploadingStatus = 'Optimizing and uploading assets...';
                              });

                              final List<String> finalUrls = [];
                              
                              try {
                                for (int i = 0; i < mediaList.length; i++) {
                                  final media = mediaList[i];
                                  if (media is File) {
                                    setModalState(() {
                                      uploadingStatus = 'Uploading photo ${i + 1} of ${mediaList.length}...';
                                    });
                                    final url = await GalleryService.uploadImage(media);
                                    if (url != null && url.isNotEmpty) {
                                      finalUrls.add(url);
                                      _deleteLocalFileSilently(media);
                                    } else {
                                      throw Exception('Image upload failed');
                                    }
                                  } else if (media is String) {
                                    finalUrls.add(media);
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  setModalState(() => isUploading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
                                }
                                return;
                              }
    
                              if (!context.mounted) return;
                              if (finalUrls.isEmpty) {
                                setModalState(() => isUploading = false);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asset uploads failed. Try again.')));
                                return;
                              }
    
                              Navigator.pop(modalContext);
                              final item = GalleryItem(
                                id: existingItem?.id ?? '',
                                title: titleController.text.trim(),
                                description: descriptionController.text.trim(),
                                imagePath: finalUrls.first,
                                imagePaths: finalUrls,
                                isVisible: isVisible,
                                createdByName: existingItem?.createdByName ?? currentProfile.value.name,
                              );
    
                              if (existingItem == null) {
                                galleryBloc.add(AddGalleryItemRequested(item: item));
                              } else {
                                galleryBloc.add(UpdateGalleryItemRequested(item: item));
                              }
                            },
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                            child: Text(existingItem == null ? 'Create Gallery Item' : 'Update'),
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      // Clean up any remaining cached files in mediaList if dismissed or cancelled
      for (final item in mediaList) {
        if (item is File) {
          _deleteLocalFileSilently(item);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AmbientTimeBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          title: const Text('Gallery'),
        ),
        body: BlocBuilder<GalleryBloc, GalleryState>(
        builder: (context, state) {
          final profile = currentProfile.value;
          final isAdmin = profile.role != UserRole.student;

          List<GalleryItem> visibleItems = [];
          if (state is GalleryLoading || state is GalleryInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is GalleryError) {
            return Center(child: Text(state.message));
          } else if (state is GalleryLoaded) {
            visibleItems = state.items.where((n) {
              if (isAdmin) return true;
              return n.isApproved && n.isVisible;
            }).toList();
          }

          if (visibleItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No gallery items yet', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  if (isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Tap + to add the first photo', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                    ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<GalleryBloc>().add(const FetchGalleryItemsRequested(forceRefresh: true));
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85,
              ),
              itemCount: visibleItems.length,
              itemBuilder: (context, index) => _buildGalleryCard(context: context, item: visibleItems[index]),
            ),
          );
        },
      ),
      floatingActionButton: ValueListenableBuilder<ProfileData>(
        valueListenable: currentProfile,
        builder: (context, profile, _) {
          if (profile.role != UserRole.student) {
            return FloatingActionButton(
              onPressed: () => _showGalleryForm(context),
              child: const Icon(Icons.add_photo_alternate),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    ),
  );
}

  Widget _buildGalleryCard({required BuildContext context, required GalleryItem item}) {
    final colors = Theme.of(context).colorScheme;
    final profile = currentProfile.value;
    final isAdmin = profile.role != UserRole.student;
    const defaultColor = Colors.blue;

    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GalleryDetailScreen(item: item))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Hero(
                    tag: 'gallery_img_${item.id}',
                    child: item.imagePath.isNotEmpty
                        ? Image.network(
                            item.imagePath,
                            fit: BoxFit.cover,
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: defaultColor.withValues(alpha: 0.05),
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              color: defaultColor.withValues(alpha: 0.1),
                              child: const Center(child: Icon(Icons.photo_library, size: 48, color: defaultColor)),
                            ),
                          )
                        : Container(
                            color: defaultColor.withValues(alpha: 0.1),
                            child: const Center(child: Icon(Icons.photo_library, size: 48, color: defaultColor)),
                          ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!item.isApproved)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                child: const Text('PENDING', style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        if (item.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: TextStyle(color: colors.onSurface.withValues(alpha: 0.55), fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (!item.isVisible)
                          const Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: Text('HIDDEN', style: TextStyle(color: Colors.orange, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (item.imagePaths.length > 1)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library_outlined, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${item.imagePaths.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          if (isAdmin)
            Positioned(
              top: 8, right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!item.isApproved &&
                        (profile.designation == 'President' || profile.designation == 'Vice President')) ...[
                      GestureDetector(
                        onTap: () {
                          context.read<GalleryBloc>().add(ApproveGalleryItemRequested(itemId: item.id));
                          _showToast(context, 'Gallery item approved!', isError: false);
                        },
                        child: const Tooltip(
                          message: 'Approve Gallery Item',
                          child: Icon(Icons.check_circle, color: Colors.green, size: 18),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    GestureDetector(
                      onTap: () {
                        context.read<GalleryBloc>().add(ToggleGalleryVisibilityRequested(itemId: item.id, isVisible: !item.isVisible));
                        _showToast(context, item.isVisible ? 'Gallery item hidden!' : 'Gallery item is now visible!', isError: false);
                      },
                      child: Tooltip(
                        message: item.isVisible ? 'Hide Item' : 'Show Item',
                        child: Icon(item.isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.orange, size: 18),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _showGalleryForm(context, existingItem: item),
                      child: const Tooltip(
                        message: 'Edit Item',
                        child: Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 18),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        context.read<GalleryBloc>().add(DeleteGalleryItemRequested(item: item));
                        _showToast(context, 'Gallery item deleted successfully!', isError: false);
                      },
                      child: const Tooltip(
                        message: 'Delete Item',
                        child: Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _deleteLocalFileSilently(File file) {
    try {
      if (file.existsSync()) {
        file.deleteSync();
        debugPrint('Temporary cache file deleted: ${file.path}');
      }
    } catch (e) {
      debugPrint('Error deleting cached file: $e');
    }
  }

  void _showToast(BuildContext context, String message, {required bool isError}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}