import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../backend/services/teacher_service.dart';
import '../../profile/models/profile_state.dart';
import '../models/teacher_state.dart';

class TeacherContactsScreen extends StatefulWidget {
  const TeacherContactsScreen({super.key});

  @override
  State<TeacherContactsScreen> createState() => _TeacherContactsScreenState();
}

class _TeacherContactsScreenState extends State<TeacherContactsScreen> {
  @override
  void initState() {
    super.initState();
    TeacherService.fetchTeachers();
  }

  void _showTeacherForm({TeacherContact? existingTeacher}) {
    final nameController = TextEditingController(text: existingTeacher?.name ?? '');
    final descController = TextEditingController(text: existingTeacher?.designation ?? '');
    final phoneController = TextEditingController(text: existingTeacher?.phone ?? '');
    final emailController = TextEditingController(text: existingTeacher?.email ?? '');
    
    File? selectedImage;
    String? currentImageUrl = existingTeacher?.imagePath;

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
                  children: [
                    Text(existingTeacher == null ? 'Add Teacher' : 'Edit Teacher', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    GestureDetector(
                      onTap: () => pickImage(setModalState),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: selectedImage != null 
                            ? FileImage(selectedImage!) 
                            : (currentImageUrl != null && currentImageUrl!.isNotEmpty ? NetworkImage(currentImageUrl!) : null) as ImageProvider?,
                        child: (selectedImage == null && (currentImageUrl == null || currentImageUrl!.isEmpty))
                            ? const Icon(Icons.add_a_photo, size: 30, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: descController, decoration: const InputDecoration(labelText: 'Designation', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone (Optional)', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email (Optional)', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isUploading ? null : () async {
                          if (nameController.text.isNotEmpty && descController.text.isNotEmpty) {
                            setModalState(() => isUploading = true);
                            String? finalImageUrl = currentImageUrl;
                            if (selectedImage != null) {
                              finalImageUrl = await TeacherService.uploadImage(selectedImage!);
                            }

                            final teacher = TeacherContact(
                              id: existingTeacher?.id ?? '',
                              name: nameController.text,
                              designation: descController.text,
                              phone: phoneController.text,
                              email: emailController.text,
                              imagePath: finalImageUrl ?? '',
                            );

                            if (mounted) {
                              Navigator.pop(modalContext);
                              if (existingTeacher == null) {
                                await TeacherService.addTeacher(teacher);
                              } else {
                                await TeacherService.updateTeacher(teacher);
                              }
                            }
                          }
                        },
                        child: isUploading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(existingTeacher == null ? 'Save' : 'Update'),
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
      appBar: AppBar(title: const Text('Teacher Contacts')),
      body: ValueListenableBuilder<List<TeacherContact>>(
        valueListenable: teachersState,
        builder: (context, teachers, _) {
          if (teachers.isEmpty) {
            return const Center(child: Text('No teacher contacts available.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              final teacher = teachers[index];
              return _buildTeacherCard(teacher);
            },
          );
        },
      ),
      floatingActionButton: ValueListenableBuilder<ProfileData>(
        valueListenable: currentProfile,
        builder: (context, profile, _) {
          if (profile.role != UserRole.student) {
            return FloatingActionButton(
              onPressed: () => _showTeacherForm(),
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildTeacherCard(TeacherContact teacher) {
    final colors = Theme.of(context).colorScheme;
    final profile = currentProfile.value;
    final isAdmin = profile.role != UserRole.student;
    final isSuper = profile.role == UserRole.superUser;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.outline.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: teacher.imagePath.isNotEmpty ? NetworkImage(teacher.imagePath) : null,
                  child: teacher.imagePath.isEmpty ? Text(teacher.name[0].toUpperCase(), style: const TextStyle(fontSize: 24)) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(teacher.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                          if (!teacher.isApproved)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), border: Border.all(color: Colors.red), borderRadius: BorderRadius.circular(4)),
                              child: const Text('PENDING', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          if (isAdmin)
                            PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'edit') _showTeacherForm(existingTeacher: teacher);
                                if (val == 'delete') TeacherService.deleteTeacher(teacher.id);
                                if (val == 'approve') TeacherService.approveTeacher(teacher.id);
                              },
                              itemBuilder: (_) => [
                                if (!teacher.isApproved && isSuper) const PopupMenuItem(value: 'approve', child: Text('Approve', style: TextStyle(color: Colors.green))),
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                        ],
                      ),
                      Text(teacher.designation, style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (teacher.phone.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => launchUrl(Uri.parse('tel:${teacher.phone}')),
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(backgroundColor: colors.surfaceContainerHighest, foregroundColor: colors.onSurface),
                  ),
                if (teacher.email.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => launchUrl(Uri.parse('mailto:${teacher.email}')),
                    icon: const Icon(Icons.email, size: 18),
                    label: const Text('Email'),
                    style: ElevatedButton.styleFrom(backgroundColor: colors.surfaceContainerHighest, foregroundColor: colors.onSurface),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
