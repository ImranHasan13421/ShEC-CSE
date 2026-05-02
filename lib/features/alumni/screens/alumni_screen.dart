import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../backend/services/alumni_service.dart';
import '../../profile/models/profile_state.dart';
import '../models/alumni_state.dart';

class AlumniScreen extends StatefulWidget {
  const AlumniScreen({super.key});

  @override
  State<AlumniScreen> createState() => _AlumniScreenState();
}

class _AlumniScreenState extends State<AlumniScreen> {
  @override
  void initState() {
    super.initState();
    AlumniService.fetchAlumni();
  }

  bool get _isSuperUser {
    final p = currentProfile.value;
    return p.designation == 'President' || p.designation == 'Vice President';
  }

  void _showAlumniForm({AlumniItem? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final roleCtrl = TextEditingController(text: existing?.role ?? '');
    final designCtrl = TextEditingController(text: existing?.designation ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final batchCtrl = TextEditingController(text: existing?.batch ?? '');
    final sessionCtrl = TextEditingController(text: existing?.session ?? '');
    final passingYearCtrl = TextEditingController(text: existing?.passingYear ?? '');
    final positionCtrl = TextEditingController(text: existing?.currentPosition ?? '');
    final companyCtrl = TextEditingController(text: existing?.company ?? '');
    final expertiseCtrl = TextEditingController();

    List<String> expertiseList = List.from(existing?.areasOfExpertise ?? []);
    bool isVisible = existing?.isVisible ?? true;
    File? selectedImage;
    String? currentImageUrl = existing?.imagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalContext) {
        return StatefulBuilder(builder: (context, setModalState) {
          bool isUploading = false;

          Future<void> pickImage() async {
            final picker = ImagePicker();
            final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
            if (picked != null) setModalState(() => selectedImage = File(picked.path));
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
                  Text(existing == null ? 'Add Alumni' : 'Edit Alumni',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: pickImage,
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
                  _f(nameCtrl, 'Full Name *'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _f(designCtrl, 'Designation')),
                    const SizedBox(width: 12),
                    Expanded(child: _f(roleCtrl, 'Role')),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _f(batchCtrl, 'Batch')),
                    const SizedBox(width: 12),
                    Expanded(child: _f(sessionCtrl, 'Session')),
                  ]),
                  const SizedBox(height: 12),
                  _f(passingYearCtrl, 'Passing Year'),
                  const SizedBox(height: 12),
                  _f(positionCtrl, 'Current Position'),
                  const SizedBox(height: 12),
                  _f(companyCtrl, 'Company / Organization'),
                  const SizedBox(height: 12),
                  _f(emailCtrl, 'Email', keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _f(phoneCtrl, 'Phone', keyboardType: TextInputType.phone),
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
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: expertiseCtrl,
                        decoration: const InputDecoration(hintText: 'Add area', border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: () {
                        if (expertiseCtrl.text.isNotEmpty) {
                          setModalState(() {
                            expertiseList.add(expertiseCtrl.text.trim());
                            expertiseCtrl.clear();
                          });
                        }
                      },
                    ),
                  ]),
                  SwitchListTile(
                    title: const Text('Visible to Members'),
                    value: isVisible,
                    onChanged: (val) => setModalState(() => isVisible = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isUploading ? null : () async {
                        if (nameCtrl.text.isEmpty) return;
                        setModalState(() => isUploading = true);
                        String? finalImageUrl = currentImageUrl;
                        if (selectedImage != null) {
                          finalImageUrl = await AlumniService.uploadImage(selectedImage!);
                        }
                        final item = AlumniItem(
                          id: existing?.id ?? '',
                          userId: existing?.userId,
                          name: nameCtrl.text.trim(),
                          role: roleCtrl.text.trim(),
                          designation: designCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          imagePath: finalImageUrl ?? '',
                          batch: batchCtrl.text.trim(),
                          session: sessionCtrl.text.trim(),
                          passingYear: passingYearCtrl.text.trim(),
                          currentPosition: positionCtrl.text.trim(),
                          company: companyCtrl.text.trim(),
                          areasOfExpertise: expertiseList,
                          isVisible: isVisible,
                          createdByName: existing?.createdByName ?? currentProfile.value.name,
                        );
                        if (mounted) {
                          Navigator.pop(modalContext);
                          if (existing == null) {
                            await AlumniService.addAlumni(item);
                          } else {
                            await AlumniService.updateAlumni(item);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: isUploading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(existing == null ? 'Save Alumni' : 'Update'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _f(TextEditingController ctrl, String label, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Alumni')),
      body: ValueListenableBuilder<List<AlumniItem>>(
        valueListenable: alumniState,
        builder: (context, alumni, _) {
          final isAdmin = currentProfile.value.role != UserRole.student;
          final visible = isAdmin ? alumni : alumni.where((a) => a.isApproved && a.isVisible).toList();

          if (visible.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school_outlined, size: 64, color: colors.onSurface.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('No alumni listed yet.', style: TextStyle(color: colors.onSurface.withOpacity(0.5))),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: visible.length,
            itemBuilder: (context, index) => _buildCard(visible[index]),
          );
        },
      ),
      floatingActionButton: ValueListenableBuilder<ProfileData>(
        valueListenable: currentProfile,
        builder: (context, profile, _) {
          if (profile.role != UserRole.student) {
            return FloatingActionButton(
              onPressed: () => _showAlumniForm(),
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCard(AlumniItem alumni) {
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
        onTap: () => _showAlumniDetails(alumni),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: colors.secondaryContainer,
                backgroundImage: alumni.imagePath.isNotEmpty ? NetworkImage(alumni.imagePath) : null,
                child: alumni.imagePath.isEmpty
                    ? Text(alumni.name[0].toUpperCase(),
                        style: TextStyle(fontSize: 26, color: colors.onSecondaryContainer, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(alumni.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                        if (!alumni.isApproved)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: const Text('PENDING', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        if (isAdmin)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 18),
                            onSelected: (val) {
                              if (val == 'edit') _showAlumniForm(existing: alumni);
                              if (val == 'delete') AlumniService.deleteAlumni(alumni.id);
                              if (val == 'approve') AlumniService.approveAlumni(alumni.id);
                              if (val == 'visibility') AlumniService.toggleAlumniVisibility(alumni.id, !alumni.isVisible);
                            },
                            itemBuilder: (_) => [
                              if (!alumni.isApproved && _isSuperUser)
                                const PopupMenuItem(value: 'approve', child: Text('Approve', style: TextStyle(color: Colors.green))),
                              PopupMenuItem(value: 'visibility', child: Text(alumni.isVisible ? 'Hide' : 'Show')),
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                      ],
                    ),
                    if (alumni.currentPosition.isNotEmpty || alumni.company.isNotEmpty)
                      Text(
                        '${alumni.currentPosition}${alumni.company.isNotEmpty ? ' @ ${alumni.company}' : ''}',
                        style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    if (alumni.session.isNotEmpty || alumni.passingYear.isNotEmpty)
                      Text(
                        '${alumni.session.isNotEmpty ? 'Session: ${alumni.session}' : ''}'
                        '${alumni.passingYear.isNotEmpty ? ' • Passed: ${alumni.passingYear}' : ''}',
                        style: TextStyle(color: colors.onSurface.withOpacity(0.5), fontSize: 12),
                      ),
                    if (alumni.areasOfExpertise.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: alumni.areasOfExpertise.take(2).map((a) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: colors.secondaryContainer, borderRadius: BorderRadius.circular(6)),
                          child: Text(a, style: TextStyle(color: colors.onSecondaryContainer, fontSize: 10)),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlumniDetails(AlumniItem alumni) {
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: alumni.imagePath.isNotEmpty ? NetworkImage(alumni.imagePath) : null,
                  child: alumni.imagePath.isEmpty ? Text(alumni.name[0].toUpperCase(), style: const TextStyle(fontSize: 48)) : null,
                ),
                const SizedBox(height: 16),
                Text(alumni.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                if (alumni.currentPosition.isNotEmpty)
                  Text('${alumni.currentPosition} @ ${alumni.company}', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                const Divider(height: 32),
                if (alumni.email.isNotEmpty || alumni.phone.isNotEmpty)
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (alumni.phone.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () => launchUrl(Uri.parse('tel:${alumni.phone}')),
                        icon: const Icon(Icons.phone, size: 16),
                        label: const Text('Call'),
                      ),
                    if (alumni.email.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => launchUrl(Uri.parse('mailto:${alumni.email}')),
                        icon: const Icon(Icons.email, size: 16),
                        label: const Text('Email'),
                      ),
                    ],
                  ]),
                if (alumni.areasOfExpertise.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Areas of Expertise', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: alumni.areasOfExpertise.map((a) => Chip(
                      label: Text(a),
                      backgroundColor: colors.primaryContainer,
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
