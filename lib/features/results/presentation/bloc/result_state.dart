import 'package:equatable/equatable.dart';
import '../../models/result_state.dart';
import '../../models/batch_member_result.dart';

class ResultState extends Equatable {
  final List<ExamResult> ownResults;
  final List<BatchMemberResult> batchResults;
  final bool isOwnLoading;
  final bool isBatchLoading;
  final bool isSyncing;
  final String selectedSession;
  final String? errorMessage;

  const ResultState({
    this.ownResults = const [],
    this.batchResults = const [],
    this.isOwnLoading = false,
    this.isBatchLoading = false,
    this.isSyncing = false,
    this.selectedSession = '',
    this.errorMessage,
  });

  ResultState copyWith({
    List<ExamResult>? ownResults,
    List<BatchMemberResult>? batchResults,
    bool? isOwnLoading,
    bool? isBatchLoading,
    bool? isSyncing,
    String? selectedSession,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ResultState(
      ownResults: ownResults ?? this.ownResults,
      batchResults: batchResults ?? this.batchResults,
      isOwnLoading: isOwnLoading ?? this.isOwnLoading,
      isBatchLoading: isBatchLoading ?? this.isBatchLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      selectedSession: selectedSession ?? this.selectedSession,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        ownResults,
        batchResults,
        isOwnLoading,
        isBatchLoading,
        isSyncing,
        selectedSession,
        errorMessage,
      ];
}
