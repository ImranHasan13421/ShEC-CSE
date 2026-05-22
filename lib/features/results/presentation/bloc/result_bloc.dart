import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../backend/services/result_service.dart';
import '../../../../backend/services/result_scraper_service.dart';
import '../../../profile/models/profile_state.dart';
import '../../models/result_state.dart';
import 'result_event.dart';
import 'result_state.dart';

class ResultBloc extends Bloc<ResultEvent, ResultState> {
  ResultBloc() : super(ResultInitial()) {
    on<LoadResultsRequested>(_onLoadResultsRequested);
    on<SyncResultsRequested>(_onSyncResultsRequested);
    on<FetchSpecificResultsRequested>(_onFetchSpecificResultsRequested);
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

  Future<void> _onFetchSpecificResultsRequested(
    FetchSpecificResultsRequested event,
    Emitter<ResultState> emit,
  ) async {
    final currentResults = state is ResultsLoaded ? (state as ResultsLoaded).results : <ExamResult>[];
    emit(ResultSyncInProgress(results: currentResults));
    try {
      final profile = currentProfile.value;
      if (profile.id.isEmpty || profile.duRegNo.isEmpty) {
        throw Exception('Profile ID or Registration Number is empty');
      }

      final List<Future<bool>> tasks = event.exams.map((exam) {
        final examId = exam['exam_id'] ?? '';
        final examName = exam['exam_name'] ?? '';
        return ResultScraperService.scrapeAndSaveSingleResult(
          userId: profile.id,
          regNo: profile.duRegNo,
          examId: examId,
          sessId: event.sessId,
          examName: examName,
        );
      }).toList();

      final List<bool> scraperResults = await Future.wait(tasks);
      final successCount = scraperResults.where((r) => r).length;

      if (successCount == 0) {
        throw Exception('No results found on the DUCMC portal for the selected exams.');
      }

      // Reload results from DB after scraping finishes
      final freshResults = await ResultService.loadResultsFromDB();
      emit(ResultsLoaded(results: freshResults));
    } catch (e) {
      emit(ResultError(message: e.toString()));
      emit(ResultsLoaded(results: currentResults));
    }
  }
}
