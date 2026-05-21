import 'package:equatable/equatable.dart';
import '../../models/notice_state.dart';

abstract class NoticeState extends Equatable {
  const NoticeState();

  @override
  List<Object?> get props => [];
}

class NoticeInitial extends NoticeState {}

class NoticeLoading extends NoticeState {}

class NoticesLoaded extends NoticeState {
  final List<NoticeItem> clubNotices;
  final List<NoticeItem> deptNotices;

  const NoticesLoaded({required this.clubNotices, required this.deptNotices});

  @override
  List<Object?> get props => [clubNotices, deptNotices];
}

class NoticeOperationSuccess extends NoticeState {}

class NoticeError extends NoticeState {
  final String message;

  const NoticeError({required this.message});

  @override
  List<Object?> get props => [message];
}
