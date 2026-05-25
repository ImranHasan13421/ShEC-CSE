import 'package:equatable/equatable.dart';

abstract class ResultEvent extends Equatable {
  const ResultEvent();

  @override
  List<Object?> get props => [];
}

class LoadResultsRequested extends ResultEvent {}

class SyncResultsRequested extends ResultEvent {}

class FetchSpecificResultsRequested extends ResultEvent {
  final String session;
  final String sessId;
  final List<Map<String, String>> exams; // List of selected exams containing 'exam_id' and 'exam_name'

  const FetchSpecificResultsRequested({
    required this.session,
    required this.sessId,
    required this.exams,
  });

  @override
  List<Object?> get props => [session, sessId, exams];
}

class LoadBatchResultsRequested extends ResultEvent {
  final String session;

  const LoadBatchResultsRequested({required this.session});

  @override
  List<Object?> get props => [session];
}
