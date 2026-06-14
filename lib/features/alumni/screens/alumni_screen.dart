import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ShEC_CSE/core/services/image_processing_service.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../backend/services/alumni_service.dart';
import '../../../backend/services/auth_service.dart';
import '../../profile/models/profile_state.dart';
import '../models/alumni_state.dart';
import '../presentation/bloc/alumni_bloc.dart';
import '../presentation/bloc/alumni_event.dart';
import '../presentation/bloc/alumni_state.dart';
import 'alumni_detail_screen.dart';
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/ambient_background.dart';

class AlumniScreen extends StatefulWidget {
  const AlumniScreen({super.key});

  @override
  State<AlumniScreen> createState() => _AlumniScreenState();
}

class _AlumniScreenState extends State<AlumniScreen> {
  List<String> _sessions = [];
  final List<String> _batches = List.generate(20, (index) => (index + 1).toString());
  final List<String> _years = List.generate(30, (index) => (DateTime.now().year - index).toString());

  @override
  void initState() {
    super.initState();
    context.read<AlumniBloc>().add(const FetchAlumniRequested(forceRefresh: true));
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessionsData = await AuthService.fetchSessions();
    setState(() {
      _sessions = sessionsData.map((e) => e['session'] as String).toList();
    });
  }

  bool get _isSuperUser {
    final p = currentProfile.value;
    return p.designation == 'President' || p.designation == 'Vice President';
  }

  void _showAlumniForm({AlumniItem? existing}) {
    final alumniBloc = context.read<AlumniBloc>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final positionCtrl = TextEditingController(text: existing?.currentPosition ?? '');
    final companyCtrl = TextEditingController(text: existing?.company ?? '');
    final expertiseCtrl = TextEditingController();

    String? selectedBatch = existing?.batch.isNotEmpty == true ? existing?.batch : null;
    String? selectedSession = existing?.session.isNotEmpty == true ? existing?.session : null;
    String? selectedYear = existing?.passingYear.isNotEmpty == true ? existing?.passingYear : null;

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
            final picked = await picker.pickImage(source: ImageSource.gallery);
            if (picked != null) {
              if (!context.mounted) return;
              
              // 1. Crop Image (Square for alumni)
              final cropped = await ImageProcessingService.cropImage(
                context, 
                File(picked.path),
                aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
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
                            : (currentImageUrl != null && currentImageUrl.isNotEmpty
                                ? NetworkImage(currentImageUrl) as ImageProvider
                                : null),
                        child: (selectedImage == null && (currentImageUrl == null || currentImageUrl.isEmpty))
                            ? const Icon(Icons.add_a_photo, size: 30, color: Colors.grey)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _f(nameCtrl, 'Full Name *'),
                  const SizedBox(height: 12),
                  
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedBatch,
                        decoration: const InputDecoration(labelText: 'Batch', border: OutlineInputBorder(), isDense: true),
                        items: _batches.map((b) => DropdownMenuItem(value: b, child: Text('Batch $b'))).toList(),
                        onChanged: (v) => setModalState(() => selectedBatch = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedSession,
                        decoration: const InputDecoration(labelText: 'Session', border: OutlineInputBorder(), isDense: true),
                        items: _sessions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setModalState(() => selectedSession = v),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  
                  DropdownButtonFormField<String>(
                    value: selectedYear,
                    decoration: const InputDecoration(labelText: 'Passing Year', border: OutlineInputBorder(), isDense: true),
                    items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                    onChanged: (v) => setModalState(() => selectedYear = v),
                  ),
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
                      onPressed: () async {
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
                          email: emailCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          imagePath: finalImageUrl ?? '',
                          batch: selectedBatch ?? '',
                          session: selectedSession ?? '',
                          passingYear: selectedYear ?? '',
                          currentPosition: positionCtrl.text.trim(),
                          company: companyCtrl.text.trim(),
                          areasOfExpertise: expertiseList,
                          isVisible: isVisible,
                          createdByName: existing?.createdByName ?? currentProfile.value.name,
                        );
                        if (mounted) {
                          Navigator.pop(modalContext);
                          if (existing == null) {
                            alumniBloc.add(AddAlumniRequested(item: item));
                          } else {
                            alumniBloc.add(UpdateAlumniRequested(item: item));
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

    return AmbientTimeBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Alumni'),
        ),
      body: BlocBuilder<AlumniBloc, AlumniState>(
        builder: (context, state) {
          final isAdmin = currentProfile.value.role != UserRole.student;
          List<AlumniItem> visible = [];
          if (state is AlumniLoading || state is AlumniInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AlumniError) {
            return Center(child: Text(state.message));
          } else if (state is AlumniLoaded) {
            final alumni = state.items;
            visible = isAdmin ? alumni : alumni.where((a) => a.isApproved && a.isVisible).toList();
          }

          if (visible.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<AlumniBloc>().add(const FetchAlumniRequested(forceRefresh: true));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school_outlined, size: 64, color: colors.onSurface.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text('No alumni listed yet.', style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AlumniBloc>().add(const FetchAlumniRequested(forceRefresh: true));
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: visible.length,
              itemBuilder: (context, index) => _buildCard(visible[index]),
            ),
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AlumniDetailScreen(alumni: alumni)),
          );
        },
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
                            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                            child: const Text('PENDING', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        if (isAdmin) ...[
                          // Removed PopupMenuButton from the header row
                        ],
                      ],
                    ),
                    if (alumni.currentPosition.isNotEmpty || alumni.company.isNotEmpty)
                      Text(
                        '${alumni.currentPosition}${alumni.company.isNotEmpty ? ' at ${alumni.company}' : ''}',
                        style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    if (alumni.session.isNotEmpty || alumni.passingYear.isNotEmpty)
                      Text(
                        '${alumni.session.isNotEmpty ? 'Session: ${alumni.session}' : ''}'
                        '${alumni.passingYear.isNotEmpty ? ' • Passed: ${alumni.passingYear}' : ''}',
                        style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5), fontSize: 12),
                      ),
                    if (isAdmin) ...[
                      const Divider(height: 16, thickness: 0.5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Admin Actions',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface.withValues(alpha: 0.4),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          _buildCardAdminMenu(alumni),
                        ],
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

  Widget _buildCardAdminMenu(AlumniItem alumni) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!alumni.isApproved && _isSuperUser) ...[
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Approve Alumni',
            onPressed: () {
              context.read<AlumniBloc>().add(ApproveAlumniRequested(itemId: alumni.id));
              _showToast('Alumni approved successfully!', isError: false);
            },
          ),
          const SizedBox(width: 12),
        ],
        IconButton(
          icon: Icon(alumni.isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.orange, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: alumni.isVisible ? 'Hide Alumni' : 'Show Alumni',
          onPressed: () {
            context.read<AlumniBloc>().add(ToggleAlumniVisibilityRequested(itemId: alumni.id, isVisible: !alumni.isVisible));
            _showToast(alumni.isVisible ? 'Alumni profile hidden!' : 'Alumni profile is now visible!', isError: false);
          },
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Edit Alumni',
          onPressed: () => _showAlumniForm(existing: alumni),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Delete Alumni',
          onPressed: () {
            context.read<AlumniBloc>().add(DeleteAlumniRequested(item: alumni));
            _showToast('Alumni deleted successfully!', isError: false);
          },
        ),
      ],
    );
  }

  void _showToast(String message, {required bool isError}) {
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
