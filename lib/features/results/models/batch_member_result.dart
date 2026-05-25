import '../../../features/profile/models/profile_state.dart';
import 'result_state.dart';

class BatchMemberResult {
  final ProfileData profile;
  final ExamResult result;

  BatchMemberResult({
    required this.profile,
    required this.result,
  });
}
