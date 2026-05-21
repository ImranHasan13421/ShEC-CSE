import 'package:equatable/equatable.dart';

abstract class ResultEvent extends Equatable {
  const ResultEvent();

  @override
  List<Object?> get props => [];
}

class LoadResultsRequested extends ResultEvent {}

class SyncResultsRequested extends ResultEvent {}
