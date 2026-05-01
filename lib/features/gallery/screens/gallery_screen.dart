import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import '../models/gallery_state.dart';
import '../../../backend/services/gallery_service.dart';
import 'gallery_detail_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  @override
  void initState() {
    super.initState();
    GalleryService.fetchGalleryItems();
  }

  void _showGalleryForm(BuildContext context, {GalleryItem? existingItem}) {
    final titleController = TextEditingController(text: existingItem?.title ?? '');
    final descriptionController = TextEditingController(text: existingItem?.description ?? '');
    bool isVisible = existingItem?.isVisible ?? true;
    
    File? selectedImage;
    String? currentImageUrl = existingItem?.imagePath;

    Future<void> pickImage(StateSetter setModalState) async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setModalState(() {
          selectedImage = File(pickedFile.path);
        });
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
                    Text(existingItem == null ? 'Add Gallery Item' : 'Edit Gallery Item', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Event Title', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController, 
                      decoration: const InputDecoration(labelText: 'Description / Location', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Visible to Members'),
                      value: isVisible,
                      onChanged: (val) => setModalState(() => isVisible = val),
                    ),
                    const SizedBox(height: 16),
                    
                    const Text('Attach Image', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (selectedImage != null)
                      Stack(
                        children: [
                          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(selectedImage!, height: 150, width: double.infinity, fit: BoxFit.cover)),
                          Positioned(top: 8, right: 8, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), style: IconButton.styleFrom(backgroundColor: Colors.black54), onPressed: () => setModalState(() => selectedImage = null))),
                        ],
                      )
                    else if (currentImageUrl != null && currentImageUrl!.isNotEmpty)
                      Stack(
                        children: [
                          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(currentImageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover)),
                          Positioned(top: 8, right: 8, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), style: IconButton.styleFrom(backgroundColor: Colors.black54), onPressed: () => setModalState(() => currentImageUrl = null))),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () => pickImage(setModalState),
                        icon: const Icon(Icons.image),
                        label: const Text('Select Image from Gallery'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isUploading ? null : () async {
                          if (titleController.text.isNotEmpty && (selectedImage != null || (currentImageUrl != null && currentImageUrl!.isNotEmpty))) {
                            setModalState(() => isUploading = true);
                            String? finalImageUrl = currentImageUrl;
                            if (selectedImage != null) {
                              finalImageUrl = await GalleryService.uploadImage(selectedImage!);
                            }

                            if (mounted && finalImageUrl != null) {
                              Navigator.pop(modalContext);
                              final item = GalleryItem(
                                id: existingItem?.id ?? '',
                                title: titleController.text,
                                description: descriptionController.text,
                                imagePath: finalImageUrl,
                                icon: existingItem?.icon ?? Icons.photo,
                                color: existingItem?.color ?? Colors.blue,
                                isVisible: isVisible,
                                createdByName: existingItem?.createdByName ?? currentProfile.value.name,
                              );
                              
                              if (existingItem == null) {
                                await GalleryService.addGalleryItemToDB(item);
                              } else {
                                await GalleryService.updateGalleryItemInDB(item);
                              }
                            }
                          }
                        },
                        child: isUploading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(existingItem == null ? 'Create' : 'Update'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: ValueListenableBuilder<List<GalleryItem>>(
        valueListenable: galleryState,
        builder: (context, items, _) {
          final profile = currentProfile.value;
          final isAdmin = profile.role != UserRole.student;

          final visibleItems = items.where((n) {
            if (isAdmin) return true;
            return n.isApproved && n.isVisible; 
          }).toList();

          if (visibleItems.isEmpty) return const Center(child: Text('No gallery items found.'));

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85,
            ),
            itemCount: visibleItems.length,
            itemBuilder: (context, index) {
              return _buildGalleryCard(context: context, item: visibleItems[index]);
            },
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
    );
  }

  Widget _buildGalleryCard({required BuildContext context, required GalleryItem item}) {
    final colors = Theme.of(context).colorScheme;
    final profile = currentProfile.value;
    final isAdmin = profile.role != UserRole.student;
    final isSuper = profile.role == UserRole.superUser;

    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => GalleryDetailScreen(item: item)));
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Hero(
                    tag: 'gallery_img_${item.id}',
                    child: Image.network(
                      item.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: item.color.withOpacity(0.1),
                          child: Center(child: Icon(item.icon, size: 48, color: item.color.withOpacity(0.8))),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.2),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!item.isApproved)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                child: const Text('PENDING', style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: TextStyle(color: colors.onSurface.withOpacity(0.6), fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
          if (isAdmin)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12))),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                  onSelected: (value) {
                    if (value == 'edit') _showGalleryForm(context, existingItem: item);
                    if (value == 'delete') GalleryService.deleteGalleryItemFromDB(item);
                    if (value == 'approve') GalleryService.approveGalleryItem(item.id);
                    if (value == 'visibility') GalleryService.toggleGalleryVisibility(item.id, !item.isVisible);
                  },
                  itemBuilder: (context) => [
                    if (!item.isApproved && (profile.designation == 'President' || profile.designation == 'Vice President'))
                      const PopupMenuItem(value: 'approve', child: Text('Approve', style: TextStyle(color: Colors.green))),
                    PopupMenuItem(value: 'visibility', child: Text(item.isVisible ? 'Hide' : 'Show')),
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}