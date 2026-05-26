import 'package:equatable/equatable.dart';

abstract class AccountingEvent extends Equatable {
  const AccountingEvent();

  @override
  List<Object?> get props => [];
}

class FetchAccountingDataRequested extends AccountingEvent {}

class FetchDuesStatusRequested extends AccountingEvent {
  final String month; // Format: 'YYYY-MM'

  const FetchDuesStatusRequested(this.month);

  @override
  List<Object?> get props => [month];
}

class AddFeePaymentSubmitted extends AccountingEvent {
  final String? memberId;
  final double amount;
  final String month;
  final String paymentType;
  final String? eventName;
  final String? remarks;
  final String? externalSource;

  const AddFeePaymentSubmitted({
    this.memberId,
    required this.amount,
    required this.month,
    required this.paymentType,
    this.eventName,
    this.remarks,
    this.externalSource,
  });

  @override
  List<Object?> get props => [memberId, amount, month, paymentType, eventName, remarks, externalSource];
}

class AddExpenseSubmitted extends AccountingEvent {
  final double amount;
  final String category;
  final String description;
  final String? eventName;
  final String? remarks;
  final DateTime expenseDate;

  const AddExpenseSubmitted({
    required this.amount,
    required this.category,
    required this.description,
    required this.expenseDate,
    this.eventName,
    this.remarks,
  });

  @override
  List<Object?> get props => [amount, category, description, eventName, remarks, expenseDate];
}

class UpdateFeePaymentSubmitted extends AccountingEvent {
  final String paymentId;
  final double amount;
  final String month;
  final String paymentType;
  final String? eventName;
  final String? remarks;

  const UpdateFeePaymentSubmitted({
    required this.paymentId,
    required this.amount,
    required this.month,
    required this.paymentType,
    this.eventName,
    this.remarks,
  });

  @override
  List<Object?> get props => [paymentId, amount, month, paymentType, eventName, remarks];
}

class DeleteFeePaymentSubmitted extends AccountingEvent {
  final String paymentId;

  const DeleteFeePaymentSubmitted(this.paymentId);

  @override
  List<Object?> get props => [paymentId];
}

class UpdateExpenseSubmitted extends AccountingEvent {
  final String expenseId;
  final double amount;
  final String category;
  final String description;
  final String? eventName;
  final String? remarks;
  final DateTime expenseDate;

  const UpdateExpenseSubmitted({
    required this.expenseId,
    required this.amount,
    required this.category,
    required this.description,
    required this.expenseDate,
    this.eventName,
    this.remarks,
  });

  @override
  List<Object?> get props => [expenseId, amount, category, description, eventName, remarks, expenseDate];
}

class DeleteExpenseSubmitted extends AccountingEvent {
  final String expenseId;

  const DeleteExpenseSubmitted(this.expenseId);

  @override
  List<Object?> get props => [expenseId];
}
