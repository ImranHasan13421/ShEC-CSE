import 'package:equatable/equatable.dart';
import '../../models/notice_state.dart';

abstract class NoticeEvent extends Equatable {
  const NoticeEvent();

  @override
  List<Object?> get props => [];
}

class FetchNoticesRequested extends NoticeEvent {
  final bool forceRefresh;

  const FetchNoticesRequested({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class AddNoticeRequested extends NoticeEvent {
  final NoticeItem notice;
  final String category;

  const AddNoticeRequested({required this.notice, required this.category});

  @override
  List<Object?> get props => [notice, category];
}

class UpdateNoticeRequested extends NoticeEvent {
  final NoticeItem notice;
  final String category;

  const UpdateNoticeRequested({required this.notice, required this.category});

  @override
  List<Object?> get props => [notice, category];
}

class DeleteNoticeRequested extends NoticeEvent {
  final NoticeItem notice;
  final String category;

  const DeleteNoticeRequested({required this.notice, required this.category});

  @override
  List<Object?> get props => [notice, category];
}

class ApproveNoticeRequested extends NoticeEvent {
  final String noticeId;

  const ApproveNoticeRequested({required this.noticeId});

  @override
  List<Object?> get props => [noticeId];
}

class ToggleNoticeVisibilityRequested extends NoticeEvent {
  final String noticeId;
  final bool isVisible;

  const ToggleNoticeVisibilityRequested({required this.noticeId, required this.isVisible});

  @override
  List<Object?> get props => [noticeId, isVisible];
}
