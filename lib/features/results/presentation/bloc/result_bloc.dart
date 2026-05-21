import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../backend/services/result_service.dart';
import '../../models/result_state.dart';
import 'result_event.dart';
import 'result_state.dart';

class ResultBloc extends Bloc<ResultEvent, ResultState> {
  ResultBloc() : super(ResultInitial()) {
    on<LoadResultsRequested>(_onLoadResultsRequested);
    on<SyncResultsRequested>(_onSyncResultsRequested);
  }

  Future<void> _onLoadResultsRequested(
    LoadResultsRequested event,
    Emitter<ResultState> emit,
  ) async {
    emit(ResultLoading());
    try {
      final results = await ResultService.loadResultsFromDB();
      emit(ResultsLoaded(results: results));
    } catch (e) {
      emit(ResultError(message: e.toString()));
    }
  }

  Future<void> _onSyncResultsRequested(
    SyncResultsRequested event,
    Emitter<ResultState> emit,
  ) async {
    final currentResults = state is ResultsLoaded ? (state as ResultsLoaded).results : <ExamResult>[];
    emit(ResultSyncInProgress(results: currentResults));
    try {
      final results = await ResultService.syncResults();
      emit(ResultsLoaded(results: results));
    } catch (e) {
      emit(ResultError(message: e.toString()));
    }
  }
}
