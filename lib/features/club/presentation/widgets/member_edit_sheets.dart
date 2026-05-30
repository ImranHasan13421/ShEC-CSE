import 'package:flutter/material.dart';
import '../../../profile/models/profile_state.dart';

class DesignationPickerSheet extends StatelessWidget {
  final ProfileData member;
  final Function(String) onSelect;

  const DesignationPickerSheet({
    super.key,
    required this.member,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> standardDesignations = [
      'President', 'Vice President', 'General Secretary', 'Joint Secretary', 
      'Treasurer', 'Press Secretary', 'Executive Member', 'Member'
    ];

    return ListView(
      shrinkWrap: true,
      children: standardDesignations.map((d) => ListTile(
        title: Text(d),
        onTap: () => onSelect(d),
      )).toList(),
    );
  }
}

class EditMemberSheet extends StatefulWidget {
  final ProfileData member;
  final Function(ProfileData) onSave;

  const EditMemberSheet({
    super.key,
    required this.member,
    required this.onSave,
  });

  @override
  State<EditMemberSheet> createState() => _EditMemberSheetState();
}

class _EditMemberSheetState extends State<EditMemberSheet> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController universityIdController;
  late TextEditingController classRollController;
  late TextEditingController duRegController;
  late TextEditingController phoneController;
  String? selectedSession;
  String? selectedBatch;

  final List<String> sessions = List.generate(10, (i) => '${2018 + i}-${2019 + i}');
  final List<String> batches = List.generate(10, (i) => '${i + 1}');

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController(text: widget.member.firstName);
    lastNameController = TextEditingController(text: widget.member.lastName);
    universityIdController = TextEditingController(text: widget.member.universityId);
    classRollController = TextEditingController(text: widget.member.classRoll);
    duRegController = TextEditingController(text: widget.member.duRegNo);
    phoneController = TextEditingController(text: widget.member.phone);
    selectedSession = widget.member.session;
    selectedBatch = widget.member.batch;

    // Ensure current values are in the lists to prevent crash
    if (selectedSession != null && !sessions.contains(selectedSession)) {
      sessions.add(selectedSession!);
      sessions.sort((a, b) => b.compareTo(a));
    }
    if (selectedBatch != null && !batches.contains(selectedBatch)) {
      batches.add(selectedBatch!);
      batches.sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    universityIdController.dispose();
    classRollController.dispose();
    duRegController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 12,
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Update Member Info', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(child: TextField(controller: firstNameController, decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: universityIdController, decoration: const InputDecoration(labelText: 'University ID', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: classRollController, decoration: const InputDecoration(labelText: 'Class Roll', border: OutlineInputBorder()))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: duRegController, decoration: const InputDecoration(labelText: 'DU Reg No', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedSession,
                    decoration: const InputDecoration(labelText: 'Session', border: OutlineInputBorder()),
                    items: sessions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => selectedSession = val),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedBatch,
                    decoration: const InputDecoration(labelText: 'Batch', border: OutlineInputBorder()),
                    items: batches.map((b) => DropdownMenuItem(value: b, child: Text('Batch $b'))).toList(),
                    onChanged: (val) => setState(() => selectedBatch = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  final updatedMember = widget.member.copyWith(
                    firstName: firstNameController.text.trim(),
                    lastName: lastNameController.text.trim(),
                    name: '${firstNameController.text.trim()} ${lastNameController.text.trim()}',
                    universityId: universityIdController.text.trim(),
                    classRoll: classRollController.text.trim(),
                    duRegNo: duRegController.text.trim(),
                    phone: phoneController.text.trim(),
                    session: selectedSession,
                    batch: selectedBatch,
                  );
                  widget.onSave(updatedMember);
                },
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
