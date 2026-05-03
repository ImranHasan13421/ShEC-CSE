import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../backend/services/teacher_service.dart';
import '../../profile/models/profile_state.dart';
import '../models/teacher_state.dart';
import 'teacher_detail_screen.dart';

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
    final designationController = TextEditingController(text: existingTeacher?.designation ?? '');
    final phoneController = TextEditingController(text: existingTeacher?.phone ?? '');
    final emailController = TextEditingController(text: existingTeacher?.email ?? '');
    final officeController = TextEditingController(text: existingTeacher?.officeRoom ?? '');
    final departmentController = TextEditingController(text: existingTeacher?.department ?? 'CSE');
    final joinYearController = TextEditingController(text: existingTeacher?.joinYear ?? '');
    final expertiseController = TextEditingController();

    List<String> expertiseList = List.from(existingTeacher?.areasOfExpertise ?? []);
    bool isVisible = existingTeacher?.isVisible ?? true;

    File? selectedImage;
    String? currentImageUrl = existingTeacher?.imagePath;

    Future<void> pickImage(StateSetter setModalState) async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) setModalState(() => selectedImage = File(picked.path));
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
                    Text(
                      existingTeacher == null ? 'Add Teacher' : 'Edit Teacher',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () => pickImage(setModalState),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: selectedImage != null
                              ? FileImage(selectedImage!)
                              : (currentImageUrl != null && currentImageUrl!.isNotEmpty
                                  ? NetworkImage(currentImageUrl!) as ImageProvider
                                  : null),
                          child: (selectedImage == null && (currentImageUrl == null || currentImageUrl!.isEmpty))
                              ? const Icon(Icons.add_a_photo, size: 30, color: Colors.grey)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _field(nameController, 'Full Name *'),
                    const SizedBox(height: 12),
                    _field(designationController, 'Designation (e.g. Assistant Professor) *'),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _field(departmentController, 'Department')),
                      const SizedBox(width: 12),
                      Expanded(child: _field(joinYearController, 'Join Year')),
                    ]),
                    const SizedBox(height: 12),
                    _field(officeController, 'Office Room'),
                    const SizedBox(height: 12),
                    _field(phoneController, 'Phone', keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _field(emailController, 'Email', keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    const Text('Areas of Expertise', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: expertiseList.map((e) => Chip(
                        label: Text(e, style: const TextStyle(fontSize: 12)),
                        onDeleted: () => setModalState(() => expertiseList.remove(e)),
                      )).toList(),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: expertiseController,
                            decoration: const InputDecoration(
                              hintText: 'Add area (e.g. Machine Learning)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: () {
                            if (expertiseController.text.isNotEmpty) {
                              setModalState(() {
                                expertiseList.add(expertiseController.text.trim());
                                expertiseController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Visible to Members'),
                      value: isVisible,
                      onChanged: (val) => setModalState(() => isVisible = val),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isUploading ? null : () async {
                          if (nameController.text.isEmpty || designationController.text.isEmpty) return;
                          setModalState(() => isUploading = true);
                          String? finalImageUrl = currentImageUrl;
                          if (selectedImage != null) {
                            finalImageUrl = await TeacherService.uploadImage(selectedImage!);
                          }
                          final teacher = TeacherContact(
                            id: existingTeacher?.id ?? '',
                            name: nameController.text.trim(),
                            designation: designationController.text.trim(),
                            phone: phoneController.text.trim(),
                            email: emailController.text.trim(),
                            officeRoom: officeController.text.trim(),
                            department: departmentController.text.trim(),
                            joinYear: joinYearController.text.trim(),
                            areasOfExpertise: expertiseList,
                            imagePath: finalImageUrl ?? '',
                            isVisible: isVisible,
                            createdByName: existingTeacher?.createdByName ?? currentProfile.value.name,
                          );
                          if (mounted) {
                            Navigator.pop(modalContext);
                            if (existingTeacher == null) {
                              await TeacherService.addTeacher(teacher);
                            } else {
                              await TeacherService.updateTeacher(teacher);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: isUploading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(existingTeacher == null ? 'Save Teacher' : 'Update'),
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

  Widget _field(TextEditingController ctrl, String label, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Contacts')),
      body: ValueListenableBuilder<List<TeacherContact>>(
        valueListenable: teachersState,
        builder: (context, teachers, _) {
          final isAdmin = currentProfile.value.role != UserRole.student;
          final visible = isAdmin ? teachers : teachers.where((t) => t.isApproved && t.isVisible).toList();
          if (visible.isEmpty) return const Center(child: Text('No teacher contacts available.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: visible.length,
            itemBuilder: (context, index) => _buildTeacherCard(visible[index]),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherDetailScreen(teacher: teacher))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: colors.primaryContainer,
                backgroundImage: teacher.imagePath.isNotEmpty ? NetworkImage(teacher.imagePath) : null,
                child: teacher.imagePath.isEmpty
                    ? Text(teacher.name[0].toUpperCase(), style: TextStyle(fontSize: 26, color: colors.onPrimaryContainer, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(teacher.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                        if (!teacher.isApproved)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                            child: const Text('PENDING', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        if (isAdmin)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 18),
                            onSelected: (val) {
                              if (val == 'edit') _showTeacherForm(existingTeacher: teacher);
                              if (val == 'delete') TeacherService.deleteTeacher(teacher.id);
                              if (val == 'approve') TeacherService.approveTeacher(teacher.id);
                              if (val == 'visibility') TeacherService.toggleTeacherVisibility(teacher.id, !teacher.isVisible);
                            },
                            itemBuilder: (_) => [
                              if (!teacher.isApproved && (profile.designation == 'President' || profile.designation == 'Vice President'))
                                const PopupMenuItem(value: 'approve', child: Text('Approve', style: TextStyle(color: Colors.green))),
                              PopupMenuItem(value: 'visibility', child: Text(teacher.isVisible ? 'Hide' : 'Show')),
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                      ],
                    ),
                    Text(teacher.designation, style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    if (teacher.areasOfExpertise.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: teacher.areasOfExpertise.take(3).map((area) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(6)),
                          child: Text(area, style: TextStyle(color: colors.onPrimaryContainer, fontSize: 10)),
                        )).toList(),
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
