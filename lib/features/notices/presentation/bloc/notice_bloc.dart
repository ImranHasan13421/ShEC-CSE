import 'package:flutter_bloc/flutter_bloc.dart';
import 'notice_event.dart';
import 'notice_state.dart';
import '../../../../backend/services/notice_service.dart';
import '../../models/notice_state.dart';

class NoticeBloc extends Bloc<NoticeEvent, NoticeState> {
  NoticeBloc() : super(NoticeInitial()) {
    on<FetchNoticesRequested>(_onFetchNoticesRequested);
    on<AddNoticeRequested>(_onAddNoticeRequested);
    on<UpdateNoticeRequested>(_onUpdateNoticeRequested);
    on<DeleteNoticeRequested>(_onDeleteNoticeRequested);
    on<ApproveNoticeRequested>(_onApproveNoticeRequested);
    on<ToggleNoticeVisibilityRequested>(_onToggleNoticeVisibilityRequested);
  }

  Future<void> _onFetchNoticesRequested(
    FetchNoticesRequested event,
    Emitter<NoticeState> emit,
  ) async {
    emit(NoticeLoading());
    try {
      await NoticeService.fetchNotices(forceRefresh: event.forceRefresh);
      emit(NoticesLoaded(
        clubNotices: List.from(clubNoticesState.value),
        deptNotices: List.from(deptNoticesState.value),
      ));
    } catch (e) {
      emit(NoticeError(message: e.toString()));
    }
  }

  Future<void> _onAddNoticeRequested(
    AddNoticeRequested event,
    Emitter<NoticeState> emit,
  ) async {
    emit(NoticeLoading());
    try {
      await NoticeService.addNoticeToDB(event.notice, event.category);
      emit(NoticeOperationSuccess());
      // Re-fetch notices after operation
      add(const FetchNoticesRequested(forceRefresh: true));
    } catch (e) {
      emit(NoticeError(message: e.toString()));
    }
  }

  Future<void> _onUpdateNoticeRequested(
    UpdateNoticeRequested event,
    Emitter<NoticeState> emit,
  ) async {
    emit(NoticeLoading());
    try {
      await NoticeService.updateNoticeInDB(event.notice, event.category);
      emit(NoticeOperationSuccess());
      add(const FetchNoticesRequested(forceRefresh: true));
    } catch (e) {
      emit(NoticeError(message: e.toString()));
    }
  }

  Future<void> _onDeleteNoticeRequested(
    DeleteNoticeRequested event,
    Emitter<NoticeState> emit,
  ) async {
    emit(NoticeLoading());
    try {
      await NoticeService.deleteNoticeFromDB(event.notice, event.category);
      emit(NoticeOperationSuccess());
      add(const FetchNoticesRequested(forceRefresh: true));
    } catch (e) {
      emit(NoticeError(message: e.toString()));
    }
  }

  Future<void> _onApproveNoticeRequested(
    ApproveNoticeRequested event,
    Emitter<NoticeState> emit,
  ) async {
    emit(NoticeLoading());
    try {
      await NoticeService.approveNotice(event.noticeId);
      emit(NoticeOperationSuccess());
      add(const FetchNoticesRequested(forceRefresh: true));
    } catch (e) {
      emit(NoticeError(message: e.toString()));
    }
  }

  Future<void> _onToggleNoticeVisibilityRequested(
    ToggleNoticeVisibilityRequested event,
    Emitter<NoticeState> emit,
  ) async {
    emit(NoticeLoading());
    try {
      await NoticeService.toggleNoticeVisibility(event.noticeId, event.isVisible);
      emit(NoticeOperationSuccess());
      add(const FetchNoticesRequested(forceRefresh: true));
    } catch (e) {
      emit(NoticeError(message: e.toString()));
    }
  }
}
