import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../backend/services/result_service.dart';
import '../../../../backend/services/result_scraper_service.dart';
import '../../../profile/models/profile_state.dart';
import 'result_event.dart';
import 'result_state.dart';

class ResultBloc extends Bloc<ResultEvent, ResultState> {
  ResultBloc() : super(const ResultState()) {
    on<LoadResultsRequested>(_onLoadResultsRequested);
    on<SyncResultsRequested>(_onSyncResultsRequested);
    on<FetchSpecificResultsRequested>(_onFetchSpecificResultsRequested);
    on<LoadBatchResultsRequested>(_onLoadBatchResultsRequested);
    on<DeleteResultRequested>(_onDeleteResultRequested);
  }

  Future<void> _onLoadResultsRequested(
    LoadResultsRequested event,
    Emitter<ResultState> emit,
  ) async {
    emit(state.copyWith(isOwnLoading: true, clearError: true));
    try {
      final results = await ResultService.loadResultsFromDB();
      emit(state.copyWith(
        isOwnLoading: false,
        ownResults: results,
      ));
    } catch (e) {
      emit(state.copyWith(
        isOwnLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSyncResultsRequested(
    SyncResultsRequested event,
    Emitter<ResultState> emit,
  ) async {
    emit(state.copyWith(isSyncing: true, clearError: true));
    try {
      final results = await ResultService.syncResults();
      emit(state.copyWith(
        isSyncing: false,
        ownResults: results,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSyncing: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onFetchSpecificResultsRequested(
    FetchSpecificResultsRequested event,
    Emitter<ResultState> emit,
  ) async {
    emit(state.copyWith(isSyncing: true, clearError: true));
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
      emit(state.copyWith(
        isSyncing: false,
        ownResults: freshResults,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSyncing: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadBatchResultsRequested(
    LoadBatchResultsRequested event,
    Emitter<ResultState> emit,
  ) async {
    emit(state.copyWith(isBatchLoading: true, clearError: true));
    try {
      final batchResults = await ResultService.loadBatchResults(event.session);
      emit(state.copyWith(
        isBatchLoading: false,
        batchResults: batchResults,
        selectedSession: event.session,
      ));
    } catch (e) {
      emit(state.copyWith(
        isBatchLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteResultRequested(
    DeleteResultRequested event,
    Emitter<ResultState> emit,
  ) async {
    emit(state.copyWith(isOwnLoading: true, clearError: true));
    try {
      await ResultService.deleteResult(event.resultId);
      final freshResults = await ResultService.loadResultsFromDB();
      emit(state.copyWith(
        isOwnLoading: false,
        ownResults: freshResults,
      ));
    } catch (e) {
      emit(state.copyWith(
        isOwnLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }
}
