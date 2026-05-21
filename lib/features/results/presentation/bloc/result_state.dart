import 'package:equatable/equatable.dart';
import '../../models/result_state.dart';

abstract class ResultState extends Equatable {
  const ResultState();

  @override
  List<Object?> get props => [];
}

class ResultInitial extends ResultState {}

class ResultLoading extends ResultState {}

class ResultSyncInProgress extends ResultState {
  final List<ExamResult> results;

  const ResultSyncInProgress({required this.results});

  @override
  List<Object?> get props => [results];
}

class ResultsLoaded extends ResultState {
  final List<ExamResult> results;

  const ResultsLoaded({required this.results});

  @override
  List<Object?> get props => [results];
}

class ResultError extends ResultState {
  final String message;

  const ResultError({required this.message});

  @override
  List<Object?> get props => [message];
}
