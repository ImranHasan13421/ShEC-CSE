import 'package:flutter/material.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import '../models/gallery_state.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  void _showGalleryForm(BuildContext context, {GalleryItem? existingItem}) {
    final titleController = TextEditingController(text: existingItem?.title ?? '');
    final subtitleController = TextEditingController(text: existingItem?.subtitle ?? '');
    final imageController = TextEditingController(text: existingItem?.imagePath ?? 'assets/gallery/placeholder.jpg');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existingItem == null ? 'Add Gallery Item' : 'Edit Gallery Item', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
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
                controller: imageController,
                decoration: const InputDecoration(labelText: 'Image Path/URL', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      if (existingItem == null) {
                        final newItem = GalleryItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleController.text,
                          subtitle: subtitleController.text,
                          imagePath: imageController.text,
                          icon: Icons.photo,
                          color: Colors.blue,
                        );
                        galleryState.value = List.from(galleryState.value)..insert(0, newItem);
                      } else {
                        final index = galleryState.value.indexOf(existingItem);
                        if (index != -1) {
                          final updatedList = List<GalleryItem>.from(galleryState.value);
                          updatedList[index] = GalleryItem(
                            id: existingItem.id,
                            title: titleController.text,
                            subtitle: subtitleController.text,
                            imagePath: imageController.text,
                            icon: existingItem.icon,
                            color: existingItem.color,
                          );
                          galleryState.value = updatedList;
                        }
                      }
                      Navigator.pop(context);
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

  void _deleteGalleryItem(GalleryItem item) {
    galleryState.value = List.from(galleryState.value)..remove(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
      ),
      body: ValueListenableBuilder<List<GalleryItem>>(
        valueListenable: galleryState,
        builder: (context, items, _) {
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildGalleryCard(context: context, item: item);
            },
          );
        },
      ),
      floatingActionButton: ValueListenableBuilder<ProfileData>(
        valueListenable: currentProfile,
        builder: (context, profile, _) {
          if (profile.role == UserRole.committeeMember) {
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

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withOpacity(0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              // Future: Open full-screen image viewer
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Image.asset(
                    item.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: item.color.withOpacity(0.1),
                        child: Center(
                          child: Icon(
                            item.icon,
                            size: 48,
                            color: item.color.withOpacity(0.8),
                          ),
                        ),
                      );
                    },
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
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            color: colors.onSurface.withOpacity(0.6),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Edit/Delete for Committee Members
          ValueListenableBuilder<ProfileData>(
            valueListenable: currentProfile,
            builder: (context, profile, _) {
              if (profile.role == UserRole.committeeMember) {
                return Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12)),
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showGalleryForm(context, existingItem: item);
                        } else if (value == 'delete') {
                          _deleteGalleryItem(item);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}