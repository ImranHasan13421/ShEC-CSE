import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../profile/models/profile_state.dart';
import '../../models/teacher_state.dart';
import '../bloc/teacher_bloc.dart';
import '../bloc/teacher_event.dart';
import '../bloc/teacher_state.dart';
import '../widgets/add_edit_teacher_sheet.dart';
import '../widgets/teacher_card.dart';
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/ambient_background.dart';

class TeacherContactsScreen extends StatefulWidget {
  const TeacherContactsScreen({super.key});

  @override
  State<TeacherContactsScreen> createState() => _TeacherContactsScreenState();
}

class _TeacherContactsScreenState extends State<TeacherContactsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TeacherBloc>().add(const FetchTeachersRequested());
  }

  void _showTeacherForm({TeacherContact? existingTeacher}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return AddEditTeacherSheet(existingTeacher: existingTeacher);
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return AmbientTimeBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Teacher Contacts'),
          elevation: 0,
        ),
      body: BlocListener<TeacherBloc, TeacherState>(
        listener: (context, state) {
          if (state is TeacherError) {
            _showToast(context, state.message, isError: true);
          }
        },
        child: BlocBuilder<TeacherBloc, TeacherState>(
          builder: (context, state) {
            if (state is TeacherLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            List<TeacherContact> teachers = [];
            if (state is TeacherLoaded) {
              teachers = state.teachers;
            }

            final profile = currentProfile.value;
            final isAdmin = profile.role != UserRole.student;
            final visible = isAdmin
                ? teachers
                : teachers.where((t) => t.isApproved && t.isVisible).toList();

            return RefreshIndicator(
              onRefresh: () async {
                context.read<TeacherBloc>().add(const FetchTeachersRequested());
              },
              child: visible.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        alignment: Alignment.center,
                        child: const Text('No teacher contacts available.'),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final teacher = visible[index];
                        return TeacherCard(
                          teacher: teacher,
                          profile: profile,
                          onEdit: () => _showTeacherForm(existingTeacher: teacher),
                        );
                      },
                    ),
            );
          },
        ),
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
    ),
  );
}
}
